{{ ADC_0831_LM34.spin


***********************************************************************

   ADC_0831LM34.spin        Larry Freeze   September 2007
    
***********************************************************************


        ┌──────────────────────────────────────────┐
        │ Copyright September 2007 by Larry Freeze │               
        │     See end of file for terms of use.    │               
        └──────────────────────────────────────────┘


                ADC0831
              
                                 │  Vcc(+5V)
             ┌───────────────┐   │
  pin 20 ────┤1 CS    VCC  8 ├───┘                
        ┌────┤2 VIN+  CLK  7 ├─────────    pin 19
        │  ┌─┤3 VIN-  DO   6 ├───────    pin 21 (1K resistor)
        │  ╋─┤4 GND   Vref 5 ├───────┐  
  1uf   │   └───────────────┘       │                                    │              Pots are 10K and resisters are 1K
 ┌───┫                                       
   270Ω│                      +5V ────┐
        │ LM34                            
       ┌┻┐  
   ┌───┫ ┣──  Vcc(+5V) 
      └─┘                     Hardware:   Propstick (serial connector)
                                           LM34 National Semiconductor
                                           ADC0831 National Semiconductor
                                           1, resistor 270 ohm
                                           1, resistor 1K ohm
                                           1, Pot 10K 
Notes                                      1, capacitor 1UF

I am a beginner with the propeller, this object was developed after
some study of the propeller manual, and much trial and error. I
attempted to make this object as simple as possible hoping it may
help other beginners. I would welcome and appreciate any comments
or corrections.  I incorporated the existing object "Full Duplex Serial"
from the object exchange library.

The purpose of this object is to produce a variable which will
contain the current temperature (farenheit) and display it repeatedly
on the desktop monitor, via a hyperterminal connection.

Testing of the completed circuit was done over several days with a
temperature range of about 38 degrees farenheit (glass of ice water)
to  about 108 degrees farenheit (glass of hot water).

After constructing the circuit, the variable resistor must be adjusted
once. It should be adjusted until the temperature displayed matches
the temperature at the LM34. In this circuit the variable resistor was adjusted to
7.45K  ohms, this cooresponded to the temperature at the
lm34 of 72 degrees. 

I have used these pins and connections in this object.
           ADC clk PIN 7 to propeller PIN 19
           ADC cs  PIN 1 to propeller PIN 20
           ADC do  PIN 2 to propeller PIN 21  
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
var
 byte lm34temp, temp
OBJ 
    SER  : "FullDuplexSerial" 
pub start
 ser.start(31, 30, 0, 9600) 

{the following repeat statements activate the chip select pin on the adc
and then captures each bit from the ADC and modifies the temp and
lm34temp variables depending on the value of each bit}

repeat
  dira[21] :=0     'set pin 21 as input
  lm34temp :=0     'starts the lm34temp variable as 0
  temp:=ina[21]    'sets the value of temp to the value of pin 21 (one or zero)
  dira[20]~~       'sets pin as output
  outa[20]~~       'sets pin 20 high  
  outa[20]~        'sets pin 20 low    'takes chip select low activating the adc       'the ADC0831

  repeat 8  
    dira[19]~~     'sets pin as output
    outa[19]:=1    'sets clock (pin 19) high      
    outa[19]:=0    'sets clock (pin 19)low  'takes the adc clk low 
      if ina[21]==1  
         temp:=1
      else
         temp:=0        
    lm34temp:=lm34temp*2
    lm34temp:=lm34temp+temp

      
  ser.tx(10)                          'line feed
  ser.tx(13)                          'carriage return
  waitcnt (1_000_000 * 50 + cnt )
  ser.str(string("   temperature farenheit =   "))    
  ser.dec(lm34temp)                   'display decimal value of lm34temp
  ser.str(string("   binary value is   "))     
  ser.bin(lm34temp,8)                 'display binary value of lm34temp 
  ser.tx(13)                          'line feed
  ser.tx(10)                          'carriage return


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