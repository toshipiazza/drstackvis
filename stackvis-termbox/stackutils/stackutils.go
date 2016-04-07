package stackutils


import "fmt"


type Write struct {
  Size int `json:size`
  Addr int `json:addr`
}


type Stack struct {
  Writes    []Write
  MaxAddr int
  MinAddr int
}


func getRange(w []Write, tick int) (int, int) {
  i := 0
  lo := w[0].Addr
  hi := w[0].Addr
  for i <= tick {
    // compute max and min
    if lo > w[i].Addr {
      lo = w[i].Addr
    } else if hi < w[i].Addr {
      hi = w[i].Addr
    }

    i += 1
  }
  return lo, hi
}


func CreateStack(writes []Write) Stack {
  stack := Stack{ Writes: writes }
  return stack
}


func addr2Index(length, minAddr, addr int) int {
  return length - (addr - minAddr) - 1
}


func GetStackByteString(tick int, writes []Write) []uint16 {
  minAddr, maxAddr := getRange(writes, tick)
  length := maxAddr - minAddr + 8
  // lo bytes for value, hi bytes for init
  stack := make([]uint16, length)

  // iterate over the writes array
  i := 0
  for i <= tick && i < len(writes) {
    j := 0
    for j < writes[i].Size {
      // TODO: write actual value when available
      index := addr2Index(length, minAddr, writes[i].Addr + j)
      stack[index] = 0x0100 | 0xcc
      j += 1
    }
    i += 1
  }

  return stack
}


func SplitByteStack(minAddr, maxAddr int, byteStringStack []uint16) []string {
  length := maxAddr - minAddr + 8
  stringStack := make([]string, length/8)

  // split at every 8 elements
  i := 0
  index := 0
  tempLine := make([]byte, 8)
  for i < len(stringStack) {
    j := 0
    for j < 8 {
      if (byteStringStack[index] >> 8) == 1 {
        tempLine[j] = byte(byteStringStack[index] & 0xFF)
      } else {
        tempLine[j] = byte('?')
      }

      index += 1
      j += 1
    }
    stringStack[i] = fmt.Sprintf("[%x] %x", minAddr + i*8, tempLine)
    i += 1
  }

  return stringStack
}


// We construct a single array representing the entire
// stack, byte for byte. Then we squash it into an array
// of strings that represent 8 byte chunks
func (s *Stack) CreateStackString(tick int) []string {
  if tick < 0 {
    tick = 0
  }
  if tick >= len(s.Writes) {
    tick = len(s.Writes) - 1
  }

  byteStringStack := GetStackByteString(tick, s.Writes)
  minAddr, maxAddr := getRange(s.Writes, tick)
  return SplitByteStack(minAddr, maxAddr, byteStringStack)
}
