#!/usr/bin/env python
# **********************************************************
# Copyright (c) 2016 Toshi Piazza. All rights reserved.
# **********************************************************

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# * Neither the name of VMware, Inc. nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL VMWARE, INC. OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.


from __future__ import print_function

import fileinput
import json
import sys
import re

STK_BOUNDS = re.compile("stk_base:(\S+) stk_ceil:(\S+)")
WRITE_OCCR = re.compile("addr:(\S+) size:(\S+) sptr:(\S+) type:(\S+) wmem:(\S+)")
STDERR_OUT = re.compile("stderr:(\S+)")
STDOUT_OUT = re.compile("stdout:(\S+)")

BREAKPOINT = re.compile("breakpoint")
CLEAR_NOTE = re.compile("clear annotations")
INTRO_NOTE = re.compile("label:(\S+) addr:(\S+)")

if __name__ == '__main__':
    tick = 0
    data = {
        "writes": [ ],
        "stderr": { },
        "stdout": { },
        "bpoint": [ ],
            }
    annotations = { }

    for i in fileinput.input():
        res = STK_BOUNDS.match(i)
        if res is not None:
            data["stk_base"] = int(res.group(1))
            data["stk_ceil"] = int(res.group(2))
            continue
        res = WRITE_OCCR.match(i)
        if res is not None:
            addr = int(res.group(1))
            data["writes"].append({
                "addr":addr,
                "size":int(res.group(2)),
                "sptr":int(res.group(3)),
                "type":res.group(4),
                "wmem":int(res.group(5)),
                "note":[] if addr not in annotations else annotations[addr]
                    })
            tick += 1 # "ticks" refer to writes
            continue
        res = STDOUT_OUT.match(i)
        if res is not None:
            data["stdout"][tick] = res.group(1)
            continue
        res = STDERR_OUT.match(i)
        if res is not None:
            data["stderr"][tick] = res.group(1)
            continue
        res = BREAKPOINT.match(i)
        if res is not None:
            data["bpoint"].append(tick)
            continue
        res = CLEAR_NOTE.match(i)
        if res is not None:
            annotations = { }
            continue
        res = INTRO_NOTE.match(i)
        if res is not None:
            try: annotations[int(res.group(2))].append(res.group(1))
            except: annotations[int(res.group(2))] = [res.group(1)]
            continue
        else:
            print("Error: Could not understand line {}".format(i), file=sys.stderr)
    print(json.dumps(data, indent=4))
