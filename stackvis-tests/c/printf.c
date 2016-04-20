#include <stdio.h>

int
main(void)
{
  printf("This should be sent to stdout\n");
  fprintf(stderr, "This should be sent to stderr\n");
  printf("This should be sent to stdout\n");
  fprintf(stderr, "This should be sent to stderr\n");
  return 0;
}
