import controlP5.*;
import java.util.*;
import javax.swing.JFileChooser;

ControlP5 cp5;
ScrollableList stack;
Stack s;
Textarea stderr, stdout;

class Mem {
   public long sptr, addr, wmem;
   public int size;
}

class Stack {
   public List<Mem> mem = new ArrayList();
   public long ceil, base;
   public int tick = 0;
   
   private boolean inStackBounds(long addr) {
     return addr <= base && addr >= ceil;
   }
   
   private int translateAddr2Index(long addr) {
     return (int) (base - addr) / 8 - 1;
   }
   
   private void stackResize(int new_size) {
     while (stack.size() < new_size)
       stack.add("");
     while (stack.size() > new_size)
       stack.remove(stack.size() - 1);
   }
   
   private List<String> stack = new ArrayList();
   public List<String> getStack(int next_tick) {
     assert next_tick >= tick; // we only go forward in time
     if (next_tick == tick)
       return stack;
     else if (next_tick == mem.size()) {
       // we're done
       exit();
     } else {
       ceil = mem.get(next_tick - 1).sptr;
       int new_size = (int) (base - ceil) / 8;
       stackResize(new_size);
       
       for (int i = tick; i < next_tick; ++i) {
         Mem m = mem.get(i);
         if (inStackBounds(m.addr)) {
           // TODO: instead of m.addr, use addr2index, round to 8
           // TODO: instead of having a list of strings, use a real data structure!!!
           stack.set(translateAddr2Index(m.addr),
              "[" + String.format("%08X", m.addr) + "] "
                  + String.format("%08X", m.wmem));
         }
       }
     }
     tick = next_tick;
     return stack;
   }
}

Stack parseJSON(JSONObject j) {
  Stack s = new Stack();
  s.ceil = (long) j.getDouble("stk_ceil");
  s.base = (long) j.getDouble("stk_base");
  
  JSONArray writes = j.getJSONArray("writes");
  for (int i = 0; i < writes.size(); ++i) {
    JSONObject block = writes.getJSONObject(i);
    Mem mem = new Mem();
    mem.sptr = block.getLong("sptr");
    mem.addr = block.getLong("addr");
    mem.wmem = (long) block.getDouble("wmem");
    mem.size = block.getInt("size");
    s.mem.add(mem);
  }
  return s;
}

JSONObject chooseFile() {
  JFileChooser chooser = new JFileChooser();
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    return loadJSONObject(chooser.getSelectedFile().getAbsoluteFile());    
  } else {
    println("ERROR: file not chosen...");
    return null;
  }
}

void setup() {
  size(600, 600);
  cp5 = new ControlP5(this);
  
  // init buttons
  cp5.addButton("Forward")
     .setPosition(20, 50)
     .setSize(100, 20)
     .setCaptionLabel(">");
  cp5.addButton("FastForward")
     .setPosition(150, 50)
     .setSize(100, 20)
     .setCaptionLabel(">>");
     
  // init "stack" representation
  stack = cp5.addScrollableList("Stack")
             .setPosition(20, 100)
             .setSize(230, 400)
             .setBarHeight(20)
             .setItemHeight(20)
             .setType(ScrollableList.LIST);
             
  // init std{err,in}
  stdout = cp5.addTextarea("stdout")
              .setPosition(280, 50)
              .setSize(300, 200)
              .setColorBackground(color(255,100))
              .setLineHeight(14);
  stderr = cp5.addTextarea("stderr")
              .setPosition(280, 300)
              .setSize(300, 200)
              .setColorBackground(color(255,100))
              .setLineHeight(14);
              
  JSONObject j = chooseFile();
  s = parseJSON(j);
  stack.addItems(stripStackNewlines(s.getStack(1)));
}

List<String> stripStackNewlines(List<String> new_stack) {
  // delete all the leading empty space -- they don't help
  int i;
  for (i = 0; i < new_stack.size(); ++i) {
    if (!new_stack.get(i).equals(""))
      break;
  }
  return new_stack.subList(i, new_stack.size());
}

public void Forward() {
  List<String> new_stack = s.getStack(s.tick + 1);
  new_stack = stripStackNewlines(new_stack);
  stack.clear();
  stack.addItems(new_stack);
}

public void FastForward() {
  // TODO
}

void draw() { }

// vim:foldmethod=syntax:foldlevel=0
