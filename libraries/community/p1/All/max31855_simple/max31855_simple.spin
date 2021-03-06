{{ max31855_simple.spin
┌─────────────────────────────────────┬──────────────┬──────────┬────────────┐
│ MAX31855 Thermocouple drver v1.0    │ BR           │ (C)2014  │ 25Aug2014  │
├─────────────────────────────────────┴──────────────┴──────────┴────────────┤
│ A simple/lightweight driver object for interfacing with the MAX31855       │
│ temperature-compensated Thermocouple-to-Digital Converter.  Based on       │
│ Beau's SPI_spin code, with mods.  Returns temperature in deg Farenheight.  │
│                                                                            │
│ For a proper object, see Jon's post here:                                  │
│ http://forums.parallax.com/showthread.php/157134                           │
│                                                                            │
│ See end of file for terms of use.                                          │
└────────────────────────────────────────────────────────────────────────────┘

  REFERENCE CIRCUIT for connecting MAX31855:    Note: STRONGLY recommend
                                                use 10nF ceramic cap between 
                  MAX31855                      pins 2 & 3 for min noise 
              ┌─────────────┐                       
   ┌──────────┤1 GND   DNC  8 ├─── No connection               
        ┌────┤2 TC+   SO   7 ├─── dpin to propeller
       TC┻────┤3 TC-   /CS  6 ├─── cspin to propeller
 +3.3v ─────┬┤4 Vcc   SCK  5 ├─── cpin to propeller  
        0.1µF└───────────────┘      
             
}}
var
long raw, tcF, cjF

pub readTC(dpin, cpin, cspin)
''Reads MAX31855 chip and returns thermocouple reading in deg F
''returns -999 if MAX31855 error flag set
''Args:   dpin : SPI bus data pin (connect to prop)
''        cpin : SPI bus clock pin (connect to prop)
''        cspin: Chip select pin (connect to prop)
''Usage:  myTC_reading := readTC(dpin, cpin, cspin) 

  outa[cspin]~~
  dira[cspin]~~
  outa[cspin]~                     'chip select pin low
  raw := shiftin(dpin,cpin,32)     'shiftin 32 bits from max31855
  outa[cspin]~~
  cjF := ~~raw.word[0]             'cold junction reading + fault code
  tcF := ~~raw.word[1]             'thermocouple reading + fault code
  if (tcF & %1) == 1               'check if error flag set
    tcF := -999
  else
    tcF := tcF ~> 2                'shift fault bit & res bit out of register
    tcF := (tcF*9/5+128) ~> 2      'convert to °F & round to nearest deg
  cjF := cjF ~> 4                  'shift fault bit & res bit out of register
  cjF := (cjF*9/5+512) ~> 4        'get cold junction reading degF
  return tcF


pub getCJ
''get cold junction temperature (degF)

  return cjF
  

pub getraw
''get raw MAX31855 data (1 long)

  return raw
  

PRI shiftin(dpin, cpin, bits) | value

  dira[dpin]~                                           ' make dpin input
  outa[cpin]~                                           
  dira[cpin]~~                                          ' make cpin output
  value~                                                ' clear output 

'    MsbPost:
      repeat bits
        outa[cpin]~~                                             ' 
        value := (value << 1) | ina[dpin]
        outa[cpin]~                                             ' 
 
  return value


DAT
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                              TERMS OF USE: MIT License                     │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│ 
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         │
│DEALINGS IN THE SOFTWARE.                                                   │
└────────────────────────────────────────────────────────────────────────────┘
}}  