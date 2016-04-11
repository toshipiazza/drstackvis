DrStackVis
==========

Stack Visualizer written using DynamoRIO. Frontend is TBA.

## How To Build
The DynamoRIO Plugin can be built using `cmake -DDynamoRIO_DIR=... && make`.

## TODO DynamoRIO Plugin
* [x] write esp AFTER write occurs, current esp values are WRONG
  * [x] pass into clean call?
  * [x] make it cross-architecture
* [ ] output current output of running program
* [ ] output instruction at which write occurs (see `type` in `memtrace_simple.c`)
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
      "wmem": 0xDEADBEEF,
      "sptr": 0xffffffff }, // this is ESP
      ...
  ],
  "stk_base": 0xffffffff
}
```

# Notice
The plugin here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
Both of these files are included in this project. These files are both
distributed under the BSD 3 clause license. The code in `drstackvis.c` is
distributed under the same license.
