{{
  TMP102 DEMO CODE
  Demonstrates the major operations of the TMP102 digital thermostat. Uses the parallax
  serial terminal object to display the temperature readings and registers to a serial
  console.  

  Kyle Crane  2011   
}}


CON
        _clkmode = xtal1 + pll16x     'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

   
OBJ
  pst       : "Parallax Serial Terminal"   'Debug terminal for communication
  therm     : "TMP102"                 
  
PUB main | ack
  therm.init(72, 2, 3, false)     'Setup the sensor on address 72, on pins 2 and 3, and do not
                                  'automaticaly sample temp when reading the object's temp

  pst.start(115_200)
  waitcnt((clkfreq*4)+cnt)

  pst.Chars(pst#CS,1) 
  pst.str(String("Looking for device at address 0x"))
  pst.hex(therm.GetDeviceAddress, 2)
  pst.str(String("....."))
  if therm.DevicePresent
    pst.str(String("found!"))
  pst.chars(pst#NL, 1)  

  pst.str(String("Start Config: "))
  pst.chars(pst#TB, 1)
  pst.bin(therm.GetConfigRegister, 16)
  pst.chars(pst#NL, 1)

  'pst.str(String("Writing: "))                   'Uncomment these blocks to test setting new modes
  'pst.chars(pst#TB, 1)
  'therm.SetConversionFreq(therm#CONV_RATE_8HZ)
  'pst.chars(pst#NL, 1) 
  
  'pst.str(String("Writing: "))                   
  'pst.chars(pst#TB, 1) 
  'therm.SetFaultQueue(therm#FAULT_REQ6)
  'pst.chars(pst#NL, 1)
  
  'pst.str(String("Writing: "))                   'Uncomment to test One-Shot
  'pst.chars(pst#TB, 1) 
  'therm.SetShutdownMode(false)                    
  'pst.chars(pst#NL, 1)  

  
  pst.str(String("Final Config: "))
  pst.chars(pst#TB, 1)
  pst.bin(therm.GetConfigRegister, 16)
  pst.chars(pst#NL, 1)
     
  pst.str(String("Alert Status: "))
  pst.chars(pst#TB, 1) 
  pst.bin(therm.GetAlertBit,1)
  pst.chars(pst#NL, 1)

  pst.dec(therm.SetAlertHighC(300))
  pst.chars(pst#NL, 1)

  pst.dec(therm.SetAlertLowC(280))
  pst.chars(pst#NL, 1)
  
  

  waitcnt((clkfreq*6)+cnt)
  
  repeat
    waitcnt((clkfreq)+cnt)
    'therm.DoOneShot                  'Uncomment to test One-Shot mode (and comment out therm.SampleTemp)
    therm.SampleTemp                  
    pst.positionX(0)
    pst.positionY(0)
    pst.Chars(pst#CS,1)
    pst.str(String("Raw Conv: "))
    pst.dec(therm.GetTempRaw)
    pst.chars(40, 1)
    pst.bin(therm.GetTempRaw,12)
    pst.chars(41, 1) 
    pst.chars(pst#NL, 1) 
    pst.chars(pst#NL, 1)  
    
    pst.dec(therm.GetTempC)
    pst.chars(pst#TB, 1)
    pst.dec(therm.GetTempF)
    pst.chars(pst#NL, 1)
    pst.chars(pst#NL, 1) 
    
    pst.dec(therm.GetTempWholeC)
    pst.str(String("."))
    pst.dec(therm.GetTempFracC)
    pst.chars(67,1)   
    pst.chars(pst#TB, 1)
    pst.dec(therm.GetTempWholeF)
    pst.str(String("."))
    pst.dec(therm.GetTempFracF)
    pst.chars(70,1)
    pst.chars(pst#NL, 1)
    pst.chars(pst#NL, 1)
 
    pst.str(String("Conf Register: "))
    pst.chars(pst#TB, 1) 
    pst.bin(therm.GetConfigRegister,16)
    pst.chars(pst#NL, 1)   
    
    pst.str(String("OS Value: ")) 
    pst.chars(pst#TB, 1)
    pst.bin(therm.GetOneShotBit,1)
    pst.chars(pst#NL, 1)   
    pst.str(String("Alert Status: ")) 
    pst.chars(pst#TB, 1)                          
    pst.bin(therm.GetAlertBit,1)
    pst.chars(pst#NL, 1)
    pst.str(String("Alert High: ")) 
    pst.chars(pst#TB, 1)
    pst.dec(therm.GetAlertHighC)
    pst.chars(pst#NL, 1)
    pst.str(String("Alert Low: ")) 
    pst.chars(pst#TB, 1)
    pst.dec(therm.GetAlertLowC)
    
    pst.chars(pst#NL, 1)     
    pst.chars(pst#NL, 1) 


{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  