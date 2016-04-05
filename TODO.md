DrStackVis TODO
===============

1. remove stack reads.
2. output writes only as json
  3. filter writes to stack values only
4. output tick at which write occurs
5. output current output (use dup2 to duplicate to some other
   file descriptor, then use fdopen to read it all in bit by bit).
6. keep track of callstack information

Look At
=======
`instrument_mem` takes write? parameter. `event_app_instruction` calls
`instrument_mem` on reads too; remove this.
