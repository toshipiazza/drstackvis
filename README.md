DrStackVis
==========

Stack Visualizer written using DynamoRIO. Frontend is in Processing (coming soon).

## How To Build
The DynamoRIO Plugin can be built using `cmake -DDynamoRIO_DIR=... && make`.

## TODO DynamoRIO Plugin
* [ ] use only pre-insert clean calls, gleam written value from registers or other opnds
* [x] pre-syscall, run base-64 encoding of stdout/stderr
  * [x] weird value for windows fd (=32), should we just output stderr vs stdout in log file?
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
  "stdout": {
    "10000": "<base64 encoding>", // here, 10000 represents an index
      ...                         // into the writes array above
  },
  "stderr": {
    "12000": "<base64 encoding>" },
      ...
  },
  "stk_base": 0xffffffff,
  "stk_ceil": 0xfffffff0
}
```

# Notice
The plugin here was heavily modified from `utils.[ch]` and `memtrace_simple.c`,
which are included in the sample files of a standard DynamoRIO distribution.
Also used for syscall hooking was the `syscall.c` sample code, also distrbuted
with DynamoRIO. These files are all distributed under the BSD 3 clause license.
The code in `drstackvis.c` is distributed under the same license.

Meanwhile, the files `base64.[ch]` are distributed under the apple public license,
or the APL. The links to these files were found
[here](http://opensource.apple.com//source/QuickTimeStreamingServer/QuickTimeStreamingServer-452/CommonUtilitiesLib/base64.c)
