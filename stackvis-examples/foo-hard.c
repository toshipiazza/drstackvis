#include <stdint.h>
 
/* sample program that does a high number of
 * writes, using increasing values of addresses
 * and also writes.
 *
 * the json should specify something of the form:
 * wmem: 0,     addr: 0xdeadbeef -> (i)
 * wmem: 0,     addr: 0xcafebabe -> (foo)
 * wmem: 1,     addr: 0xdeadbeef
 * wmem: 1,     addr: 0xcafebabe
 * ...
 * wmem: 9999,  addr: 0xdeadbeef
 * wmem: 9999,  addr: 0xcafebabe
 * wmem: 10000, addr: 0xdeadbeef -> (i)
 */

int
main(void)
{
  uint64_t foo[10000];
  for (int i = 0; i < 10000; ++i)
    foo[i] = i;
  return 0;
}
