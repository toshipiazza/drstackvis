import java.util.*;
import javax.xml.bind.DatatypeConverter;

public class Mem {
  private long sptr, addr, wmem;
  private int size;
  public String type;

  Mem(long s, long a, long w, String t, int sz) {
    sptr = s;
    addr = a;
    wmem = w;
    type = t;
    size = sz;
    
  }

}

class Stack {
  private List<Mem> mem;
  private long ceil, base;
  private int tick = 0;

  /* maps tick -> pipe */
  private Map<Integer, String> stderr;
  private Map<Integer, String> stdout;

  /* internal representation */
  private Addr[] stack = new Addr[0];
  Stack(){
  }
  
  Stack(long ceil, long base, List<Mem> mem, Map<Integer, String> err, Map<Integer, String> out) {
    this.ceil = ceil;
    this.base = base;
    this.mem = mem;
    stderr = err;
    stdout = out;
  }

  public class Addr {
    boolean used;
    byte   value;
  }

  public long getCeil() {
    return ceil;
  }

  public long getBase() {
    return base;
  }

  private boolean inStackBounds(long addr) {
    return addr <= base && addr >= ceil;
  }

  private int translateAddr2Index(long addr) {
    return (int) (base - addr) - 1;
  }

  private long translateIndex2Addr(int index) {
    return (long) (base - index) - 8;
  }

  private Addr[] resizeStack(Addr[] stack, int new_size) {
    Addr[] addr = new Addr[new_size];
    for (int i = 0; i < stack.length && i < addr.length; ++i)
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
    if (next_tick == tick || (next_tick > mem.size())){
      return stack;
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
              = (byte) (value & (long) 0xFF);
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
      String accum = "[0x" + String.format("%016x", translateIndex2Addr(i)) + "] ";
      for (int j = 0; j < 8; ++j) {
        accum += getMaybeValue(byteStack[i+j]);
      }
      stack.add(accum);
    }
    return stack;
  }

  private String getMaybeValue(Stack.Addr addr) {
    if (addr.used == true)
      return String.format("%02x", addr.value);
    return "??";
  }

  public boolean hasStdoutInPipe() {
    return stdout.containsKey(tick);
  }

  public byte[] getStdoutInPipe() {
    String ret = stdout.get(tick);
    stdout.remove(tick);
    return DatatypeConverter.parseBase64Binary(ret);
  }

  public boolean hasStderrInPipe() {
    return stderr.containsKey(tick);
  }

  public byte[] getStderrInPipe() {
    String ret = stderr.get(tick);
    stderr.remove(tick);
    return DatatypeConverter.parseBase64Binary(ret);
  }
}
// vim:foldmethod=syntax:foldlevel=0