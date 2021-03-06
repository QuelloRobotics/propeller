{{┌──────────────────────────────────────────┐      
  │ PASM demos wrapper                       │      
  │ Author: Chris Gadd                       │      
  │ Copyright (c) 2012 Chris Gadd            │      
  │ See end of file for terms of use.        │      
  └──────────────────────────────────────────┘
}}
OBJ
PASM_1_9   : "PASM 1 - 9 - Blinking LEDs"                     ' Blink LEDs to get a feel for bit-level operations
PASM_10a   : "PASM 10a - Serial transmitter using djnz"       ' Simple serial transmitter (toggling an output with a specific pattern)
PASM_10b   : "PASM 10b - Serial transmitter using waitcnt"    ' Just like 10a, except using the right command for the right job
PASM_11    : "PASM 11 - Text string using par"                ' Accessing one location in hub memory
PASM_12    : "PASM 12 - Lookup table"                         ' Accessing many locations in hub memory based on offsets
PASM_13a   : "PASM 13a - Message table"                       ' Accessing hub memory locations based on addresses (stand-alone routine only)
PASM_13b   : "PASM 13b - Message table - using @@0"           ' Accessing hub memory locations based on addresses (may be used as object in another routine)
PASM_13c   : "PASM 13c - Message table - using VAR"           ' Accessing VARs and DATs in hub memory
PASM_14    : "PASM 14 - Hex to ASCII - Dynamic data"          ' Convert a counter into ASCII and display as hexadecimal
PASM_15a   : "PASM 15a - Hex to BCD"                          ' Simple method of converting a counter into decimal
PASM_15b   : "PASM 15b - Hex to BCD"                          ' More complicated, though smaller, method of converting into decimal
PASM_16    : "PASM 16 - RC time"                              ' Determine the position of a potentiometer by measuring the amount of time it takes a capacitor to discharge
PASM_17a   : "PASM 17a - Serial receiver"                     ' Receive a character from the serial terminal, change case, and retransmit - using a single routine
PASM_17b   : "PASM 17b - Multiple cogs"                       ' Same as 17a, but splitting the receiver, transmitter, and case-changer into seperate cogs
PASM_17c1  : "PASM 17c1 - Multiple objects - parent"          ' Same as 17a, but using seperate objects for the receiver, transmitter, and case-changer
'PASM_17c2 : "PASM 17c2 - receiver"                           '
'PASM_17c3 : "PASM 17c3 - transmitter"                        '
PASM_18    : "PASM 18 - Self-modifying code"                  ' Using movs, movd, and movi


PUB blank

DAT                     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                                        