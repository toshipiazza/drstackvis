class Stack {
  public List<Mem> mem = new ArrayList();
  public long ceil, base;
  private int tick = 0;
  private Addr[] stack = new Addr[0];

  public class Mem {
    public long sptr, addr, wmem;
    public int size;
  }

  public class Addr {
    boolean used;
    byte   value;
  }

  private boolean inStackBounds(long addr) {
    return addr <= base && addr >= ceil;
  }

  private int translateAddr2Index(long addr) {
    return (int) (base - addr) - 1;
  }

  private long translateIndex2Addr(int index) {
    return (long) (base - index);
  }

  private Addr[] resizeStack(Addr[] stack, int new_size) {
    Addr[] addr = new Addr[new_size];
    for (int i = 0; i < stack.length; ++i)
      addr[i] = stack[i];
    for (int i = stack.length; i < addr.length; ++i)
      addr[i] = new Addr();
    return addr;
  }

  private int calculateSize(long base, long ceil) {
    return (int) (base - ceil);
  }

  public Addr[] getStack(int next_tick) {
    assert next_tick >= tick; // we only go forward in time
    if (next_tick == tick)
      return stack;
    else if (next_tick == mem.size()) {
      // we're done
      exit();
    } else {
      ceil = mem.get(next_tick - 1).sptr;
      int new_size = calculateSize(base, ceil);
      this.stack = resizeStack(this.stack, new_size);

      for (int i = tick; i < next_tick; ++i) {
        Mem m = mem.get(i);
        long value = m.wmem;
        if (inStackBounds(m.addr)) {
          for (int j = 0; j < m.size; ++j) {
            stack[translateAddr2Index(m.addr + j)].used = true;
            stack[translateAddr2Index(m.addr + j)].value
              = (byte) ((int) value & 0xFF);
            value >>= 8;
          }
        }
      }
    }
    tick = next_tick;
    return stack;
  }

  public List<String> convertByteStack2Stack(Addr[] byteStack) {
    List<String> stack = new ArrayList();
    int i;
    // skip empty lines
    for (i = 0; i < byteStack.length; ++i) {
      if (byteStack[i].used)
        break;
    }

    for ( ; i < byteStack.length; i += 8) {
      String accum = "[" + translateIndex2Addr(i) + "] ";
      for (int j = 0; j < 8; ++j) {
        accum += getMaybeValue(byteStack[i+j]);
      }
      stack.add(accum);
    }
    return stack;
  }

  private String getMaybeValue(Stack.Addr addr) {
    if (addr.used == true)
      return String.format("%02X", addr.value);
    return "??";
  }
}
// vim:foldmethod=syntax:foldlevel=0
