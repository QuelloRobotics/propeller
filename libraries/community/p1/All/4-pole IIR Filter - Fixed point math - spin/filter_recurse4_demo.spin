{{ recurse4_demo.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ IIR recurse4 filter demo v0.6       │ BR             │ (C)2009             │  4 Dec 2009   │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ Demo of 4-element IIR "recurse4" integer math filter                                       │
│       •various filter synthesis setups shown, uncomment as desired                         │
│                                                                                            │
│ pst output setup to use PLX-DAQ (enables easy plot of raw data vs filtered output). To     │
│ download PLX-DAQ, go to Parallax basic stamp software downloads page.  PLX-DAQ rocks.      │
│ Demo calculates filter frequency response via direct simulation with the help of the       │
│ prop's built-in math tables and a handy sin function courtesy of Ariba.  It also simulates │
│ filter impulse response and step response.                                                 │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}


CON
  _clkmode        = xtal1 + pll16x    ' System clock → 80 MHz
  _xinfreq        = 5_000_000

  
OBJ
   
    pst  : "Parallax Serial Terminal"
'   sn   : "Simple_Numbers"
   filter: "filter_recurse4"    

  
PUB Init

  waitcnt(clkfreq * 5 + cnt)
  pst.StartRxTx(31, 30, 0, 57600)
  pst.Str(String("MSG,Initializing...",13))
  pst.Str(String("LABEL,x_meas,x_filt,ticks,bwidth",13))
  pst.Str(String("CLEARDATA",13))
  main


Pub Main| iter, mark, value, xmeas, xfilt, ticks, random
'=========================================
'Filter setup methods--uncomment one of the following
'=========================================
filter.synth_low_pass(200,255)                   'synthesize low pass filter for use with recurse4
'filter.synth_high_pass(15,255)                  'synthesize high pass filter for use with recurse4
'filter.synth_band_stop(25,100,25,10)            'synthesize band stop filter for use with recurse4
'filter.synth_band_pass(25,100,10,10)            'synthesize band pass filter for use with recurse4
'filter.synth_fslp(15,50)                        'synthesize four stage low pass filter for use with recurse4

'======================================================
'Filter response to sinusoidal inputs (poor man's Bode)
'======================================================
mark := random := cnt
repeat  iter from 1 to 40 step 2                 'simulate 20 frequencies, highest frequency is nearly Nyquist freq
  repeat value from 0 to 359 step 4              'take 90 samples per frequency
    mark += clkfreq/50                           'output data (slow down to watch it plot "real time" in excel)
    pst.Str(String("DATA, "))                    'data header for PLX-DAQ
    xmeas := filter.sin(value*iter,200)          'thanks Ariba
'   xmeas += iter * random? >> 28                'add some noise to the measurements

    ticks := cnt
    xfilt := filter.recurse4(xmeas)              'be sure to call one of the synth_XXXX functions before using
    ticks := cnt - ticks

    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(", "))
    pst.Dec(ticks)
    pst.Str(String(", "))
    pst.Dec(clkfreq/ticks)
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
      xmeas := 0                                      'let the filter chill for a moment....
    elseif iter < 100
      xmeas := impulse_fun(iter, 51, 200) 'input impulse function
    else
      xmeas := step_fun(iter,101,200)                 'input step function

    xfilt := filter.recurse4(xmeas)              

    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(", "))
    pst.Dec(ticks)
    pst.Str(String(", "))
    pst.Dec(clkfreq/ticks)
    pst.Str(String(13))
    waitcnt(mark)                                


pub impulse_fun(i,trigger,mag)
''Returns impulse function. i = current sample index
''                          trigger = sample index on which impulse is triggered
''                          mag = magnitude of impulse
    if i==trigger
      return mag
    else
      return 0


pub step_fun(i,trigger,mag)
''Returns step function. i = current sample index
''                       trigger = sample index on which step is triggered
''                       mag = magnitude of impulse
    if i < trigger
      return 0
    else
      return mag

      