DrStackVis
==========

Stack Visualizer written using DynamoRIO.

## TODO
[x] remove stack reads
[x] remove instruction reads
[x] output json
  [ ] use jannson or other small c library, wrap malloc
[ ] filter writes to stack values only
[ ] output write values
[ ] output instruction

### Later Time
[ ] output current output
[ ] output tick at which write occurs
[ ] keep track of callstack information

> NOTE: to output current output, use dup2 to duplicate to
> some other file descriptor, then use fdopen to read it in
> incrementally

## JSON Output

```
[
  { "addr": 0x08045890,
    "size": 8,
    "val":  0xDEADBEEF,    // TODO
    "inst": "mov eax 0xff" // TODO
    "tick": 1 },           // TODO
  ...
]
```

# Notice
The code here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
Both of these files are included in this project. These files are both
distributed under the BSD 3 clause license.
