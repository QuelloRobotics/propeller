''***************************************
''*  EEPROM Monitor Demo v1.0           *
''*  Author: Chip Gracey                *
''*  Modified By: Chris Savage          *
''*  Copyright (c) 2010 Parallax, Inc.  *
''*  See end of file for terms of use.  *
''***************************************

' This version has been modified to refer to the EEPROM_Monitor.spin
' object rather than the original monitor.spin  The EEPROM_Monitor.spin
' object displays / edits the connected EEPROM memory, rather than the
' Propeller ROM / RAM.

CON

        _clkmode        = xtal1 + pll16x
        _xinfreq        = 5_000_000


OBJ

        mon     : "EEPROM_Monitor"                      ' Modified version of Montor.spin


PUB go

'' Starts 'Monitor' in another cog using pins 31 and 30 at 19200 baud.
'' Use a terminal program on the host machine to communicate.

  mon.start(31, 30, 19200)

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