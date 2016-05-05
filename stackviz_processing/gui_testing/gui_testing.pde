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

void setup(){
  size(800,800);
  //load fonts
  AvenirHeavy = loadFont("AvenirHeavy_18.vlw");
  
  //creating back/forward buttons
  b_back = createShape(RECT, 25, 25, b_BoxWidth, b_BoxHeight,8); //center at (65,52.5)
  b_forward = createShape(RECT, 265, 25, b_BoxWidth, b_BoxHeight,8); //center at (305,52.5)
  b_back.setStroke(false);
  b_forward.setStroke(false);
  
  //stdout, stderr
  STDOUT = createShape(RECT, 525,25,out_width,out_width);
  STDERR = createShape(RECT, 875-out_width, 35+out_width,out_width,100);
}
//stdout: 425,25, size of 350x350
//stderr: 

void draw(){
  update(mouseX,mouseY);
  textFont(AvenirHeavy,18);
  shape(b_back,0,0);
    text("Back",44,50);
    fill(50,50,50);
  shape(b_forward,0,0);
    text("Forward",269,50);
    fill(50,50,50);
  shape(STDOUT,0,0);
  shape(STDERR,0,0);
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