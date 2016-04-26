/* compile with -nostartfiles */

#include <stdlib.h>
void
_start(void)
{
  int x[100];
  int i;
  for (i = 0; i < 100; ++i) {
    x[i] = 100 - i;
  }
  exit(0);  
}
