/* gcc -nostartfiles -static -std=c++11 */
#include <cstdlib>
#include <cstdint>

void
call_me(uintptr_t i, uintptr_t &j)
{
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

