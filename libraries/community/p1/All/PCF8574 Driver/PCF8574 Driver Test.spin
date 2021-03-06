''PCF8574 Driver Test.spin, v1.0, Craig Weber

''┌──────────────────────────────────────────┐
''│ Copyright (c) 2008 Craig Weber           │               
''│     See end of file for terms of use.    │               
''└──────────────────────────────────────────┘

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  SCL  = 15        'PCF8574 Serial ClK line
  SDA  = 14        'PCF8574 Serial DATA line
  ADDR = 56        'PCF8574A I2C Address (A0, A1, A2 all pulled low)

  CLS  = 0
OBJ
  IO     : "PCF8574_Driver"
  Serial : "FullDuplexSerial"

PUB Main
  Serial.start(31, 30, %0000, 38400)
  
  IO.Set_Pins(SCL, SDA)

  IO.Initialize
  IO.OUT(ADDR, %11111111)

  repeat
    serial.tx(CLS)
    serial.bin(IO.IN(ADDR), 8)
    waitcnt(16_000_000 + cnt)



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