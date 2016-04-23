import controlP5.*; //library used for UI/string input
import javax.xml.bind.DatatypeConverter; //b64
import javax.swing.JFileChooser;

ControlP5 cp5;

//start helper functions here
void parseJSON(JSONObject j){
  //TODO: read in stdout, stderr
  double stk_ceil = j.getDouble("stk_ceil");
  double stk_base = j.getDouble("stk_base");
  
  JSONArray writes = j.getJSONArray("writes");
  
  println("stk_ceil: " + stk_ceil);
  println("stk_base: " + stk_base);
  for (int i=0; i<writes.size(); i++){ //go through writes
    JSONObject block = writes.getJSONObject(i);
    double sptr = block.getDouble("sptr");
    double addr = block.getDouble("addr");
    double wmem = block.getDouble("wmem");
    int size = block.getInt("size");
    
    println("sptr: " + sptr +
            "\taddr: " + addr +
            "\twmem: " + wmem +
            "\tsize: " + size + "\n");

    //create a class object Mem with these items
    //also need to convert double to hex
  }
}

void setup(){
  //expose a file chooser to the user, read that json in

  JFileChooser chooser = new JFileChooser();
  //TODO: accept only json files; involves creating a custom
  //FileFilter class that overrides boolean accept(File f);
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    //read in the json
    JSONObject j = loadJSONObject(chooser.getSelectedFile().getName());
    parseJSON(j);
    println("json file has been read"); //confirm end of readjson
  } else {
    println("ERROR: file not chosen...");
    exit();
  }
}

void draw(){
  //TODO
}

//input path

//read json file
// address
// size
// spointer
// wmem

//create objects from the json
// determine height