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

#include <stddef.h>
#include <stdint.h>
#include "dr_api.h"
#include "drmgr.h"
#include "drutil.h"
#include "utils.h"

typedef struct _mem_ref_t {
    ushort size;
    app_pc addr;
    app_pc sptr;
} mem_ref_t;

#define MAX_NUM_MEM_REFS 4096
#define MEM_BUF_SIZE (sizeof(mem_ref_t) * MAX_NUM_MEM_REFS)

/* thread private log file and counter */
typedef struct {
    byte      *seg_base;
    mem_ref_t *buf_base;
    file_t     log;
    app_pc     stk_base;
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
#define TLS_SLOT(tls_base, enum_val) (void **)((byte *)(tls_base)+tls_offs+(enum_val))
#define BUF_PTR(tls_base) *(mem_ref_t **)TLS_SLOT(tls_base, MEMTRACE_TLS_OFFS_BUF_PTR)

#define MINSERT instrlist_meta_preinsert

static uint64_t
dereference_pointer(app_pc pc, ushort size)
{
    switch (size) {
    case 1: return *(uint8_t *) pc;
    case 2: return *(uint16_t *) pc;
    case 4: return *(uint32_t *) pc;
    case 8: return *(uint64_t *) pc;
    default: return 0;
    }
}

static void
memtrace(void *drcontext)
{
    per_thread_t *data;
    mem_ref_t *mem_ref, *buf_ptr;

    data    = drmgr_get_tls_field(drcontext, tls_idx);
    buf_ptr = BUF_PTR(data->seg_base);
    mem_ref = (mem_ref_t *) data->buf_base;

    if (data->stk_base == 0) {
        dr_query_memory(mem_ref->sptr, &data->stk_base, NULL, NULL);
    }

    /* TODO: output json? */
    for (; mem_ref < buf_ptr; mem_ref++) {
        /* filter by whether write occurs on the stack or not */
        if (mem_ref->addr >= data->stk_base)
            dr_fprintf(data->log, "addr:"PFX" size:%d sptr:"PFX" wmem:"PFX"\n",
                       mem_ref->addr, mem_ref->size, mem_ref->sptr,
                       dereference_pointer(mem_ref->addr, mem_ref->size));
    }
    BUF_PTR(data->seg_base) = data->buf_base;
}

/* clean_call dumps the memory reference info to the log file */
static void
clean_call(void)
{
    void *drcontext = dr_get_current_drcontext();
    memtrace(drcontext);
}

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
insert_save_sptr(void *drcontext, instrlist_t *ilist, instr_t *where,
                 reg_id_t base, reg_id_t scratch)
{
    scratch = reg_resize_to_opsz(scratch, OPSZ_8);
    /* steal value of stack pointer here */
    MINSERT(ilist, where,
            XINST_CREATE_move(drcontext,
                              opnd_create_reg(scratch),
                              opnd_create_reg(DR_REG_XSP)));
    MINSERT(ilist, where,
            XINST_CREATE_store(drcontext,
                               OPND_CREATE_MEMPTR(base,
                                                  offsetof(mem_ref_t, sptr)),
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

/* insert inline code to add a memory reference info entry into the buffer */
static void
instrument_mem(void *drcontext, instrlist_t *ilist, instr_t *where, opnd_t ref)
{
    reg_id_t reg_ptr = IF_X86_ELSE(DR_REG_XCX, DR_REG_R1);
    reg_id_t reg_tmp = IF_X86_ELSE(DR_REG_XBX, DR_REG_R2);
    ushort slot_ptr  = SPILL_SLOT_2;
    ushort slot_tmp  = SPILL_SLOT_3;
    ushort size;

    dr_save_reg(drcontext, ilist, where, reg_ptr, slot_ptr);
    dr_save_reg(drcontext, ilist, where, reg_tmp, slot_tmp);

    insert_save_addr(drcontext, ilist, where, ref, reg_ptr, reg_tmp);
    size = drutil_opnd_mem_size_in_bytes(ref, where);
    insert_save_size(drcontext, ilist, where, reg_ptr, reg_tmp, size);
    insert_save_sptr(drcontext, ilist, where, reg_ptr, reg_tmp);
    insert_update_buf_ptr(drcontext, ilist, where, reg_ptr, sizeof(mem_ref_t));

    /* restore scratch registers */
    dr_restore_reg(drcontext, ilist, where, reg_ptr, slot_ptr);
    dr_restore_reg(drcontext, ilist, where, reg_tmp, slot_tmp);
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

    if (!instr_is_app(instr))
        return DR_EMIT_DEFAULT;
    if (!instr_writes_memory(instr))
        return DR_EMIT_DEFAULT;

    /* insert code to add an entry for each memory write opnd */
    for (i = 0; i < instr_num_dsts(instr); i++) {
        if (opnd_is_memory_reference(instr_get_dst(instr, i)))
            instrument_mem(drcontext, bb, instr, instr_get_dst(instr, i));
    }

    /* insert code to call clean_call for processing the buffer */
    if (/* XXX i#1702: it is ok to skip a few clean calls on predicated instructions,
         * since the buffer will be dumped later by other clean calls.
         */
        IF_X86_ELSE(true, !instr_is_predicated(instr))
        /* FIXME i#1698: there are constraints for code between ldrex/strex pairs,
         * so we minimize the instrumentation in between by skipping the clean call.
         * However, there is still a chance that the instrumentation code may clear the
         * exclusive monitor state.
         */
        IF_ARM(&& !instr_is_exclusive_store(instr)))
        dr_insert_clean_call(drcontext, bb, instr_get_next(instr), (void *) clean_call, false, 0);

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
    data->log = log_file_open(client_id, drcontext, NULL /* using client lib path */,
                              "memtrace",
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
    dr_fprintf(data->log, "stk_base: "PFX"\n", data->stk_base);
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
    dr_set_client_name("DynamoRIO Sample Client 'memtrace'",
                       "http://dynamorio.org/issues");
    if (!drmgr_init() || !drutil_init())
        DR_ASSERT(false);

    /* register events */
    dr_register_exit_event(event_exit);
    if (!drmgr_register_thread_init_event(event_thread_init) ||
        !drmgr_register_thread_exit_event(event_thread_exit) ||
        !drmgr_register_bb_app2app_event(event_bb_app2app, NULL) ||
        !drmgr_register_bb_instrumentation_event(NULL /*analysis_func*/,
                                                 event_app_instruction,
                                                 NULL))
        DR_ASSERT(false);

    client_id = id;

    tls_idx = drmgr_register_tls_field();
    DR_ASSERT(tls_idx != -1);
    /* The TLS field provided by DR cannot be directly accessed from the code cache.
     * For better performance, we allocate raw TLS so that we can directly
     * access and update it with a single instruction.
     */
    if (!dr_raw_tls_calloc(&tls_seg, &tls_offs, MEMTRACE_TLS_COUNT, 0))
        DR_ASSERT(false);

    /* make it easy to tell, by looking at log file, which client executed */
    dr_log(NULL, LOG_ALL, 1, "Client 'memtrace' initializing\n");
}
/* vim:set tabstop=4 shiftwidth=4: */
