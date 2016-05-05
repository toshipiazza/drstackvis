import controlP5.*; //library used for UI/string input
import javax.xml.bind.DatatypeConverter; //b64
import javax.swing.JFileChooser;
import java.lang.*;
import java.util.*;

ControlP5 cp5;
//GUI VARIABLES:
  //Buttons
    PShape b_back; //back button
    boolean goBack = false; //bool that back button is hovered on
    PShape b_forward; //forward button
    boolean goFor = false; //bool that forward button is hovered on
    int b_BoxWidth = 80; //width of forward/back
    int b_BoxHeight = 35; //height of forward/back

  //Stdout, Stderr
    PShape STDOUT;
    PShape STDERR;
    int out_width = 350;

  //FORMATTING, TYPOGRAPHY AND THE LIKE
    PFont AvenirHeavy;
    PFont AvenirHeavy14;
    PFont AvenirBook;

//integers to access things and data structure
  ArrayList<Time> TIME;
  int current = 1;
  
  ScrollableList stack;
  Stack s;
  Textarea stderr, stdout;
  List<String> StringQueue = new ArrayList<String>();
  

//start helper functions here
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
    return null;
  }
}

//a helper function to the programmer: prints the contents of TIME
/*void testing(ArrayList<Time> T){
  for (int i=0; i<T.size(); i++){
    Time time = T.get(i);
    println("========\nTIME: " + i);
    for (int j=0; j<time.Blocks.size();j++){
      Mem m = time.Blocks.get(j);
      println("\tMEM[" + j + "]");
      m.Print();      
    }
  }
}*/

void setup(){
  size(800,800);
  background(245);
  //load fonts
    AvenirHeavy = loadFont("AvenirHeavy-18.vlw");
    AvenirHeavy14 = loadFont("AvenirHeavy-14.vlw");
    AvenirBook = loadFont("AvenirBook-13.vlw");
  //creating back/forward buttons
    b_back = createShape(RECT, 25, 25, b_BoxWidth, b_BoxHeight,8); //center at (65,52.5)
    b_forward = createShape(RECT, 265, 25, b_BoxWidth, b_BoxHeight,8); //center at (305,52.5)
    b_back.setStroke(false);
    b_forward.setStroke(false);
    b_back.setFill(color(#99DCC3));
    b_forward.setFill(color(#99DCC3));
  //stdout, stderr
    STDOUT = createShape(RECT, 775-out_width,50,out_width,out_width-25);
    STDERR = createShape(RECT, 775-out_width, 775-out_width,out_width,out_width-25);
  
  
  JSONObject j = chooseFile();
  s = parseJSON(j);
  Stack.Addr[] byteStack = s.getStack(1);
  StringQueue = s.convertByteStack2Stack(byteStack);
   for (int i=0; i<StringQueue.size();i++){
    String thing = StringQueue.get(i);
    println("queue[" + i + "]: " + thing);
  }
}

public void Forward() {
  Stack.Addr[] byteStack = s.getStack(s.tick + 1);
  StringQueue.clear();
  StringQueue = s.convertByteStack2Stack(byteStack);
  println(s.tick);
}

public void FastForward() {
  // TODO
  println("METHOD NOT IMPLEMENTED");
}

void draw(){
  //TODO   
 update(mouseX,mouseY); //DETECT WHERE THE MOUSE IS
  background(245);
  textFont(AvenirHeavy,18); //print buttons
  shape(b_back,0,0);
    text("Back",44,50);
    fill(50,50,50);
  shape(b_forward,0,0);
    text("Forward",269,50);
    fill(50,50,50);
  text("Write " + current + "/" + s.mem.size(), 120, 50);
  shape(STDOUT);
  shape(STDERR);
  
  
  //stdout
  int y = 70;
  for (int i=0; i<StringQueue.size();i++){
    PShape toprint = new PShape();
    toprint = createShape(RECT,40,y,285,20);
    toprint.setFill(color(230));
    shape(toprint);
    
  
    textFont(AvenirBook,14);
    String string = StringQueue.get(i);
    text(string,45,y+14);
    y += 20;
    
  }
  
  //stderr
  String stderror = "stderror";
  text(stderror,777-out_width, 777-out_width,out_width-2,out_width-27);
  
  //stack
  /*
  int y_val = 70;
  int colors = 100;
  PShape toprint = new PShape();
  toprint = createShape(RECT,60,70,240,20);
  shape(toprint);
  toprint.setFill(color(colors));*/
   
  
  
  
}

void update(int x, int y){
  hover_reset(); //set everything to false
  //test for backwards/forwards in time???
  if (hovering(25, 25, b_BoxWidth, b_BoxHeight)){
    goBack = true;
    b_back.setFill(color(#50c89b));//setfill
  } else if (hovering(265, 25, b_BoxWidth, b_BoxHeight)){
    goFor = true;
    b_forward.setFill(color(#50c89b));
  }
}

void mousePressed(){
  println("mouse was pressed");
  
  if (goBack){
    println("BACKWARDS IN TIME");
  }
  if (goFor){
    println("FORWARDS IN TIME");
    Forward();
    println("current: " + current + "\twritesize: " + s.mem.size());
    if (current < s.mem.size()){
      current += 1;
    }
    
   for (int i=0; i<StringQueue.size();i++){
    String thing = StringQueue.get(i);
    println("queue[" + i + "]: " + thing);
  }
    clear();
    redraw();
  }
}

//hovering for rectangles (buttons, stack elements)
boolean hovering(int x, int y, int width, int height){ 
  if (mouseX >= x && mouseX <= x+width &&
      mouseY >= y && mouseY <= y+height){
        return true;
      } else {
        return false;
      }
}

void hover_reset(){
  goBack = false;
  goFor = false;
  b_back.setFill(color(#99DCC3));
  b_forward.setFill(color(#99DCC3));
}