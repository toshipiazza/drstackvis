import controlP5.*; //library used for UI/string input
import javax.xml.bind.DatatypeConverter; //b64

ControlP5 cp5;
String PATH = "data_01.json";

//start helper functions here
void parseJSON(JSONObject j){
  double stk_ceil = j.getDouble("stk_ceil");
  double stk_base = j.getDouble("stk_base");
  
  JSONArray writes = j.getJSONArray("writes");
  
  for (int i=0; i<writes.size(); i++){ //go through writes
    JSONObject block = writes.getJSONObject(i);
    double sptr = block.getDouble("sptr");
    String type = block.getString("type");
    double addr = block.getDouble("addr");
    double wmem = block.getDouble("wmem");
    int size = block.getInt("size");
    
    println("stk_ceil: " + stk_ceil);
    println("stk_base: " + stk_base);
    println("\nsptr: " + sptr + "\naddr: " + addr + "\nwmem: " + wmem + "\nsize: " + size);
    //create a class object Mem with these items
    //also need to convert double to hex
  }
  
  
}

void readjson(String PATH){
  JSONObject j = loadJSONObject(PATH);
  parseJSON(j);
}

void setup(){
  readjson(PATH);
  println("json file has been read"); //confirm end of readjson
  
}

void draw(){
}

//input path

//read json file
// address
// size
// spointer
// wmem

//create objects from the json
// determine height