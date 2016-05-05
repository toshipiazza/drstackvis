import controlP5.*;
import java.util.*;
import javax.swing.JFileChooser;

ControlP5 cp5;
ScrollableList stack;
Stack s;
Textarea stderrTextArea, stdoutTextArea;

Stack parseJSON(JSONObject j) {
  JSONArray writes = j.getJSONArray("writes");
  List<Mem> smem = new ArrayList();
  Map<Integer, String> stdout = new HashMap();
  Map<Integer, String> stderr = new HashMap();

  // iterate over writes
  for (int i = 0; i < writes.size(); ++i) {
    JSONObject block = writes.getJSONObject(i);
    smem.add(new Mem(block.getLong("sptr"),
                     block.getLong("addr"),
                     (long) block.getDouble("wmem"),
                     block.getInt("size")));
  }

  // iterate over stderr
  Iterator<?> keys = j.getJSONObject("stderr").keys().iterator();
  while (keys.hasNext()) {
    String tick = (String) keys.next();
    stderr.put(Integer.parseInt(tick), j.getJSONObject("stderr").getString(tick));
  }

  // iterate over stdout
  keys = j.getJSONObject("stdout").keys().iterator();
  while (keys.hasNext()) {
    String tick = (String) keys.next();
    stdout.put(Integer.parseInt(tick), j.getJSONObject("stdout").getString(tick));
  }

  Stack s = new Stack((long) j.getDouble("stk_ceil"),
                      (long) j.getDouble("stk_base"), smem,
                      stderr, stdout);
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
    exit();
  }
  return null;
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
  stdoutTextArea = cp5.addTextarea("stdout")
    .setPosition(280, 50)
    .setSize(300, 200)
    .setColor(color(128))
    .setColorBackground(color(255,100))
    .setColorForeground(color(255,100))
    .setLineHeight(14);
  stderrTextArea = cp5.addTextarea("stderr")
    .setPosition(280, 300)
    .setSize(300, 200)
    .setColor(color(128))
    .setColorBackground(color(255,100))
    .setColorForeground(color(255,100))
    .setLineHeight(14);

  JSONObject j = chooseFile();
  s = parseJSON(j);
  Stack.Addr[] byteStack = s.getStack(1);
  stack.addItems(s.convertByteStack2Stack(byteStack));
  updateOutput();
}

void updateOutput() {
  if (s.hasStdoutInPipe())
     stdoutTextArea.setText(stdoutTextArea.getText() + new String(s.getStdoutInPipe())); 
  if (s.hasStderrInPipe())
     stderrTextArea.setText(stderrTextArea.getText() + new String(s.getStderrInPipe()));
}

public void Forward() {
  int tick = s.tick;
  Stack.Addr[] byteStack = s.getStack(tick + 1);
  stack.clear();
  stack.addItems(s.convertByteStack2Stack(byteStack)); 
  updateOutput();
}

public void FastForward() {
  println("METHOD NOT IMPLEMENTED");
}

void draw() { }

// vim:foldmethod=syntax:foldlevel=0