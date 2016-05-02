import controlP5.*; //library used for UI/string input
import javax.xml.bind.DatatypeConverter; //b64
import javax.swing.JFileChooser;
import java.lang.*;

ControlP5 cp5;

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
  
}