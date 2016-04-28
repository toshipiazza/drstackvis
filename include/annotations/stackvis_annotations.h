#ifndef _STACKVIS_ANNOTATIONS_H_
#define _STACKVIS_ANNOTATIONS_H_ 1

#include "annotations/dr_annotations_asm.h"

#ifdef __GNUC__
# pragma GCC system_header
#endif

#define STACKVIS_IMPROMPTU_BREAKPOINT() \
    stackvis_impromptu_breakpoint()
#define STACKVIS_STACK_ANNOTATION(addr, label) \
    DR_ANNOTATION(stackvis_stack_annotation, addr, label)

#ifdef __cplusplus
extern "C" {
#endif

DR_DECLARE_ANNOTATION(void, stackvis_impromptu_breakpoint, (void));
DR_DECLARE_ANNOTATION(void, stackvis_stack_annotation,
    (void *p, const char *label));

#ifdef __cplusplus
}
#endif
#endif
