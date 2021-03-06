CON  'To calibrate TX bits make this the top object then send a single pulse repeatedly    
     'Finally, check RX side to see the range of values for that pulse
  _CLKMODE = XTAL1 + PLL16X        
  _XINFREQ = 5_000_000
                          
  start_bit = 192000   
  one       = 96000   
  zero      = 48000   
  interval  = 160000  '= (clkfreq/500+cnt)

OBJ    
  'pst : "Parallax Serial Terminal"

VAR
   byte index

PUB init        
   dira[1]~~  
 '  SendCode(start_bit)  
PUB SendCode(Code) 

  'pst.Start(115_200)
  'waitcnt(clkfreq*2+cnt)      
   
 ' repeat                             'CALIBRATE BITS BY UNCOMMENTING THIS LINE
  outa[1]~~
  waitcnt(start_bit + cnt)            'select 'start_bit', 'one' or 'zero' to check range of values at receiver
  outa[1]~                           
  waitcnt(interval + cnt)             'spin needs about 2ms between bits 
  index := 0
  repeat
    if ((Code >> index) & 1)  == 1    'this line evaluates the LSB
      outa[1]~~
      waitcnt(one + cnt)
      outa[1]~
    else
      outa[1]~~
      waitcnt(zero + cnt)
      outa[1]~       
    waitcnt(interval + cnt)           'pause between bits
    index++     
  while index < 8                     
  'waitcnt(interval+cnt)                       
  'pst.Str(String(pst#NL, "Code = ")) 
  'pst.Dec(Code)
  'pst.Bin(Code, 8)  

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