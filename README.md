==========

Stack Visualizer written using DynamoRIO. Frontend is TBA.

## How To Build
The DynamoRIO Plugin can be built using `cmake -DDynamoRIO_DIR=... && make`.

## TODO DynamoRIO Plugin
* [x] remove stack reasd
* [x] remove instruction reads
* [x] output valid json
* [ ] filter writes to stack values only, so that the termbox interface doesn't hang
  * do this at the termbox end?
  * can send base addr and esp at time of current write in json
* [ ] output write values instead of just addreses written to
* [ ] output instruction at which write occurs

### Later Time
* [ ] output current output of running program
* [ ] determine whether a pointer is on the stack or heap and color accordingly

> NOTE: to output current output, use dup2 to duplicate to
> some other file descriptor, then use fdopen to read it in
> incrementally, every time `memtrace` is called

## JSON Output (tentative)

```
{
  "writes": [
    { "addr": 0x08045890,
      "size": 8,
      "val":  0xDEADBEEF,   // TODO
      "fptr": 0xffffffff }, // TODO
      ...
  ],
  "base": 0xfffffff
}
```

# Notice
The plugin here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
Both of these files are included in this project. These files are both
distributed under the BSD 3 clause license.
