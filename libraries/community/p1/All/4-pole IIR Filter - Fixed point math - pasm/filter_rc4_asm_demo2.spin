{{ filter_rc4_asm_demo2.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ IIR Integer Filter Demo (asm) v0.1  │ BR             │ (C)2009             │  5Dec2009     │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ Demo showing how to cascade several IIR filters to make a composite filter.                │
│ This demo uses 4 low pass filters to make a higher performance low-pass filter.            │
│                                                                                            │
│ Demo calculates filter frequency response via direct simulation with the help of the       │
│ prop's built-in math tables and a handy sin function courtesy of Ariba.  It also simulates │
│ filter impulse response and step response.                                                 │
│                                                                                            │
│ pst setup to use PLX-DAQ (enables easy plot of raw data vs filtered output).    Works      │
│ fine with pst, also...just not as easy to plot the data.                                   │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}


CON
  _clkmode        = xtal1 + pll16x    ' System clock → 80 MHz
  _xinfreq        = 5_000_000

  
var
   long in,out1,out2,out3,out    'filter output must be located adjacent to input


OBJ   
  pst      : "Parallax Serial Terminal"
  filter[4]: "filter_rc4_asm"  

  
PUB Init|coeffPtr

  waitcnt(clkfreq * 5 + cnt)
  pst.start(57600)
  pst.Str(String("MSG,Initializing...",13))
  pst.Str(String("LABEL,x_meas,x_filt",13))
  pst.Str(String("CLEARDATA",13))

' Cascade a set of four low-pass filters
  coeffPtr:=filter.synth_low_pass(200,8)           '2^4 = 16, 2^6=64, 2^8=256
  filter[0].start(@in)           
  filter[1].start(@out1)         
  filter[2].start(@out2)         
  filter[3].start(@out3)
  main

Pub Main| iter, mark, xmeas, xfilt, value, random

'======================================================
'Filter response to sinusoidal inputs (poor man's Bode)
'======================================================
mark := random := cnt
repeat  iter from 1 to 40 step 2                 'simulate 20 frequencies, highest frequency is nearly Nyquist freq
  repeat value from 0 to 359 step 4              'take 90 samples per frequency
    mark += clkfreq/50                           'output data at 50 samples/sec
    pst.Str(String("DATA, "))                    'data header for PLX-DAQ
    xmeas := sin(value*iter,200)                 'thanks Ariba
'   xmeas += iter * random? >> 28                'add some noise to the measurements
    in := xmeas
    xfilt := out

    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(13))
    waitcnt(mark)                                'wait for it...

'=================================
'Filter impulse and step responses
'=================================
mark := random := cnt
repeat  iter from 1 to 150                      
    mark += clkfreq/50                           
    pst.Str(String("DATA, "))                    
    if iter < 50
      xmeas := 1                                      'let the filter chill for a moment....
    elseif iter < 100
      xmeas := 1+ impulse_fun(iter, 51, 200)          'input impulse function
    else
      xmeas := step_fun(iter,101,200)                 'input step function

    in := xmeas
    xfilt := out
'
    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(13))
    waitcnt(mark)                                


PUB sin(degree, mag) : s | c,z,angle
''Returns scaled sine of an angle: rtn = mag * sin(degree)
'Function courtesy of forum member Ariba
'http://forums.parallax.com/forums/default.aspx?f=25&m=268690

  angle //= 360
  angle := (degree*91)~>2 ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*mag)~>16       ' return sin = -range..+range


pub cos(degree, mag) : s
''Returns scaled cosine of an angle: rtn = mag * cos(degree)

  return sin(degree+90,mag)

  
pub impulse_fun(i,trigger,mag):x_rtn
''Returns impulse function. i = current sample index
''                          trigger = sample index on which impulse is triggered
''                          mag = magnitude of impulse
    if i==trigger
      return mag
    else
      return 0


pub step_fun(i,trigger,mag):x_rtn
''Returns step function. i = current sample index
''                       trigger = sample index on which step is triggered
''                       mag = magnitude of impulse
    if i < trigger
      return 0
    else
      return mag


DAT

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    