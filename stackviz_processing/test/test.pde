import controlP5.*; //library used for UI/string input
import javax.xml.bind.DatatypeConverter; //b64
import javax.swing.JFileChooser;
import java.lang.*;

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
    PFont AvenirBook;

//start helper functions here
ArrayList<Time> parseJSON(JSONObject j){
  //TODO: read in stdout, stderr
  ArrayList<Time> T = new ArrayList();
  long stk_ceil = (long) j.getDouble("stk_ceil");
  long stk_base = (long) j.getDouble("stk_base");
  
  JSONArray writes = j.getJSONArray("writes");
  //create initial Time
  Time Initial = new Time();
  for (int i=0; i<writes.size(); i++){ //go through writes    
    Time t = new Time(Initial);
    
    JSONObject block = writes.getJSONObject(i);
    long sptr = (long) block.getDouble("sptr");
    long addr = (long) block.getDouble("addr");
    long wmem = (long) block.getDouble("wmem");
    int size = block.getInt("size");
     
    Mem m = new Mem(sptr, addr, wmem, size);
   
    t.Blocks.add(m);
    T.add(t);
    Initial = t;  
    
  }
  testing(T);
  return T;
}

//
void testing(ArrayList<Time> T){
  for (int i=0; i<T.size(); i++){
    Time time = T.get(i);
    println("========\nTIME: " + i);
    for (int j=0; j<time.Blocks.size();j++){
      Mem m = time.Blocks.get(j);
      println("\tMEM[" + j + "]");
      m.Print();
      //println("\tsptr: " + Long.toHexString(m.sptr));
      //println("\taddr: " +  Long.toHexString(m.addr));
      //println("\twmem: " +  Long.toHexString(m.wmem));
      //println("\tsize: " + m.size + "\n");
      
    }
  }
}

void setup(){
  size(800,800);
  background(245);
  //load fonts
    AvenirHeavy = loadFont("AvenirHeavy-18.vlw");
    AvenirBook = loadFont("AvenirBook-13.vlw");
  //creating back/forward buttons
    b_back = createShape(RECT, 25, 25, b_BoxWidth, b_BoxHeight,8); //center at (65,52.5)
    b_forward = createShape(RECT, 265, 25, b_BoxWidth, b_BoxHeight,8); //center at (305,52.5)
    b_back.setStroke(false);
    b_forward.setStroke(false);
    b_back.setFill(color(#99DCC3));
    b_forward.setFill(color(#99DCC3));
  //stdout, stderr
    STDOUT = createShape(RECT, 775-out_width,25,out_width,out_width);
    STDERR = createShape(RECT, 775-out_width, 775-out_width,out_width,out_width);
  
  
  //expose a file chooser to the user, read that json in
  JFileChooser chooser = new JFileChooser();
  //TODO: accept only json files; involves creating a custom
  //FileFilter class that overrides boolean accept(File f);
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    //read in the json
    JSONObject j = loadJSONObject(chooser.getSelectedFile().getAbsoluteFile());
    ArrayList<Time> TIME = parseJSON(j);
    
  } else {
    println("ERROR: file not chosen...");
    exit();
  }
}

void draw(){
  //TODO
  
  //print stack
  //print stdout
  //print stderr
  //print button for forward
  //print button for back
    //if forward or back, go forward/back a time thing
    //redraw
    
 update(mouseX,mouseY);
  textFont(AvenirHeavy,18);
  shape(b_back,0,0);
    text("Back",44,50);
    fill(50,50,50);
  shape(b_forward,0,0);
    text("Forward",269,50);
    fill(50,50,50);
  shape(STDOUT);
  shape(STDERR);
  
  //stdout
  textFont(AvenirBook,13);
  String s = "lorem ipsum dolor sit amet";
  text(s,777-out_width,27,out_width-2,out_width-2);
  
}

void update(int x, int y){
  hover_reset(); //set everything to false
  //test for backwards/forwards in time???
  if (hovering(25, 25, b_BoxWidth, b_BoxHeight)){
    goBack = true;
  } else if (hovering(265, 25, b_BoxWidth, b_BoxHeight)){
    goFor = true;
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
}