package stack

import (
  "encodings/json"
  "fmt"
)

// Write struct, assuming x86-64 or 64bit arm
// NOTE: that we must ignore the first "dummy"
// write (all zeros)
type write struct {
  size uint16 `json:size` // size of write
  addr uint64 `json:addr` // addr at which write happened
  sptr uint64 `json:sptr` // frame pointer pre-write
  wmem uint64 `json:wmem` // value written at this time
}

type address struct {
  val uint8
  init bool
}

type Stack struct {
  writes []write   `json:writes`   // records all writes *to the stack*
  stack  []address `json:ignore`
  BStack uint64    `json:stk_base` // address of base of stack (does not change)
  TStack uint64    `json:ignore`   // address of top of stack (varies with tick)
  tick uint64      `json:ignore`   // index into Writes array
}

func InitStack(json_writes string) (s stack) {
  json.Unmarshal(json_writes, &s)
  s.tStack = s.writes[0].sptr
  s.tick = 0
  s.stack = make([]Address, 0)
  s.computeStackByteString(0)
}

func (s *stack) SetCurrentTick(tick uint64) {
  // check tick bounds
  if tick > len(s.writes) {
    tick = len(s.writes) - 1
  }

  s.stack = s.getStackByteString(tick)
  s.tick = tick
}

func (s *stack) GetValueAtAddr(addr uint64, size uint16) (uint8, bool) {
  idx := s.stack[s.addr2Index(addr)]
  return (idx.val, idx.init)
}

// private, helper functions
func (s *stack) addr2Index(addr uint64) int {
  return addr - s.BStack
}

func (s *stack) computeStackByteString(atTick int) {

}
