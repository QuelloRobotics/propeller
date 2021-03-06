{{ adc0831_slow.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ adc0831_slow              v1.0      │  BR            │ (C)2011             │  31May2011    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ Bare-bones ADC0831 8-bit ADC driver, written in spin.                                      │
│ Adapted from example by Jean-Marc Lugrin: http://obex.parallax.com/objects/248/            │
│ •ADC0831 driver code encapsulated into a self-contained object                             │
│ •Interface adjusted to follow propeller object conventions                                 │
│                                                                                            │
│ NOTES                                                                                      │
│ •Max sample rate is about 2.5KHz for a prop clock of 80 Mhz.                               │
│ •Vin is spec'd as +5v, but 3.3v seems to work OK for the part I have                       │
│ •If using +5v, be sure to put a 2.2K resistor on the d0 pin. In practice, it doesn't hurt  │
│  to use a 2.2K resistor on all pins connected to the propeller, just to be safe.           │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘

Reference circuit w/ potentiometer
============================================
Typical connections for a simple adc test circuit with 0 at ground and max scale at Vdd.
Example curcuit shown uses a potentiometer to make a variable voltage divider which
can be used to see how adc output changes w/ voltage.  See data sheet for further example
reference configurations (upper/lower bound scaling, differential voltage sampling, etc.).

              
                   ADC0831         Vcc(+5V spec'd, but +3.3V 
              ┌─────────────┐   │      seems to work OK)
   cs pin ────┤1 -CS   VCC  8 ├───┘                
         ┌────┤2 VIN+  CLK  7 ├─────────  clk pin 
         │  ┌─┤3 VIN-  DO   6 ├───────  d0 pin (2.2K resistor)
 sampled │  ╋─┤4 GND   Vref 5 ├───────┐  
 voltage │   └───────────────┘       │                                    
                                     │
      ┌───────────────────────────┻─ +3.3V (or 5V)    
      │  pot                              
 100Ω 
      

}}

var
  long CLK_PIN, CS_BAR_PIN, DO_PIN   'BAR-->active low pin (idle state is high)


pub init(cs,clk,d0) | data
''initilaizes driver, puts adc0831 in idle state (sets cs pin high)

  CLK_PIN := clk
  CS_BAR_PIN := cs
  DO_PIN := d0
  
  dira[DO_PIN]~                 ' set DO pin as input (is default at start, present for clarity)

  outa[CS_BAR_PIN]~~            ' set pin -CS high   
  dira[CS_BAR_PIN]~~            ' set -CS pin as output (chip disabled)
 
  outa[CLK_PIN]~                ' set clock pin low 
  dira[CLK_PIN]~~               ' set pin as output


pub stop
''release cs pin, clk pin
  outa[CS_BAR_PIN]:=dira[CS_BAR_PIN]:= 0
  outa[CLK_PIN]:=dira[CLK_PIN]:= 0
  

pub getSample | data
''activates adc0831 and returns an 8-bit sample value (0-255)

'Aquiring data requires to assert CS, pulse the clock once to start aquisition, then
'pulse the clock 8 times to read each bit after the descending edge of the clock.
'The chip is driven by the clock signal from the prop, so timing is not critical.
  
  data := 0                     ' This will accumulate the resulting value
  outa[CS_BAR_PIN]~             ' sets pin -CS low to activate the chip    

  outa[CLK_PIN]~~               ' pulse the clock, first high      
  outa[CLK_PIN]~                ' then low, this starts the conversion

  'Read 8 bits, MSB first.
  repeat 8              
    data <<= 1                  ' Multiply data by two
    outa[CLK_PIN]~~             ' pulse the clock, first high      
    outa[CLK_PIN]~              ' then low, this makes the next bit available on DO
    data += ina[DO_PIN]         ' Add it to the current value
           
  outa[CS_BAR_PIN]~~            ' done, deselect the chip
  return data   


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
             