/* ******************************************************************************
 * Copyright (c) 2016 Toshi Piazza. All rights reserved.
 * ******************************************************************************/

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * * Neither the name of VMware, Inc. nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL VMWARE, INC. OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

#include <stddef.h>   // for offsetof
#include <stdint.h>   // for uint*_t
#include <inttypes.h> // for PRIuPTR
#include "dr_api.h"
#include "drmgr.h"
#include "drutil.h"
#include "utils.h"
#include "base64.h"

#ifdef UNIX
# if defined(MACOS) || defined(ANDROID)
#  include <sys/syscall.h>
# else
#  include <syscall.h>
# endif
#endif

typedef struct _mem_ref_t {
    ushort size;
    ushort type;
    app_pc addr;
} mem_ref_t;

#define MAX_NUM_MEM_REFS 4096
#define MEM_BUF_SIZE (sizeof(mem_ref_t) * MAX_NUM_MEM_REFS)

/* thread private log file and counter */
typedef struct {
    byte      *seg_base;
    mem_ref_t *buf_base;
    file_t     log;
    app_pc     stk_base;
    app_pc     stk_ceil;
} per_thread_t;

static client_id_t client_id;

/* Allocated TLS slot offsets */
enum {
    MEMTRACE_TLS_OFFS_BUF_PTR,
    MEMTRACE_TLS_COUNT, /* total number of TLS slots allocated */
};
static reg_id_t tls_seg;
static uint     tls_offs;
static int      tls_idx;

/* The system call number of SYS_write/NtWriteFile */
static int      write_sysnum;
#define TLS_SLOT(tls_base, enum_val) (void **)((byte *)(tls_base)+tls_offs+(enum_val))
#define BUF_PTR(tls_base) *(mem_ref_t **)TLS_SLOT(tls_base, MEMTRACE_TLS_OFFS_BUF_PTR)

#define MINSERT instrlist_meta_preinsert

/********************************************************************************
 * STACK INSTRUMENTATION UTILITIES
 */

static uint64_t
dereference_pointer(app_pc pc, ushort size)
{
    switch (size) {
    case 1:  return *(uint8_t *)  pc;
    case 2:  return *(uint16_t *) pc;
    case 4:  return *(uint32_t *) pc;
    case 8:  return *(uint64_t *) pc;
    default: return 0;
    }
}

static void
get_stack_bounds(app_pc *base, app_pc *ceil, app_pc sptr)
{
    size_t sz;
    bool ok = dr_query_memory(sptr, ceil, &sz, NULL);
    DR_ASSERT(ok);
    /* stack starts at top of memory */
    *base -= sz;
}

static void
memtrace(app_pc pc, bool pre_call)
{
    /* get stack pointer */
    void *drcontext = dr_get_current_drcontext();
    dr_mcontext_t mcontext = {sizeof(mcontext), DR_MC_CONTROL/*only xsp*/,};
    dr_get_mcontext(drcontext, &mcontext);
    app_pc stk_ptr = (app_pc) mcontext.xsp;

    /* We preinsert on calls, so we have to manually decrement stk_ptr. */
    if (pre_call) stk_ptr -= sizeof(app_pc);

    per_thread_t *data = drmgr_get_tls_field(drcontext, tls_idx);
    mem_ref_t *buf_ptr = BUF_PTR(data->seg_base),
              *mem_ref = (mem_ref_t *) data->buf_base;

    /* get the stack base, or a good estimate */
    if (data->stk_base == 0) {
        get_stack_bounds(&data->stk_base, &data->stk_ceil, stk_ptr);
        dr_fprintf(data->log, "stk_base:%"PRIuPTR" stk_ceil:%"PRIuPTR"\n",
                data->stk_base, data->stk_ceil);
    }

    for (; mem_ref < buf_ptr; mem_ref++) {
        /* filter by whether write occurs on the stack or not */
        if (mem_ref->addr <= data->stk_base && mem_ref->addr >= stk_ptr) {
            /* on a call instruction, the written memory is just pc */
            app_pc wmem = pre_call ? pc
                : (app_pc) dereference_pointer(mem_ref->addr, mem_ref->size);
            dr_fprintf(data->log, "addr:%"PRIuPTR
                                  " size:%d"
                                  " sptr:%"PRIuPTR
                                  " type:%s"
                                  " wmem:%"PRIuPTR"\n",
                        mem_ref->addr, mem_ref->size, stk_ptr,
                        decode_opcode_name(mem_ref->type), wmem);
        }
    }
    BUF_PTR(data->seg_base) = data->buf_base;
}

/* clean call to flush the buffer */
static void post_mov(void)      { memtrace(0, false); }
static void pre_call(app_pc pc) { memtrace(pc, true); }

static void
insert_load_buf_ptr(void *drcontext, instrlist_t *ilist, instr_t *where,
                    reg_id_t reg_ptr)
{
    dr_insert_read_raw_tls(drcontext, ilist, where, tls_seg,
                           tls_offs + MEMTRACE_TLS_OFFS_BUF_PTR, reg_ptr);
}

static void
insert_update_buf_ptr(void *drcontext, instrlist_t *ilist, instr_t *where,
                      reg_id_t reg_ptr, int adjust)
{
    MINSERT(ilist, where,
            XINST_CREATE_add(drcontext,
                             opnd_create_reg(reg_ptr),
                             OPND_CREATE_INT16(adjust)));
    dr_insert_write_raw_tls(drcontext, ilist, where, tls_seg,
                            tls_offs + MEMTRACE_TLS_OFFS_BUF_PTR, reg_ptr);
}

static void
insert_save_size(void *drcontext, instrlist_t *ilist, instr_t *where,
                 reg_id_t base, reg_id_t scratch, ushort size)
{
    scratch = reg_resize_to_opsz(scratch, OPSZ_2);
    MINSERT(ilist, where,
            XINST_CREATE_load_int(drcontext,
                                  opnd_create_reg(scratch),
                                  OPND_CREATE_INT16(size)));
    MINSERT(ilist, where,
            XINST_CREATE_store_2bytes(drcontext,
                                      OPND_CREATE_MEM16(base,
                                                        offsetof(mem_ref_t, size)),
                                      opnd_create_reg(scratch)));
}

static void
insert_save_type(void *drcontext, instrlist_t *ilist, instr_t *where,
                 reg_id_t base, reg_id_t scratch, ushort type)
{
    scratch = reg_resize_to_opsz(scratch, OPSZ_2);
    MINSERT(ilist, where,
            XINST_CREATE_load_int(drcontext,
                                  opnd_create_reg(scratch),
                                  OPND_CREATE_INT16(type)));
    MINSERT(ilist, where,
            XINST_CREATE_store_2bytes(drcontext,
                                      OPND_CREATE_MEM16(base,
                                                        offsetof(mem_ref_t, type)),
                                      opnd_create_reg(scratch)));
}

static void
insert_save_addr(void *drcontext, instrlist_t *ilist, instr_t *where,
                 opnd_t ref, reg_id_t reg_ptr, reg_id_t reg_addr)
{
    bool ok;
    /* we use reg_ptr as scratch to get addr */
    ok = drutil_insert_get_mem_addr(drcontext, ilist, where, ref, reg_addr, reg_ptr);
    DR_ASSERT(ok);

    /* write to offset */
    insert_load_buf_ptr(drcontext, ilist, where, reg_ptr);
    MINSERT(ilist, where,
            XINST_CREATE_store(drcontext,
                               OPND_CREATE_MEMPTR(reg_ptr,
                                                  offsetof(mem_ref_t, addr)),
                               opnd_create_reg(reg_addr)));
}

static bool
filter_abs_writes(opnd_t ref)
{
    /* On windows, SS and DS refer to the same location.
     * This check might not work on Windows. */
#ifndef WINDOWS
    if (opnd_is_abs_addr(ref)) {
        /* check the selector */
        reg_t seg = opnd_get_segment(ref);
        /* TODO: in windows, DS and SS refer to the same
         * segment. Does this still work? */
        if (seg == DR_SEG_SS)
            return true;
        return false;
    }
#if 0
    /* TODO: does this work? */
    else if (opnd_is_base_disp(ref)) {
        reg_id_t base = opnd_get_base(ref);
        if (base == DR_REG_XSP || base == DR_REG_XBP)
            return true;
        return false;
    }
#endif
#endif
    return true;
}

/* insert inline code to add a memory reference info entry into the buffer */
static bool
instrument_mem(void *drcontext, instrlist_t *ilist, instr_t *where, opnd_t ref)
{
    reg_id_t reg_ptr = IF_X86_ELSE(DR_REG_XCX, DR_REG_R1);
    reg_id_t reg_tmp = IF_X86_ELSE(DR_REG_XBX, DR_REG_R2);
    ushort slot_ptr  = SPILL_SLOT_2;
    ushort slot_tmp  = SPILL_SLOT_3;
    ushort size;
    ushort type;

    /* simple filter optimization */
    if (!filter_abs_writes(ref)) {
        dr_fprintf(STDERR, "~~DrStackVis~~ WARNING: filtering on operand of ");
        instr_disassemble(drcontext, where, STDERR);
        dr_fprintf(STDERR, "\n");
        return false;
    }

    size = drutil_opnd_mem_size_in_bytes(ref, where);
    type = instr_get_opcode(where);

    /* we need two scratch registers */
    dr_save_reg(drcontext, ilist, where, reg_ptr, slot_ptr);
    dr_save_reg(drcontext, ilist, where, reg_tmp, slot_tmp);

    /* save_addr should be called first as reg_ptr or reg_tmp maybe used in ref */
    insert_save_addr(drcontext, ilist, where, ref, reg_ptr, reg_tmp);
    insert_save_size(drcontext, ilist, where, reg_ptr, reg_tmp, size);
    insert_save_type(drcontext, ilist, where, reg_ptr, reg_tmp, type);
    insert_update_buf_ptr(drcontext, ilist, where, reg_ptr, sizeof(mem_ref_t));

    /* restore scratch registers */
    dr_restore_reg(drcontext, ilist, where, reg_ptr, slot_ptr);
    dr_restore_reg(drcontext, ilist, where, reg_tmp, slot_tmp);
    return true;
}

/* For each memory reference app instr, we insert inline code to fill the buffer
 * with an instruction entry and memory reference entries.
 */
static dr_emit_flags_t
event_app_instruction(void *drcontext, void *tag, instrlist_t *bb,
                      instr_t *instr, bool for_trace,
                      bool translating, void *user_data)
{
    int i;
    bool did_instrument = false;

    if (!instr_is_app(instr))
        return DR_EMIT_DEFAULT;
    if (!instr_writes_memory(instr))
        return DR_EMIT_DEFAULT;

    /* insert code to add an entry for each memory write opnd */
    for (i = 0; i < instr_num_dsts(instr); i++) {
        if (opnd_is_memory_reference(instr_get_dst(instr, i)))
            did_instrument |=
                instrument_mem(drcontext, bb, instr, instr_get_dst(instr, i));
    }

    /* our filter deemed it unecessary to insert instrumentation */
    if (!did_instrument)
        return DR_EMIT_DEFAULT;

    bool should_insert_clean_call =
        /* XXX i#1702: it is ok to skip a few clean calls on predicated instructions,
         * since the buffer will be dumped later by other clean calls.
         */
        IF_X86_ELSE(true, !instr_is_predicated(instr))
        /* FIXME i#1698: there are constraints for code between ldrex/strex pairs,
         * so we minimize the instrumentation in between by skipping the clean call.
         * However, there is still a chance that the instrumentation code may clear the
         * exclusive monitor state.
         */
        IF_ARM(&& !instr_is_exclusive_store(instr));
    if (!should_insert_clean_call)
        return DR_EMIT_DEFAULT;

    /* We dump the writes to stdout. In the case of a call instruction, we pre-insert
     * instrumentation so writes appear in order. Otherwise, we post-insert for ease
     * of getting the written value.
     */
    if (!instr_is_call(instr)) {
        instr_t *next = instr_get_next(instr);
        dr_insert_clean_call(drcontext, bb, next, (void *) post_mov, false, 0);
    } else {
        /* for call instruction, this is xip to be pushed onto the stack */
        byte * curr_pc = instr_get_app_pc(instr);
        app_pc next_pc = decode_next_pc(drcontext, curr_pc);
        opnd_t pc = IF_X86_ELSE(OPND_CREATE_INTPTR,OPND_CREATE_INT)(next_pc);
        dr_insert_clean_call(drcontext, bb, instr, (void *) pre_call, false, 1, pc);
    }

    return DR_EMIT_DEFAULT;
}

/* We transform string loops into regular loops so we can more easily
 * monitor every memory reference they make.
 */
static dr_emit_flags_t
event_bb_app2app(void *drcontext, void *tag, instrlist_t *bb,
                 bool for_trace, bool translating)
{
    if (!drutil_expand_rep_string(drcontext, bb)) {
        DR_ASSERT(false);
        /* in release build, carry on: we'll just miss per-iter refs */
    }
    return DR_EMIT_DEFAULT;
}

/********************************************************************************
 * SYSCALL HANDLERS, TO HOOK STDOUT AND STDERR
 */

static int
get_write_sysnum(void)
{
#ifdef UNIX
    return SYS_write;
#else
    byte *entry;
    module_data_t *data = dr_lookup_module_by_name("ntdll.dll");
    DR_ASSERT(data != NULL);
    entry = (byte *) dr_get_proc_address(data->handle, "NtWriteFile");
    DR_ASSERT(entry != NULL);
    dr_free_module_data(data);
    return drmgr_decode_sysnum_from_wrapper(entry);
#endif
}

static bool
event_filter_syscall(void *drcontext, int sysnum)
{
    return sysnum == write_sysnum;
}

#ifdef UNIX
# define FD_ARG 0
# define OUTPUT_ARG 1
# define SIZE_ARG 2
#else
# define FD_ARG 0
# define OUTPUT_ARG 5
# define SIZE_ARG 6
#endif

/* generally strive to make this function very thread-safe */
static bool
event_pre_syscall(void *drcontext, int sysnum)
{
    if (sysnum == write_sysnum) {
        per_thread_t *data = drmgr_get_tls_field(drcontext, tls_idx);

        /* get info */
        int fd = dr_syscall_get_param(drcontext, FD_ARG);
        if (fd == STDERR || fd == STDOUT) {
            byte *out = (byte *) dr_syscall_get_param(drcontext, OUTPUT_ARG);
            size_t size = dr_syscall_get_param(drcontext, SIZE_ARG);

            /* Base64encode_len provides null byte so no size+1 */
            size_t base64_len = Base64encode_len(size);
            byte *base64 = malloc(base64_len);
            Base64encode(base64, out, size);

            dr_fprintf(data->log, "%s:%s\n",
                       fd == STDERR ? "stderr" : "stdout" , base64);
            free(base64);
        }
    }
    return true;
}

/********************************************************************************
 * STACKVIS_* ANNOTATION HANDLERS
 */

void
handle_stackvis_impromptu_breakpoint(void)
{
    void *drcontext = dr_get_current_drcontext();
    per_thread_t *data = drmgr_get_tls_field(drcontext, tls_idx);
    dr_fprintf(data->log, "breakpoint\n");
}

void
handle_stackvis_clear_annotation(void)
{
    void *drcontext = dr_get_current_drcontext();
    per_thread_t *data = drmgr_get_tls_field(drcontext, tls_idx);
    dr_fprintf(data->log, "clear annotations\n");
}

void
handle_stackvis_stack_annotation(byte *pc, char *label)
{
    void *drcontext = dr_get_current_drcontext();
    per_thread_t *data = drmgr_get_tls_field(drcontext, tls_idx);
    dr_fprintf(data->log, "label:%s addr:%"PRIuPTR"\n",
            label, (app_pc) pc);
}

/********************************************************************************
 * INIT, EXIT ROUTINES AND MAIN
 */

static void
event_thread_init(void *drcontext)
{
    per_thread_t *data = dr_thread_alloc(drcontext, sizeof(per_thread_t));
    DR_ASSERT(data != NULL);
    drmgr_set_tls_field(drcontext, tls_idx, data);

    /* Keep seg_base in a per-thread data structure so we can get the TLS
     * slot and find where the pointer points to in the buffer.
     */
    data->seg_base = dr_get_dr_segment_base(tls_seg);
    data->buf_base = dr_raw_mem_alloc(MEM_BUF_SIZE,
                                      DR_MEMPROT_READ | DR_MEMPROT_WRITE,
                                      NULL);
    data->stk_base = NULL;
    DR_ASSERT(data->seg_base != NULL && data->buf_base != NULL);
    /* put buf_base to TLS as starting buf_ptr */
    BUF_PTR(data->seg_base) = data->buf_base;

    /* We're going to dump our data to a per-thread file.
     * On Windows we need an absolute path so we place it in
     * the same directory as our library. We could also pass
     * in a path as a client argument.
     */
    data->log = log_file_open(client_id, drcontext, NULL, "drstackvis",
#ifndef WINDOWS
                              DR_FILE_CLOSE_ON_FORK |
#endif
                              DR_FILE_ALLOW_LARGE);
}

static void
event_thread_exit(void *drcontext)
{
    per_thread_t *data;
    data = drmgr_get_tls_field(drcontext, tls_idx);
    log_file_close(data->log);
    dr_raw_mem_free(data->buf_base, MEM_BUF_SIZE);
    dr_thread_free(drcontext, data, sizeof(per_thread_t));
}

static void
event_exit(void)
{
    if (!dr_raw_tls_cfree(tls_offs, MEMTRACE_TLS_COUNT))
        DR_ASSERT(false);

    if (!drmgr_unregister_tls_field(tls_idx) ||
        !drmgr_unregister_thread_init_event(event_thread_init) ||
        !drmgr_unregister_thread_exit_event(event_thread_exit) ||
        !drmgr_unregister_bb_app2app_event(event_bb_app2app) ||
        !drmgr_unregister_bb_insertion_event(event_app_instruction))
        DR_ASSERT(false);

    drutil_exit();
    drmgr_exit();
}


DR_EXPORT void
dr_client_main(client_id_t id, int argc, const char *argv[])
{
    dr_set_client_name("DynamoRIO Client 'drstackvis'",
                       "http://dynamorio.org/issues");
    if (!drmgr_init() || !drutil_init())
        DR_ASSERT(false);

    /* cache write syscall for performance in the filter */
    write_sysnum = get_write_sysnum();
    dr_register_filter_syscall_event(event_filter_syscall);
    drmgr_register_pre_syscall_event(event_pre_syscall);

    /* register events */
    dr_register_exit_event(event_exit);
    if (!drmgr_register_thread_init_event(event_thread_init) ||
        !drmgr_register_thread_exit_event(event_thread_exit) ||
        !drmgr_register_bb_app2app_event(event_bb_app2app, NULL) ||
        !drmgr_register_bb_instrumentation_event(NULL /*analysis_func*/,
                                                 event_app_instruction,
                                                 NULL))
        DR_ASSERT(false);

    /* register annotations */
    dr_annotation_register_call("stackvis_impromptu_breakpoint",
                                handle_stackvis_impromptu_breakpoint, false, 0,
                                DR_ANNOTATION_CALL_TYPE_FASTCALL);
    dr_annotation_register_call("stackvis_clear_annotation",
                                handle_stackvis_clear_annotation, false, 0,
                                DR_ANNOTATION_CALL_TYPE_FASTCALL);
    dr_annotation_register_call("stackvis_stack_annotation",
                                handle_stackvis_stack_annotation, false, 2,
                                DR_ANNOTATION_CALL_TYPE_FASTCALL);

    client_id = id;

    tls_idx = drmgr_register_tls_field();
    DR_ASSERT(tls_idx != -1);
    /* The TLS field provided by DR cannot be directly accessed from the code cache.
     * For better performance, we allocate raw TLS so that we can directly
     * access and update it with a single instruction.
     */
    if (!dr_raw_tls_calloc(&tls_seg, &tls_offs, MEMTRACE_TLS_COUNT, 0))
        DR_ASSERT(false);
}
/* vim:set tabstop=4 shiftwidth=4: */
