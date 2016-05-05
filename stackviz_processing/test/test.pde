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
  int current = 0;
  
  ScrollableList stack;
  Stack s;
  Textarea stderr, stdout;
  List<String> StringQueue = new ArrayList<String>();
  

//start helper functions here
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

//a helper function to the programmer: prints the contents of TIME
void testing(ArrayList<Time> T){
  for (int i=0; i<T.size(); i++){
    Time time = T.get(i);
    println("========\nTIME: " + i);
    for (int j=0; j<time.Blocks.size();j++){
      Mem m = time.Blocks.get(j);
      println("\tMEM[" + j + "]");
      m.Print();      
    }
  }
}

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
}

public void FastForward() {
  // TODO
  println("METHOD NOT IMPLEMENTED");
}

void draw(){
  //TODO   
 update(mouseX,mouseY); //DETECT WHERE THE MOUSE IS
  
  textFont(AvenirHeavy,18); //print buttons
  shape(b_back,0,0);
    text("Back",44,50);
    fill(50,50,50);
  shape(b_forward,0,0);
    text("Forward",269,50);
    fill(50,50,50);
  int c = current + 1;
  text("Write " + c + "/" + s.mem.size(), 120, 50);
  shape(STDOUT);
  shape(STDERR);
  
  
  //stdout
  textFont(AvenirHeavy,18);
  text("stdout",425,45);
  text("stderr",425,777-out_width-10);
  textFont(AvenirBook,13);
  String s = "this is some output";
  text(s,777-out_width,52,out_width-2,out_width-27);
  
  //stderr
  text(s,777-out_width, 777-out_width,out_width-2,out_width-27);
  
  //stack
  int y_val = 70;
  int colors = 100;
  for (int i=0; i<=7;++i){
    PShape toprint = new PShape();
    int y_val2 = y_val + 20;
    toprint = createShape(RECT,60,y_val,240,y_val2);
    toprint.setFill(color(colors));
    //canvas.add(toprint);
    shape(toprint);
    //println("[" + i + "]\ty1: " + y_val + "\ty2: " + y_val2);
    y_val += 20;
    colors += 20;
  }
  
  
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