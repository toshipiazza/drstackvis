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


import fileinput
import json
import re

STK_BOUNDS = re.compile("stk_base:(\S+) stk_ceil:(\S+)")
WRITE_OCCR = re.compile("addr:(\S+) size:(\S+) sptr:(\S+) type:(\S+) wmem:(\S+)")
WRITE_SYSC = re.compile("fd:(\S+) output:(\S+)")

if __name__ == '__main__':
    tick = 0
    # even though we *can* get other file descriptors,
    # we don't particularly care about them for navigating
    data = {
        "writes": [ ],
        "stderr": { },
        "stdout": { }
            }

    for i in fileinput.input():
        res = STK_BOUNDS.match(i)
        if res is not None:
            data["stk_base"] = int(res.group(1))
            data["stk_ceil"] = int(res.group(2))
        else:
            res = WRITE_OCCR.match(i)
            if res is not None:
                data["writes"].append({
                    "addr":int(res.group(1)),
                    "size":int(res.group(2)),
                    "sptr":int(res.group(3)),
                    "type":res.group(4),
                    "wmem":int(res.group(5))
                        })
                tick += 1 # "ticks" refer to writes
            else:
                res = WRITE_SYSC.match(i)
                if res is not None:
                    fd = int(res.group(1))
                    out = res.group(2)

                    if fd == 1:
                        data["stdout"][tick] = out
                    elif fd == 2:
                        data["stderr"][tick] = out
    print(json.dumps(data, indent=4))