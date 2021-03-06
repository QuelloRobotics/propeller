{{ tsl230_pi.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ TSL230_pi Light to Freq Driver      │ BR             │ (C)2008             │  31 Dec 2008  │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ TAOS TSL230 light to frequency sensor driver with manual and auto scaling capabilities.    │
│ Uses the PULSE INTEGRATION method with constant (user specified) sampling rate.  This      │
│ driver is suitable for measuring light intensity at a sample rate of 1Hz to ~50KHz.        │
│ Also includes a moving average filter in the assembly routine.                             │
│                                                                                            │
│ PULSE INTEGRATION SAMPLING METHOD:                                                         │
│ •Counts total number of pulse rising edges output from TSL230 over a fixed time interval   │
│                                                                                            │
│                      |──────────── Tsamp=1/samplefreq ────────────────|                  │
│    TSL230 out ... ...          │
│    PHSA           +1        +1        +1        +1        +1        +1                     │
│    FRQA           0          1         2         3         4         5     ──▶  RawCnts=5  │
│                                                                                            │
│ NOTES:                                                                                     │
│ •Derived from original object located at:  http://obex.parallax.com/objects/236/           │
│ •This object maintains backward compatibility with Paul's original.                        │
│ •TSL230 manufacturer datasheet states that max frequency w/o saturation is 1.1 MHz.        │
│  However, for the part used to test this driver, the max frequency output is 1.6 MHz.      │
│  This presumably means that the 1.1-1.6 MHz region is a no-man's land of nonlinearity...   │
│  this driver assumes the that 1.1 MHz is the usable upper limit.                           │
│ •Autoscaling constants in this object were selected to keep output as near to 1.1 MHz as   │
│  possible without going over and with a sufficient hysteresis band to avoid dithering      │
│  of scale when autoscale enabled.                                                          │
│ •The getSample method returns a scaled frequency in accordance with the current setting of │
│  the scale parameter(output range is between 0 and ~160,000,000).                          │
│ •getRawSample returns the raw frequency w/o scale (output range between 0 and ~1,600,000)  │
│ •TSL230 pins 7 & 8 (frequency dividers) always assumed to be low since counters easily have│
│  enough bandwidth to keep up with a 1.6 MHz (saturated) signal.  If running prop at clock  │
│  frequencies less than ~5 MHz, may need to adjust these settings for proper operation.     │
│ •A moving average filter has been added to the assembly driver.  This reduces noise        │
│  at the expense of increased response time. A 16-pt average seems to be fairly effective   │
│  at eliminating the 60 Hz flicker caused by incancescent or flourescent lighting.          │
│  The filter can easily be bypassed by commenting out the ASM calls to finit and filt.      │
│ •The measurement update rate can be selected at run time via the setSampleFreq method.     │
│  Note that there is an inherent tradeoff between update rate and measurement precision.    │
│  Very high update rates shorten the frequency integration time  able to detect high       │
│  frequency changes in light intensity at the cost of reduced measurement precision.        │
│  The relationship between intergration time (update rate) and precision should be          │
│  (assuming an 80MHz clock):                                                                │
│                                                                                            │
│  IN DECIMAL UNITS:                                                                         │
│  Updates/s     MaxRawCnts     SigDigits    MIN roundoff error @ sat¹                       │
│  1             ~1.1M          6            1 / 1_100_000  0.0001%                         │
│  10            110_000        5            1 / 110_000    0.001%                          │
│  100           11_000         4            1 / 11_000     0.01%                           │
│  1000          1_100          3            1 / 1_100      0.1%                            │
│  10_000        110            2            1 / 110        1%                              │
│  100_000       11             1            1 / 11         11%                             │
│                                                                                            │
│  IN BINARY UNITS:                                                                          │
│  Updates/s     MaxRawCnts     SigBits²                                                     │
│  1             1_048_576      20                                                           │
│  2             524_288        19                                                           │
│  4             262_144        18                                                           │
│  8             131_072        17                                                           │
│  16            65_536         16                                                           │
│  32            32_768         15                                                           │
│  64            16_384         14                                                           │
│  128           8_192          13                                                           │
│  256           4_096          12                                                           │
│  512           2_048          11                                                           │
│  1_024         1_024          10                                                           │
│  2_048         512            9                                                            │
│  4_096         256            8                                                            │
│  8_192         128            7                                                            │
│  16_384        64             6                                                            │
│  32_768        32             5                                                            │
│  65_536        16             4                                                            │
│  131_072       8              3                                                            │
│  262_144       4              2                                                            │
│  524_288       2              1                                                            │
│                                                                                            │
│  ¹This is the MINIMUM roundoff error when device is saturated. Lower frequencies/light     │
│   intensities will yield larger errors (~10X worse or more).                               │
│  ²Note that this ideal relationship ignores noise in the TSL230, power supply, etc.        │
│   Actual precision is less than this due to these additional sources of noise.             │
│                                                                                            │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                               
 SCHEMATIC:
─────────────────────────────────────────────────────────────────────────────────────────────  
                    ┌──────────┐
    ctrlpinbase ──│1 o      8│──┳──┐ GND
                    │          │   │  
  ctrlpinbase+1 ──│2        7│──┘ 
                    │    []    │   
                ┌──│3        6│──── inpin
                │   │          │    
            GND ┣──│4        5│──┘ 3.3V 
                   └──────────┘          
─────────────────────────────────────────────────────────────────────────────────────────────  
V1.0: •Change getSample method to select scaling based on raw frequency, not scaled freq
      •Update hysteresis range for autoscaling logic to use more of TSL230's dynamic range
      •Add methods to return raw frequency count, current scale setting, and freq pointer
      •Update asm routine to enable run time selection of measurement update rate
      •Added moving average filter to ASM routine
}}
'FIXME: figure a good test to quantify the SNR for this device.
'FIXME: do something with freqsat?
'FIXME: confirm that the tables above are correct


CON 
  ctrmode = $28000000                   'POS edge detector
  freqMax = 1_110_000                   'upper bound on freq  decrease sensitivity
  freqMin = 100_000                     'lower bound on freq  increase sensitivity
' freqSat = 1_100_000                   'Saturation freq; light-freq relationship assumed nonlinear past this pt
  bufExp  = 4                           'moving average filter buffer size (2^bufExp)
  bufSize = 1 << bufExp                 

        
VAR
  long freq                             'outputs
  long cntadd, scale, cbase, sps, auto  'inputs
  byte cog


PUB Start(inpin, ctrlpinbase, samplefreq, autoscale): okay
''Start method to initialize TSL230 driver, arguments:
''inpin       - Prop pin number to which output of tsl230 is connected
''ctrlpinbase - Prop pin number connected to S0
''              S1 connected to ctrlpinbase + 1
''samplefreq  - TSL230 measurement refresh rate (updates/second).
''              Higher values reduce precision (significant digits), increase responsiveness
''autoscale   - Boolean, TRUE  autoscaling turned on
                                          
  scale := %11                          'set inital scale to maximum
  cbase := ctrlpinbase                  'copy parameters
  sps := samplefreq                       
  auto := autoscale                       

  dira := %11 << cbase                  'set control pins to output
  outa := %11 << cbase                  'set scale
  
  ctra_ := ctrmode + inpin              'compute counter mode
  cntadd := clkfreq / samplefreq        'compute wait period
  _cntadd := cntadd                     'initialize _cntadd so its value gets loaded into cog when cognew called
  
  cog := okay := cognew(@entry, @freq)  'start driver


PUB Stop                                                               
'' Stop driver - frees a cog

    if cog
       cogstop(cog~ -  1)


PUB getSample:val|tmp
''Return scaled frequency measurement in Hz (proportional to light intensity)
''Max data rate ~9000 calls/sec for 1 cog @ clkfreq=80    (8112 ticks)
 
  val := freq * sps                     'compute raw frequency
  tmp := lookup(scale: 100, 10, 1)
  if auto                               'autoscale based on raw frequency
    if val > freqMax                    'if output exceeds threshold, decrease gain
      scale := --scale #> 1
    elseif val < freqMin                'if output less than threshold, increase gain
      scale := ++scale <# 3
    outa := scale << cbase
  val *= tmp                            'compute scaled frequency


pub getRawSample:val
''Return raw (unscaled) frequency measurement in Hz
''Max data rate ~50000 calls/sec for 1 cog @ clkfreq=80   (1392 ticks)

  return freq

  
pub getRawSamplePtr:val
''Return pointer to raw (unscaled) frequency measurement in Hz
''Use this if >~50000 calls/sec needed.  Scale in freq[7].

  return @freq

  
pub getScale:val
''Return current sensitivity setting, 1 = 1X, 2 = 10X, 3 = 100X

  return scale
  

PUB setScale(range):success
''Manually set sensitivity gain, 1 = 1X, 2 = 10X, 3 = 100X
''Works in autoscale and manual modes, though autoscale may  
''override scale if turned on

  scale := 1 #> range <# 3              'limit argument range to 1,2 or 3
  outa := scale << cbase                'set scale
  return 1


pub setSampleFreq(newFreq):success
''set ASM routine measurement update rate (i.e. the rate at which the
''ASM routine updates the freq variable in hub memory).

  if newFreq < 1                      'bound the sample rate between 1 Hz - 524KHz
    return 0                          '(1 sec to 1.9 us pulse integration period)
  if newFreq > 524_288
    return 0
  sps := newFreq
  cntadd := clkfreq / newFreq         'compute wait period
  return 1


DAT
'--------------------------
'Assembly driver for tsl230
'--------------------------
           org        
entry      mov     ctra,ctra_              'setup counter to count positive edges
           mov     frqa,#1                 'increment for each edge seen
           mov     ptr,par                 'load freq pointer into p
           add     ptr,#4                  'increment pointer by 1 long to point at cntadd
           call    #finit                  'initialize filter
           mov     cnt_,cnt                'initialize waitperiod
           add     cnt_,_cntadd
        
:loop      waitcnt cnt_,_cntadd            'wait for next sampling period                              '5+
           mov     new,phsa                'record new count                                           '4
           mov     temp,new                'make second copy                                           '4
           sub     new,old                 'compute cycles since last                                  '4        
           call    #filt                   'call filter function                                       '4 +48
           wrlong  new,par                 'write number of cycles since last period to hub memory     '7..22
           mov     old,temp                'record a new old count                                     '4
           rdlong  _cntadd,ptr             'update sample rate (copy cntadd into _cntadd)              '8 +4(window)                                                                                                               
           jmp     #:loop                  'play it again, Sam                                         '4

'--------------------------                                                                            'tot=96..111
'2^n-point moving average filter
'on entry: raw data is in new
'on exit: filtered data is in new
'--------------------------                                               
filt       mov     bptr,#buf               'move base buffer address into bptr                         '4
           add     bptr,indx               'add value in indx to bptr                                  '4
           movs    :mod1,bptr              'embed buffer pointer in sub instruction src field          '4
           movd    :mod2,bptr              'embed buffer pointer in mov instruction dest field         '4
           add     sum,new                 'add new measurement to accumulator                         '4
:mod1      sub     sum,0-0                 'subtract oldest measurement in buffer                      '4
:mod2      mov     0-0,new                 'save new measurement, overwriting old                      '4
           add     indx,#1                 'increment offset pointer by 1                              '4
           and     indx,#|<bufExp-1        'mask off all but lower n bits (ring buffer)                '4
           mov     new,sum                 'copy accumulator into new                                  '4
           sar     new,#bufExp             'divide by 2^n to get average                               '4
filt_ret   ret                                                                                         '4
'--------------------------                                                                            'tot=48
'filter initialization routine
'--------------------------                                                                            
finit      movd    :loop,#buf              'zero buffer registers
           mov     indx,#bufSize
:loop      mov     0-0,#0
           add     :loop,d_inc
           djnz    indx,#:loop             'indx initialized to 0 on exit
           mov     sum,#0                  'zero accumulator
finit_ret  ret

'--------------------------                                                                            
'initialized data
'--------------------------                                                                           
ctra_      long    0
_cntadd    long    0
d_inc      long    1 << 9
'uninitialized data--main routine vaiables
cnt_       res     1
new        res     1
old        res     1
temp       res     1
ptr        res     1                       'pointer to cntadd in hub memory
'uninitialized data--filter variables
bptr       res     1                       'pointer to current buffer location
indx       res     1                       'offset from buf[0]
sum        res     1                       'moving average accumulator
buf        res     bufSize                 'raw measurement buffer

fit 496

{{

┌────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this        │
│software and associated documentation files (the "Software"), to deal in the Software       │
│without restriction, including without limitation the rights to use, copy, modify, merge,   │
│publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons  │
│to whom the Software is furnished to do so, subject to the following conditions:            │
│                                                                                            │                         
│The above copyright notice and this permission notice shall be included in all copies or    │
│substantial portions of the Software.                                                       │
│                                                                                            │                         
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,         │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR    │
│PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE   │
│FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR        │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER      │                                │
│DEALINGS IN THE SOFTWARE.                                                                   │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}