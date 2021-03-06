{{              74hc597 v1.0
                Data Acquisition cog reading up to 4 74hc597's in series
                Written by Jim Miller
                CannibalRobotics, 2008
                This cog free runs sampling constantly. It is a great way to read multiple switch inputs
                without taking up a bunch of prop ports The 74hc597 is a good choice as it runs at 3.3v
  
                contact: jmiller5@austin.rr.com
                
                      ┌──────┐
                   B  ┫1•  16┣  Vcc                 
                   C  ┫2   15┣  A                                 
                   D  ┫3   14┣───────────────────────────────┐ ← SI  Ground this if first in the line                
                   E  ┫4   13┣─────────────────┐   ← ~Sload            
                   F  ┫5   12┣───────────────┐ │   ← Rck        
                   G  ┫6   11┣─────────────┐ │ │   ← Sck
                   H  ┫7   10┣───────────────────┐ ← ~Sclr
                 gnd  ┫7    9┣───────┐ Qh' │ │ │ │
                      └──────┘       │     │ │ │ │
                                     │     │ │ │ │
                      ┌──────┐       │     │ │ │ │    Tie all ~Sload, Rck,Sck and ~Sclr together
                   B  ┫1•  16┣  Vcc  │     │ │ │ │       
                   C  ┫2   15┣  A    │     │ │ │ │    A - H are data inputs: Vcc = 1, gnd = 0                  
                   D  ┫3   14┣───────┘ SI  │ │ │ │             
                   E  ┫4   13┣─────────────┻─│─│─│───•  ~Sload               
                   F  ┫5   12┣───────────────┻─│─│───•  Rck                 
                   G  ┫6   11┣─────────────────┻─│───•  Sck
                   H  ┫7   10┣───────────────────┻───•  ~Sclr
                 gnd  ┫7    9┣───────┐ Qh'
                      └──────┘       
                                    to next 74hc597 SI (pin 14)
                                     or prop pin Qh

}}

VAR
  Byte  bitno
  long  LatchData,LatchBuffer
  Word  LatchStack[36] 
  
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
   
  Delay = 1500                  ' Clock Delay
  Latches = 4                   ' Number of latches in series - remember, a single long can only hold 32 bits
  Bits = Latches * 8            ' Number of bits clocked in total
 
PUB Start(sload,rck,sck,sclr,Qh) :Success
                                ' Call to start,sload,rck,sck,sclr,Qh are the port numbers of the respective pins
  Success := cognew(Main(sload,rck,sck,sclr,Qh), @LatchStack)  

PUB Main(sload,rck,sck,sclr,Qh)
                                ' Set control lines direction to OUT
  dira[sload] := 1              ' Parallel data input
  dira[rck]   := 1              ' Storage clock
  dira[sck]   := 1              ' Shift clock
  dira[sclr]  := 1              ' Async Reset
  dira[Qh]    := 0              ' Data line out from shiftregister. set to Input for data

  outa[sload] := 1              ' active low
  outa[rck]   := 0              '
  outa[sck]   := 0              ' Main clock
  outa[sclr]  := 1              ' active low

                                
  outa[sclr] := 0               ' Clear Shift Register (not really necessary if pull up/down resistors placed properly). 
  waitcnt((Delay + cnt))        ' Hang for a bit to let pins change
  outa[sclr] := 1               ' finish it
   
Repeat                          ' This is the top of the loop. Each repeat will load 'bits' data into LatchBuffer.
  outa[rck] :=1                 ' Load input registers. Get set to move data from pins to first buffer
  ClockLatch(sck)               ' Actually Clock the data in
  outa[rck] :=0                 ' Go low 
  outa[sload] :=0               ' set up to move data from input register to shift register
  clockLatch(sck)               ' Actually Clock the movement
  outa[sload] :=1               ' Set to HIGH to gcomplete the load process.
  
  LatchBuffer :=0                                       ' reset LatchBuffer word
  repeat bitno from 1 to Bits                           ' OK, go around this 'bits' times - for 4
    ClockLatch(sck)                                     ' Move bit into place on input line
    LatchBuffer := LatchBuffer + ina[Qh]                ' Sample the input and add it to LatchBuffer (in bit position 0)
    LatchBuffer := LatchBuffer << 1                     ' Rotate the LatchBuffer one bit to the left
                                                        ' This will leave a 0 in the 0 position for the next go around
  LatchData := LatchBuffer >> 2                         ' Rotate bits back to compensate for over run in repeat
                                                        ' Place LatchBuffer into LatchData holder to prevent mid-stream reads
                                                        ' of latching process
                                                        
pub GetLatch : Bufr                                     ' Returns the latest read of the latch data
           Bufr := LatchData
           
PUB ClockLatch(CL)
      ' ----------------------------- Clock Latch ------------------
      waitcnt((Delay + cnt))        ' Wait
      OUTA[CL] := 1                  ' Clock up            
      waitcnt((Delay + cnt))        ' Wait
      OUTA[CL] := 0                  ' Clock Down      
      ' ----------------------------- Clock Latch ------------------

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