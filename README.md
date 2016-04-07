==========

Stack Visualizer written using DynamoRIO. The frontend will be written in termbox-go
as a cross-platform alternative to ncurses for the "GUI".

## How To Build
The DynamoRIO Plugin can be built using `cmake -DDynamoRIO_DIR=... && make`.
The termbox interface can be built with simple `go build`. Sorry all the build
logic couldn't all be in a single place!

## TODO DynamoRIO Plugin
* [x] remove stack reasd
* [x] remove instruction reads
* [x] output valid json
* [ ] filter writes to stack values only, so that the termbox interface doesn't hang
* [ ] output write values instead of just addreses written to
* [ ] output instruction at which write occurs

### Later Time
* [ ] output current output of running program
* [ ] json specifies whether instruction was a return statement, so we know the
      true stack boundary
   * [ ] alternatively, just output esp (and ebp) at each iteration
* [ ] determine whether a pointer is on the stack or heap and color accordingly

> NOTE: to output current output, use dup2 to duplicate to
> some other file descriptor, then use fdopen to read it in
> incrementally, every time `memtrace` is called

## TODO Termbox Frontend
* [X] simple json parsing
* [X] draw stack onto the screen
* [ ] show current write, and provide a way to jump to other writes fast

### Later Time
* [ ] show output on separate pane
* [ ] able to search for an output string
* [ ] input tick number vs index
* [ ] display callstack information

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
The plugin here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
Both of these files are included in this project. These files are both
distributed under the BSD 3 clause license.
