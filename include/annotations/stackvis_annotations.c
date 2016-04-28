#include "stackvis_annotations.h"

DR_DEFINE_ANNOTATION(void, stackvis_impromptu_breakpoint, (void), );
DR_DEFINE_ANNOTATION(void, stackvis_stack_annotation,
    (void *p, const char *label), );
