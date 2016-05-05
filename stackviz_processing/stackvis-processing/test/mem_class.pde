

class Time {
  ArrayList<Mem> Blocks = new ArrayList<Mem>();
  String place = ""; //used to test for call by sharing
  Time(){ //default constructor
  }
  
  Time(Time t){ //copy without dealing with call by sharing
    //go through each old mem block
    ArrayList<Mem> old = t.Blocks;
    for (int i=0; i<old.size(); i++){
      Mem m_old = old.get(i);
      long p = m_old.sptr;
      long a = m_old.addr;
      long w = m_old.wmem;
      int s = m_old.size;
      Mem created = new Mem(p,a,w,s); //make a new mem block
      Blocks.add(created); //add this mem block to self.blocks
    }   
  }
}

class Mem {
  long sptr;
  long addr;
  long wmem;
  int size;
  
  Mem(long p, long a, long w, int s){
    sptr = p;
    addr = a;
    wmem = w;
    size = s;
  }
  
  void Print(){
    String p = String.format("%08X",(0xFFFFFF & sptr));
    String a = String.format("%08X",(0xFFFFFF & addr));
    String w = String.format("%08X",(0xFFFFFF & wmem));
    String s = Integer.toString(size);
    println("sptr: 0x" + p);
    println("addr: 0x" + a);
    println("wmem: 0x" + w);
    println("size: " + s);
  }
}