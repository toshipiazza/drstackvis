/* #include "annotations/stackvis_annotations.h" */
#include <stdio.h>
#include <cstdlib>
#include <cstdint>
#include <unistd.h>

extern "C" void
call_me(uintptr_t i, uintptr_t &j)
{
  /* STACKVIS_STACK_ANNOTATION(&i, "i_inner"); */
  /* STACKVIS_STACK_ANNOTATION(&j, "j_inner"); */
  write(1, &i, sizeof(uintptr_t));
  write(1, "\n", 1);
  write(2, &j, sizeof(uintptr_t));
  write(2, "\n", 1);
  j = 0x4343434343434343;

  /* STACKVIS_IMPROMPTU_BREAKPOINT(); */
}

extern "C" void _exit(int);
extern "C" void
_start(void)
{
  uintptr_t i = 0x4141414141414141;
  uintptr_t j = 0x4242424242424242;
  /* STACKVIS_STACK_ANNOTATION(&i, "i"); */
  /* STACKVIS_STACK_ANNOTATION(&j, "j"); */
  call_me(i, j);
  /* STACKVIS_CLEAR_ANNOTATION(); */
  _exit(0);
}
