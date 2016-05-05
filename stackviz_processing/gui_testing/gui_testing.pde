import controlP5.*;
import java.util.*;
import javax.swing.JFileChooser;

ControlP5 cp5;
ScrollableList stack;
Stack s;
Textarea stderr, stdout;

Stack parseJSON(JSONObject j) {
  Stack s = new Stack();
  s.ceil = (long) j.getDouble("stk_ceil");
  s.base = (long) j.getDouble("stk_base");

  JSONArray writes = j.getJSONArray("writes");
  for (int i = 0; i < writes.size(); ++i) {
    JSONObject block = writes.getJSONObject(i);
    Stack.Mem mem = s.new Mem();
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
  Stack.Addr[] byteStack = s.getStack(1);
  stack.addItems(s.convertByteStack2Stack(byteStack));
}

public void Forward() {
  Stack.Addr[] byteStack = s.getStack(s.tick + 1);
  stack.clear();
  stack.addItems(s.convertByteStack2Stack(byteStack));
}

public void FastForward() {
  // TODO
  println("METHOD NOT IMPLEMENTED");
}

void draw() { }

// vim:foldmethod=syntax:foldlevel=0
