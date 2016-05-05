/* gcc -nostartfiles -static -std=c++11 */
#include <stdio.h>
#include <cstdlib>
#include <cstdint>
#include <unistd.h>

void
call_me(uintptr_t i, uintptr_t &j)
{
  uintptr_t *addr_i = &i,
            *addr_j = &j;
  write(1, &addr_i, sizeof(uintptr_t *));
  write(1, "\n", 1);
  write(1, &addr_j, sizeof(uintptr_t *));
  write(1, "\n", 1);
  j += i;
}

extern "C" void _exit(int);
extern "C" void
_start(void)
{
  uintptr_t i = 0xdeadbeef;
  uintptr_t j = 0xcafebabe;
  call_me(i, j);
  _exit(0);
}

