#include "annotations/stackvis_annotations.h"
#include <stdint.h>
#include <stdio.h>

void
loop(uint64_t *j)
{
  int i;
  for (i = 0; i < 100; ++i) {
    *j ^= 0xcafebabe;
  }
}

int
main(void)
{
  uint64_t j = 0xdeadbeef;
  STACKVIS_STACK_ANNOTATION(&j, "j");
  loop(&j);
  STACKVIS_IMPROMPTU_BREAKPOINT();
  loop(&j);
  STACKVIS_CLEAR_ANNOTATION();
  return 0;
}
