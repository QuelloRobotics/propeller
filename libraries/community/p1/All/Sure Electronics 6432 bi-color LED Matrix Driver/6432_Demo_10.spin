' 6432 3mm Bi-color display test... 1.0

' This is the small 64x32 Bi-color LED matrix from Sure Electronics.
' The demo was written with Brad's Spin tool on Ubuntu... ;-)

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ
  driver      : "6432_Driver_10"            ' LED Driver
  graph       : "6432_Graphics_10"          ' LED Graphics routines.

VAR

 long waiter ' To get even wait periods.

PUB start

  driver.start
  graph.start(driver.getBitmap)

  graph.print_string(0,0,  String("HELLO"), 1)
  graph.print_string(8,0,  String("WORLD"), 2)

  graph.line(5, 16, 60, 22, 3)

  graph.initScroll

  waiter := cnt
  repeat
        waitcnt(waiter += 3_500_000)
        graph.updateScroll
        graph.showscroll


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
