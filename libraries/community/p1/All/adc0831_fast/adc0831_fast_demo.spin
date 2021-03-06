{{ 
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ adc0831_fast DEMO                   │  BR            │ (C)2011             │  31May2011    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ Demo of adc0831asm driver.  Uses a cog to get 8-bit adc samples at a max rate of           │
│ 30,000 samples/sec.                                                                        │
│                                                                                            │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
CON 
  _clkmode = xtal1 + pll16x       
  _XinFREQ = 5_000_000
'hardware constants
  cs             = 0       'chip select pin
  clk            = 1       'clock pin
  d0             = 2       'data pin
'software constants
  sampleRate     = 30000   'adc sample rate (samples/sec)


obj
  pst: "Parallax Serial Terminal"
  adc: "adc0831_fast"


var
 long adcOut


pub go|tmp
  pst.start(115_200)
  adc.start(cs,clk,d0,sampleRate,@adcOut)
  waitcnt(clkfreq*5+cnt)
  pst.Str(String("adc0831_fast demo",13))
  repeat
    pst.dec(adcOut)
    pst.newline
    waitcnt(clkfreq/5+cnt)


dat
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
  