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
    PFont AvenirHeavy14;
    PFont AvenirBook;

//integers to access things and data structure
  ArrayList<Time> TIME;
  int current = 0;
  

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
  
  
  //expose a file chooser to the user, read that json in
  JFileChooser chooser = new JFileChooser();
  //TODO: accept only json files; involves creating a custom
  //FileFilter class that overrides boolean accept(File f);
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    //read in the json
    JSONObject j = loadJSONObject(chooser.getSelectedFile().getAbsoluteFile());
    TIME = parseJSON(j);
    
  } else {
    println("ERROR: file not chosen...");
    exit();
  }
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
  shape(STDOUT);
  shape(STDERR);
  
  //stdout
  textFont(AvenirHeavy,18);
  text("stdout",425,45);
  text("stderr",425,777-out_width-10);
  textFont(AvenirBook,13);
  String s = "Bacon ipsum dolor amet strip steak turkey drumstick corned beef jowl pancetta capicola ham hock beef pork belly landjaeger. Frankfurter beef doner, tail short loin turducken ground round swine turkey short ribs bacon spare ribs boudin. Sirloin capicola doner alcatra tenderloin pork chuck turkey. Short loin sausage porchetta biltong, boudin shank short ribs picanha corned beef pork belly t-bone pastrami ground round swine leberkas. Pork belly drumstick brisket tri-tip porchetta jerky. Pork belly leberkas tenderloin pork chop prosciutto kevin biltong tongue. Capicola kevin rump brisket shankle cupim t-bone tri-tip leberkas ham hock filet mignon boudin.\n\nPork chop doner pig capicola ham hock alcatra turducken fatback tongue tenderloin pancetta rump t-bone flank. Chuck flank doner prosciutto ribeye. Meatloaf ground round rump, shoulder bresaola chicken tri-tip ribeye short loin salami ball tip pancetta prosciutto venison pig. Rump turkey picanha tri-tip, tenderloin frankfurter kevin alcatra pig shoulder. Pork loin frankfurter porchetta turkey pancetta doner leberkas bacon spare ribs flank tongue picanha.\n\nTail swine pig, sausage pancetta tenderloin tongue meatball short ribs fatback venison pork belly. Jowl short loin tail tongue bresaola. Turkey doner ham hock shank. Sausage porchetta salami pig. Shoulder ham hock jowl swine jerky pork loin pancetta pork belly fatback. Cow sirloin pork chop filet mignon ribeye chuck capicola prosciutto. Pork loin bacon pig, sirloin chicken biltong meatloaf pancetta picanha shankle turducken ham doner filet mignon.\n\nBall tip tail jowl, prosciutto ground round shankle t-bone salami pancetta landjaeger. Pancetta tri-tip kevin swine. Ribeye pork loin salami landjaeger venison. Pork loin porchetta tongue kielbasa t-bone capicola. Ball tip ribeye venison, fatback chicken alcatra turkey.\n\nTail pork loin cow pancetta short ribs sausage. Ham hock drumstick pork belly, capicola spare ribs cupim t-bone porchetta. Swine rump tenderloin pork belly, shankle boudin flank pancetta chuck short ribs tail landjaeger sirloin. Jowl sausage shoulder leberkas tongue. Chuck biltong short ribs leberkas kielbasa shoulder ham hock shank swine flank pork chop. Fatback doner hamburger beef bacon spare ribs meatloaf venison frankfurter jowl flank pork loin pig.";
  text(s,777-out_width,52,out_width-2,out_width-27);
  
  //stderr
  text(s,777-out_width, 777-out_width,out_width-2,out_width-27);
  
  //stack
  ArrayList<String> queue = new ArrayList();
  //call function here that returns the thing
  ArrayList<PShape> canvas = new ArrayList();
  int y_val = 70;
  int colors = 100;
  for (int i=0; i<=7;++i){
    PShape toprint = new PShape();
    int y_val2 = y_val + 20;
    toprint = createShape(RECT,60,y_val,240,y_val2);
    toprint.setFill(color(colors));
    canvas.add(toprint);
    shape(toprint);
    println("[" + i + "]\ty1: " + y_val + "\ty2: " + y_val2);
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