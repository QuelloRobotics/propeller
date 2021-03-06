''Sensirion SHT-11 demo for the propeller
''based on the original by Cam Thompson
''Modified to use a simple serial terminal for demo
''Also modified to show how to put the SHT-11 on the prop's I2C bus.
''Also...updated corelation constants in float calcs to latest values (datasheet 4.3, May2010)

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  SHT_DATA      = 29                                    ' SHT-11 data pin
  SHT_CLOCK     = 28                                    ' SHT-11 clock pin

  CLS         = $0                                      ' clear screen
  CR          = $D                                      ' carriage return
  Deg         = $B0                                     ' degree symbol

var
  byte status
  
OBJ

  term          : "fullduplexserial"
  sht           : "Sensirion_full"
  fp            : "FloatString"
  f             : "Float32"
  
PUB main | count,tmp,rawTemp, rawHumidity, tempC, rh, dewC, TF_fp, RH_fp

  term.start(31, 30, 0, 115200)
  f.start                                               ' start floating point object
  sht.start(SHT_DATA, SHT_CLOCK)                        ' start sensirion object

  waitcnt(clkfreq*3+cnt)
  sht.config(33,sht#off,sht#yes,sht#hires)              'configure SHT-11
  term.tx(CLS)                                          

  ' read SHT-11 sensor and update (note: need to set baud to 57K if want output data to PLX-DAQ)
  term.Str(String("MSG,Sensirion SHT-11 Demo",13))
  term.Str(String("Temp_raw, RH_raw, TC_float, TF_float, RH_float, DewPtC_float, DewPtF_float, TF_fixpt, RH_fixpt, status_byte",13))
  term.Str(String("CLEARDATA",13))
  repeat
    term.Str(String("DATA,"))
    rawTemp := f.FFloat(sht.readTemperature) 
    term.str(fp.FloatToFormat(rawTemp, 5, 0))
    term.str(string(","))
    rawHumidity := f.FFloat(sht.readHumidity)
    term.str(fp.FloatToFormat(rawHumidity, 5, 0))

    term.str(string(","))
    tempC := celsius(rawTemp)  
    term.str(fp.FloatToFormat(tempC, 5, 1))
    term.str(string(","))
    term.str(fp.FloatToFormat(fahrenheit(tempC), 5, 1))
    term.str(string(","))
     
    rh := humidity(tempC, rawHumidity)
    term.str(fp.FloatToFormat(rh, 5, 1))
    term.str(string("%, "))
     
    dewC := dewpoint(tempC, rh)
    term.str(fp.FloatToFormat(dewC, 5, 1))
    term.str(string(",      "))
    term.str(fp.FloatToFormat(fahrenheit(dewC), 5, 1))
    term.str(string(",    "))

    TF_fp:=sht.getTemperatureF
    term.dec(TF_fp)
    term.str(string(", "))
    RH_fp:=sht.getHumidity
    term.dec(RH_fp)
    term.str(string(",   "))
    status:=sht.readStatus
    term.bin(status,8)
    term.str(string(",  "))
'   status:=sht.checkLowBat
'   term.bin(status,8)
    term.str(string(13))

    if count//4                                       'toggle every 4 cycles
      sht.config(33,sht#off,sht#no,sht#lores)         '3 fast, loRes measurements
    else
      sht.config(33,sht#off,sht#yes,sht#hires)        '1 slow, hiRes measurement
    count++
'   waitcnt (clkfreq*2+cnt)                           'display every 2 seconds
    
     
PUB celsius(t)
  ' from SHT1x/SHT7x datasheet using value for 3.5V supply
  ' celsius = -39.7 + (0.01 * t)
  return f.FAdd(-39.7, f.FMul(0.01, t))  

PUB fahrenheit(t)
  ' fahrenheit = (celsius * 1.8) + 32
  return f.FAdd(f.FMul(t, 1.8), 32.0)
  
PUB humidity(t, rh) | rhLinear
  ' rhLinear = -2.0468 + (0.0367 * rh) + (-1.5955E-6 * rh * rh)
  ' simplifies to: rhLinear = ((-1.5955E-6 * rh) + 0.0367) * rh -2.0468
  rhLinear := f.FAdd(f.FMul(f.FAdd(0.0367, f.FMul(-1.5955E-6, rh)), rh), -2.0468)
  ' rhTrue = (t - 25.0) * (0.01 + 0.00008 * rawRH) + rhLinear
  return f.FAdd(f.FMul(f.FSub(t, 25.0), f.FAdd(0.01, f.FMul(0.00008, rh))), rhLinear)

PUB dewpoint(t, rh) | h
  ' h = (log10(rh) - 2.0) / 0.4343 + (17.62 * t) / (243.12 + t)
  h := f.FAdd(f.FDiv(f.FSub(f.log10(rh), 2.0), 0.4343), f.FDiv(f.FMul(17.62, t), f.FAdd(243.12, t)))
  ' dewpoint = 243.12 * h / (17.62 - h)
  return f.FDiv(f.FMul(243.12, h), f.FSub(17.62, h))
  
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