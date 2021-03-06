{{

Takes care of displaying global variables using its own cog.


Copyright (c) Javier R. Movellan, 2008
Distribution and use: MIT License (see below)


}}

CON
 
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000
  ' Configuration only required for the example serial output
  RX_PIN      = 31
  TX_PIN      = 30
  BAUD_RATE   = 9600


OBJ 
    SER  : "FullDuplexSerial"    ' Object from the standard Propeller Tool library
   
    
PUB init  

' Connect to serial line to display data
  ser.start(RX_PIN, TX_PIN, 0, BAUD_RATE)


PUB display(dataPtr)
    ser.str(string("Data = "))    
    ser.dec(LONG[dataPtr])                'display decimal 
    ser.str(string($0D, $0A))
   
PUB periodicDisplay(dataPtr)
  repeat
    display(dataPtr)
    waitcnt(clkfreq+cnt)
     
 


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