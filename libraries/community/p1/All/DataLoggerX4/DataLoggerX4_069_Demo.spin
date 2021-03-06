'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │  Data Logger Demo v0.067                                                 │
'' │  Author: Ray Rodrick                                                     │
'' │  Copyright (c) 2008 Ray Rodrick                                          │
'' │  See end of file for terms of use.                                       │
'' └──────────────────────────────────────────────────────────────────────────┘
                             
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │  Acknowledgement: to Paul Baker's Logic Analyzer (dscope.spin) for the   │
'' │  inspiration and naming conventions.                                     │
'' ├──────────────────────────────────────────────────────────────────────────┤
'' │  Uses the following Objects:                                             │
'' │    Full-Duplex Serial Driver v1.1 by Chip Gracey (FullDuplexSerial.spin) │
'' │    Data Logger Object v0.066 by Ray Rodrick (DataLoggerX4_066.spin)      │
'' └──────────────────────────────────────────────────────────────────────────┘
''
'' Demonstration program using the object DataLoggerX4.spin.
'' Resolution is 1 clock cycle (12.5nS = 80MHz for 5MHz xtal + PLL16X)
'' by interleaving 4 cogs sampling at 4 clock cycles each.
'' Option to sequentially sample at 4 clock cycles (50nS). 
'' Option to sample at 150nS to 25.6uS in 50nS increments.
'' 
'' At the end of the sampling, the dataset will be sent to the serial port
'' via the object FullDuplexSerial.spin        
''
'' Uses pins 0, 1 & 2 (serial rx, serial tx, output trigger pin)
'' Pin 2 triggers on an incoming character on pin 0. After it goes high to
'' trigger the DataLogger, it delays and then pulses @ 8 clock cycles (100nS)
'' This toggling has the added effect of seeing the dataset varying.

'' RR20080505   commence code
'' RR20080518   split into Object and Calling files
'' RR20080519   call 4 objects !!!
'' RR20080519   v0.060 change trigger method in Data Logger Object v0.060
''              stores 1880 samples plus the last sample stores the current CNT register (see :debug instructions)
''              4 objects will store 1880 clocks @ 12.5nS
'' RR20080519   v0.062 Add compile option to sequentially sample
''              4 objects will store 1880 x (4 clocks at 50nS)
''              fix bug (length of bufferb, bufferc, bufferd should be 512)
'' RR20080520   v0.063 Add option "cyclesx4" for slower samples (0=12.5nS, 1=50nS, 2=invalid, 3=150nS, 4=200nS, 5=250nS...)
''              change buffer parameters order        
''              fix bug sequential samples were starting 471 clocks later, should be 470*4
'' RR20080522   Add "showclocks" constant to output serially in a form capable of being captured into a *.spin file so
''              it displays as a timing diagram in the Propeller IDE. Capture data after the "?" is displayed.
'' RR20080523   v0.068 log the timing of assembler instructions
''              v0.069 don't start serial until the DataLogging has been done (allows me to start another cog for timing
''              purposes)

CON

  _CLKMODE = XTAL1 + PLL16X     'Set to ext low-speed xtal, 16x PLL
  _XINFREQ = 5_000_000          'Xtal 5MHz

  trigmask  = %00000000_00000000_00000000_00000100      'mask (pin 2 only)
  trigstate = %00000000_00000000_00000000_00000100      'state (pin 2 =1)                     
  trigdelay = 5                                         'must be a minimum of 5 cycles                        
  cyclesx4  = 0                 '(0=12.5nS, 1=50nS, 2=invalid, 3=150nS, 4=200nS, 5=250nS...)
  samples   = 470               'number of data samples in object (keep in sync!!!)

  showclocks = true             'Will display data in Unicode for saving as *.spin file.

                      '\\       'These are the offsets into the bufferx[512] defined below
                      '||       'THE FOLLOWING MUST BE KEPT TOGETHER & IN THIS ORDER               
  bmask   = 0         '||       'trigger pin mask (trigger immediately if =0)                                               
  bstate  = 1         '||       'trigger pin state                                                                          
  bdelay  = 2         '||       'trigger delay (clock cycles, minimum 5)
  bcycles = 3         '||       'no. of cycles*4 between samples (0=12.5nS, 1=50nS, 2=invalid, 3=150nS, 4=200nS, 250nS...)  
  bsize   = 4         '||       'dataset buffer size (set by cog when done)                                                 
  bdata   = 5         '||       'dataset buffer (max 507, but not all can be used by the cog - see "samples" above)                                                 
                      '//       'Note: This is not the same as dscope.spin !!!                                              


VAR

  long  interleave              'Interleave = true      1880 samples @ 12.5nS (1 clock cycle) 
                                'Sequentially = false   1880 samples @ cyclesx4 * 50nS ( multiples of 4 clock cycles)
                                '                               (cyclesx4 = invalid so 100nS samples is not possible)

  long  buffer1[512]            'buffer for first cog   (see parameter order in CON above)
  long  buffer2[512]            'buffer for second cog
  long  buffer3[512]            'buffer for third cog
  long  buffer4[512]            'buffer for fourth cog

  long  coga
  long  cogb
  long  cogc
  long  cogd

  long  sample1                 'first dataset sample - for use if debugging "cnt" instead of "ina" in object
  long  prevdata                'last sample displayed

  
OBJ
  FDX           : "FullDuplexSerial"
  DL1           : "DataLoggerX4_066"
  DL2           : "DataLoggerX4_066"
  DL3           : "DataLoggerX4_066"
  DL4           : "DataLoggerX4_066"
  
PUB Main
{
  FDX.start(0,1,%0000,19200)                            '(rxpin, txpin, mode, baudrate)
  waitus(1_000_000)                                     'wait ?uS
  FDX.tx($0D)
  FDX.tx($0A)

  if cyclesx4 == 0
    interleave := true
    FDX.tx("I")
  else
    interleave := false
    FDX.tx("S")
    FDX.dec(cyclesx4)
  if cyclesx4 == 2                                      '2 is invalid!
    FDX.tx("e")
    FDX.tx("r")
    FDX.tx("r")
    FDX.tx("o")
    FDX.tx("r")
    repeat                                              'loop here!
  FDX.tx("?")
}

  waitus(1_000_000)                                     'wait ?uS
  if cyclesx4 == 0
    interleave := true
  else
    interleave := false
    
'  cognew(@WaitforPin0,0)                                'wait for Pin0 = 0, then make Pin2 = 1, delay, pulse @ 100nS

  StartDataLogger                                       'start DataLogger

'The following is used to assess the timing of assembler instructions
  cognew(@timing,0)
  cognew(@pulsing,0)
  waitus(1000000)                                       'wait 1 sec
  dira[2]~~                                             'make Pin 2 output
  dira[4]~~                                             'make Pin 4 output
  waitpne(1,1,0)                                        'wait for Pin0 = 0
  outa[2]~~                                             'make Pin 2 = 1
  outa[4]~~                                             'make Pin4 = 1
  outa[4]~                                              'make Pin4 = 0

  repeat until buffer1[bsize]                           'wait until buffers are full (we have a dataset)
  repeat until buffer2[bsize]                               
  repeat until buffer3[bsize]                               
  repeat until buffer4[bsize]                               

'start the serial driver
  FDX.start(0,1,%0000,19200)                            '(rxpin, txpin, mode, baudrate)
  waitus(1_000_000)                                     'wait ?uS

  if not showclocks
    if interleave
      DisplayInterleave                                 'output data to serial port
    else
      DisplaySequential                                 'output data to serial port
  else
    if interleave
      DisplayIntClocks                                  'output data to serial port
    else
      DisplaySeqClocks                                  'output data to serial port
     
  repeat                                                'loop here indefinately  ????

PUB StartDataLogger : okay

  longfill( @buffer1, 0, 512)                           'clear the buffer                  
  buffer1[bmask]   := trigmask                          'set trigger mask
  buffer1[bstate]  := trigstate & trigmask              'set trigger state
  buffer1[bcycles] := cyclesx4                          'set sample rate
               
  longfill( @buffer2, 0, 512)                                    
  buffer2[bmask]   := trigmask                          
  buffer2[bstate]  := trigstate & trigmask              
  buffer2[bcycles] := cyclesx4                          
                                                        
  longfill( @buffer3, 0, 512)                                    
  buffer3[bmask]   := trigmask                          
  buffer3[bstate]  := trigstate & trigmask              
  buffer3[bcycles] := cyclesx4                          
                                                        
  longfill( @buffer4, 0, 512)                                    
  buffer4[bmask]   := trigmask                          
  buffer4[bstate]  := trigstate & trigmask              
  buffer4[bcycles] := cyclesx4                          

  if interleave                                          
    buffer1[bdelay] := trigdelay                             'clock delay after triggering (minimum 5)                                         
    buffer2[bdelay] := trigdelay + 1
    buffer3[bdelay] := trigdelay + 2                                      
    buffer4[bdelay] := trigdelay + 3                                      
  else
    buffer1[bdelay] := trigdelay + (0 * samples * cyclesx4 * 4)  'clock delay after triggering (minimum 5)                                     
    buffer2[bdelay] := trigdelay + (1 * samples * cyclesx4 * 4)                 
    buffer3[bdelay] := trigdelay + (2 * samples * cyclesx4 * 4)                 
    buffer4[bdelay] := trigdelay + (3 * samples * cyclesx4 * 4)                 

  coga  := DL1.start(@buffer1)                          'start DataLog cog
  cogb  := DL2.start(@buffer2)                          
  cogc  := DL3.start(@buffer3)                          
  cogd  := DL4.start(@buffer4)                          

                                                         

Pub StopDataLogger

  DL1.stop                                              'stops the Cog
  DL2.stop                                              'stops the Cog
  DL2.stop                                              'stops the Cog
  DL4.stop                                              'stops the Cog


PUB DisplayInterleave | i
''Display the dataset (interleaved cog data)

  DisplayCogs

  sample1 := buffer1[bdata]                             'save the first sample
  repeat i from 0 to buffer1[bsize] - 1                 'send whole buffer
    DisplayLine((i*4)+0,buffer1[bdata + i])
    DisplayLine((i*4)+1,buffer2[bdata + i])
    DisplayLine((i*4)+2,buffer3[bdata + i])
    DisplayLine((i*4)+3,buffer4[bdata + i])

  FDX.tx($0D)
  FDX.tx($0A)    


PUB DisplaySequential | i, clocks, skip
''Display the dataset (sequential cog data)

  DisplayCogs

  clocks  := cyclesx4 * 4
  sample1 := buffer1[bdata]                             'save the first sample
  repeat i from 0 to (buffer1[bsize] - 1)               'send whole buffer
    DisplayLine(i * clocks, buffer1[bdata + i])
  skip  := 1 * samples * clocks
  repeat i from 0 to (buffer2[bsize] - 1)                       
    DisplayLine((i * clocks) + skip, buffer2[bdata + i])
  skip  := 2 * samples * clocks
  repeat i from 0 to (buffer3[bsize] - 1)                       
    DisplayLine((i * clocks) + skip, buffer3[bdata + i])
  skip  := 3 * samples * clocks
  repeat i from 0 to (buffer4[bsize] - 1)                       
    DisplayLine((i * clocks) + skip, buffer4[bdata + i])

  FDX.tx($0D)
  FDX.tx($0A)    

PUB DisplayIntClocks | i, j, p
''Display the dataset (interleaved cog data)

  DisplayClocksBOF
  sample1 := buffer1[bdata]                             'save the first sample
  DisplayClocksHDR(1,buffer1[bsize]*4)
  repeat j from 0 to 31                                 'repeat for each pin
    p := 1 << j
    DisplayClocksBOL(j)
    repeat i from 0 to buffer1[bsize] - 1                 'send whole buffer
      DisplayClocks((i*4)+0,buffer1[bdata + i],p)
      DisplayClocks((i*4)+1,buffer2[bdata + i],p)
      DisplayClocks((i*4)+2,buffer3[bdata + i],p)
      DisplayClocks((i*4)+3,buffer4[bdata + i],p)
    DisplayClocksEOL
  DisplayClocksEOF

PUB DisplaySeqClocks | i, j, clocks, skip ,p
''Display the dataset (sequential cog data)

  DisplayClocksBOF
  clocks  := cyclesx4 * 4
  sample1 := buffer1[bdata]                             'save the first sample
  DisplayClocksHDR(1,buffer1[bsize]*4)
  repeat j from 0 to 31                                 'repeat for each pin
    p := 1 << j
    skip := 0
    DisplayClocksBOL(j)
    repeat i from 0 to (buffer1[bsize] - 1)               'send whole buffer
      DisplayClocks(i * clocks, buffer1[bdata + i],p)
    skip  := 1 * samples * clocks
    repeat i from 0 to (buffer2[bsize] - 1)                       
      DisplayClocks((i * clocks) + skip, buffer2[bdata + i],p)
    skip  := 2 * samples * clocks
    repeat i from 0 to (buffer3[bsize] - 1)                       
      DisplayClocks((i * clocks) + skip, buffer3[bdata + i],p)
    skip  := 3 * samples * clocks
    repeat i from 0 to (buffer4[bsize] - 1)                       
      DisplayClocks((i * clocks) + skip, buffer4[bdata + i],p)
    DisplayClocksEOL
  DisplayClocksEOF

PUB DisplayClocksBOF
  FDX.tx($FF)                 '\ UTF-16 header
  FDX.tx($FE)                 '/
  FDX.tx($0D)                 '\ <cr>
  FDX.tx($00)                 '|
  FDX.tx($0A)                 '| <lf>
  FDX.tx($00)                 '/

PUB DisplayClocksHDR (inc,siz) | i, j, k, n, x, y, z
  FDX.tx(" ")                 '\ 
  FDX.tx($00)                 '|
  FDX.tx(" ")                 '| 
  FDX.tx($00)                 '|
  FDX.tx(" ")                 '| 
  FDX.tx($00)                 '/
  repeat i from 0 to (siz-1)/10
    j := 0
    'display significant digits
    x := i*10
    y := 1_000_000_000
    repeat 10
      if x => y
        FDX.tx(x/y + "0")
        FDX.tx($00)
        x := x // y
        j := j+1
      elseif j or y == 1
        FDX.tx("0")
        FDX.tx($00)
        j := j+1
      y := y/10
    'now fill remaining 10 characters with spaces
    repeat j from j to 9
      FDX.tx(" ")
      FDX.tx($00)
  DisplayClocksEOL
'-----
  FDX.tx(" ")                 '\ 
  FDX.tx($00)                 '|
  FDX.tx(" ")                 '| 
  FDX.tx($00)                 '|
  FDX.tx(" ")                 '| 
  FDX.tx($00)                 '/
  repeat i from 0 to (siz-1)/10
    FDX.tx($A2)                 ' 
    FDX.tx($F0)
    repeat j from 1 to 9
'      n := lookupz(j : "0".."9")
'      FDX.tx(n)
      FDX.tx(j + "0")
      FDX.tx($00)
DisplayClocksEOL
  
PUB DisplayClocksBOL (j) | n
  n := j
  case n
    0..9   : FDX.tx("0")
    10..19 : FDX.tx("1")
             n := n-10
    20..29 : FDX.tx("2")
             n := n-20
    30..31 : FDX.tx("3")
             n := n-30
  FDX.tx($00)                 '|
  n := lookupz(n : "0".."9")
  FDX.tx(n)                   '| 
  FDX.tx($00)                 '|
  FDX.tx(" ")                 '| 
  FDX.tx($00)                 '/
  
PUB DisplayClocks (i,data,p) | d  
  d := data & p                 'extract the bit being displayed
  if i == 0
    if d == 0
      FDX.tx($89)                 '\   
      FDX.tx($F0)                 '/
    else
      FDX.tx($8A)                 '\   
      FDX.tx($F0)                 '/
  else
    if d == prevdata
      if d == 0
        FDX.tx($81)                 '\   
        FDX.tx($F0)                 '/
      else
        FDX.tx($86)                 '\   
        FDX.tx($F0)                 '/
    else
      if d == 0
        FDX.tx($85)                 '\   
        FDX.tx($F0)                 '/
      else
        FDX.tx($82)                 '\   
        FDX.tx($F0)                 '/
  prevdata := d  

{
 FDX.tx($AF)                 '\   
  FDX.tx($F0)                 '/
  FDX.tx($B4)                 '\   
  FDX.tx($F0)                 '/
}

PUB DisplayClocksEOL
  FDX.tx($0D)                 '\ <cr>
  FDX.tx($00)                 '|
  FDX.tx($0A)                 '| <lf>
  FDX.tx($00)                 '/

PUB DisplayClocksEOF
  FDX.tx($0D)                 '\ <cr>
  FDX.tx($00)                 '|
  FDX.tx($0A)                 '| <lf>
  FDX.tx($00)                 '/
  FDX.tx($00)                 '  EOF


PUB DisplayLine (i,data)
  FDX.tx($0D)
  FDX.tx($0A)
  if i < 1000
    FDX.tx("0")
  if i < 100
    FDX.tx("0")
  if i < 10
    FDX.tx("0")
  FDX.dec(i)
  FDX.tx(" ")
  FDX.tx("$")
  FDX.hex(data,8)
  FDX.tx(" ")
  FDX.tx("$")
  FDX.bin(data,32)
' FDX.tx(" ")                                      '<--- for debugging
' FDX.dec(data-sample1)                            '<--- for debugging when sampling "cnt" used instead of "ina" in object
  waitus(500)                                           'wait ?uS  (delay because Hyperterminal loses chars???)
   

PUB DisplayCogs

  FDX.tx(" ")
  FDX.tx("C")
  FDX.tx("o")
  FDX.tx("g")
  FDX.tx("s")
  FDX.tx(" ")
  FDX.dec(coga)
  FDX.tx(",")
  FDX.dec(cogb)
  FDX.tx(",")
  FDX.dec(cogc)
  FDX.tx(",")
  FDX.dec(cogd)
  FDX.tx(" ")


PUB WaitUS(DelayUS)
  waitcnt(clkfreq / 1_000_000 * DelayUS + cnt)          'wait ?uS (min 10uS)


DAT
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ Various Pin routines                                                     │
'' └──────────────────────────────────────────────────────────────────────────┘

              org
WaitforPin0
              mov       dira, :pinout                   'make pin 2 output
              waitpne   :pinin,:pinin                   'wait for pin 0 =0 (start of serial character)                                          
              or        outa, :pinout                   'make pin 2 =1
              nop                                       'delay 20 clocks 
              nop
              nop
              nop

              nop                                       'delay another 20 clocks
              nop
              nop
              nop
              nop

              nop                                       'delay another 20 clocks
              nop
              nop
              nop
              nop

:wloop        xor       outa, :pinout                   'toggle pin 2 (100nS)
              jmp       #:wloop                         'loop indefinately
:pinin        LONG      %00000000_00000000_00000000_00000001 'pin 0 
:pinout       LONG      %00000000_00000000_00000000_00000100 'pin 2 
'------------------------------------------------------------------------------

'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ COG: Instruction Timing routine                                          │
'' └──────────────────────────────────────────────────────────────────────────┘
              org
Timing        mov       dira, :pinout                   'make pin 7 output
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ Wait for trigger (or skip if tmask=0)                                    │
'' └──────────────────────────────────────────────────────────────────────────┘
              waitpeq   :tstate,:tmask                  'wait here for trigger condition (modified if tmask=0)
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ Wait for tdelay clock cycles (or skip if tdelay=0)                       │
'' └──────────────────────────────────────────────────────────────────────────┘
              add       :tdelay,cnt                     'wait for tdelay clock cycles (modified if tdelay=0)
              waitcnt   :tdelay,0                     
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ We are now synchronised with the DataLogger Cogs                         │
'' └──────────────────────────────────────────────────────────────────────────┘
              or        outa, :pinout                   'make pin 7 =1  (to show we are synchronised!)
              waitpeq   :pinout,:pinout                 'wait for pin 7 =1 (we just set it this way!)                                          
              xor       outa, :pinout                   'toggle pin 7 =0

              waitpeq   :pin10,:pin10                   'wait for pin 10 =1 (wait here for pin)                                                
              xor       outa, :pinout                   'toggle pin 7 =1

              nop
:loop         xor       outa, :pinout                   'toggle pin 7
              jmp       #:loop

':id          cogid     :id
'             cogstop   :id

:pinout       LONG      %00000000_00000000_00000000_10000000 'pin 7
:pin10        LONG      %00000000_00000000_00000100_00000000 'pin 10
:tmask        LONG      %00000000_00000000_00000000_00000100 'pin 2 
:tstate       LONG      %00000000_00000000_00000000_00000100 'pin 2 
:tdelay       LONG      5
'------------------------------------------------------------------------------

'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ COG: Pulse output pins to give timing reference                          │
'' └──────────────────────────────────────────────────────────────────────────┘
              org
Pulsing       mov       dira, :pinout                   'make pins 8..16 output
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ Wait for trigger (or skip if tmask=0)                                    │
'' └──────────────────────────────────────────────────────────────────────────┘
              waitpeq   :tstate,:tmask                  'wait here for trigger condition (modified if tmask=0)
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ Wait for tdelay clock cycles (or skip if tdelay=0)                       │
'' └──────────────────────────────────────────────────────────────────────────┘
              add       :tdelay,cnt                     'wait for tdelay clock cycles (modified if tdelay=0)
              waitcnt   :tdelay,0                     
'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ We are now synchronised with the DataLogger Cogs                         │
'' └──────────────────────────────────────────────────────────────────────────┘
:loop         mov       outa, :counter                  'make pin8 =1
              add       :counter, #$100                 'inc counter (counts from pin8...)
              jmp       #:loop

':id          cogid     :id
'             cogstop   :id

:pinout       LONG      %00000000_00000000_11111111_00000000 'pins 8..15
:counter      long      %00000000_00000000_00000001_00000000 'counter                    
:tmask        LONG      %00000000_00000000_00000000_00000100 'pin 2 
:tstate       LONG      %00000000_00000000_00000000_00000100 'pin 2 
:tdelay       LONG      5
'------------------------------------------------------------------------------


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