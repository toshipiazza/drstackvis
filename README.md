DrStackVis
==========

Stack Visualizer written using DynamoRIO. Frontend is TBA.

## How To Build
The DynamoRIO Plugin can be built using `cmake -DDynamoRIO_DIR=... && make`.

## TODO DynamoRIO Plugin
* [x] write esp AFTER write occurs, current esp values are WRONG
  * [x] pass into clean call?
  * [x] make it cross-architecture
* [ ] output 64 bit values (right now it's only 32 bits...?)
* [ ] use only pre-insert clean calls, gleam written value from registers or other opnds
* [ ] wrap write syscall/function, and base64 encode the output to stdout/stderr
* [x] output instruction at which write occurs (see `type` in `memtrace_simple.c`)
* [ ] determine whether a pointer is on the stack or heap and color accordingly

## JSON Output (tentative)

```
{
  "writes": [
    { "addr": 0x08045890,
      "size": 8,
      "wmem": 0xDEADBEEF,
      "type": "call",
      "sptr": 0xffffffff }, // this is ESP
      ...
  ],
  // TODO
  "stdout": [
    { "tick": 10000,
      "output": "<base64 encoding>" },
      ...
  ],
  // TODO
  "stderr": [
    { "tick": 10000,
      "output": "<base64 encoding>" },
      ...
  ]
  "stk_base": 0xffffffff
}
```

# Notice
The plugin here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
These files are both distributed under the BSD 3 clause license. The code in
`drstackvis.c` is distributed under the same license.
