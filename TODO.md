DrStackVis TODO
===============

[x] remove stack reads.
[ ] output write destinations, not write addresses
[ ] output writes only as json
  [ ] filter writes to stack values only
[ ] output tick at which write occurs
[ ] output current output (use dup2 to duplicate to some other
    file descriptor, then use fdopen to read it all in bit by bit).
[ ] keep track of callstack information

Look At
=======
[x] `instrument_mem` takes write? parameter. `event_app_instruction` calls
    `instrument_mem` on reads too; remove this.
