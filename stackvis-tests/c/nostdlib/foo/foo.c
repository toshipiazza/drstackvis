/* compile with -nostartfiles -static */
void
_start(void)
{
  int i, j = 0xdeadbeef;
  for (i = 0; i < 1000; ++i) {
    j += 0xcafebabe;
  }
  _exit(0);
}
