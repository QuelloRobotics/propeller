{{
***************************************
* Maxbotix MaxSonar Demo V1.0         *
* (C) 2008 Anon-Industries            *
* Author:  Harrison Jones             *
* Started: 05-24-2008                 *
***************************************

Interface to Maxbotix Sonar sensor and measure distance.
Connections should be as follows:
MaxBotix MaxSonar   ---         Propeller
GND                             GND
+5                              +5 or +3.3
Tx                              Pin(This pin is an INPUT)
Rx                              NC
An                              NC
PW                              Another Pin(This pin is an INPUT)
BW                              NC




}}
CON
  SonarTx = 7 'or whatever pin you are using
  SonarPw = 4
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
VAR
  long SonarDist

OBJ
  Sonar : "MaxSonar"
  Com : "FullDuplexSerial"
PUB Main
  'Init
  Com.Start(31,30,%0000,9_600)
  Sonar.Start(SonarTx,SonarPw,1) 'Initalizes the MaxSonar and saves SonarTx and SonarPw to memory, use PWM for the input(Uses 0 cogs, could cause cog-lockup, use watchdog
  'Sonar.Start(SonarTx,SonarPw,0) 'Initalizes the MaxSonar and saves SonarTx and SonarPw to memory, use Serial for the input(Uses 1 cogs)
  
  'Main Run
  Com.Str(String("Welcome to MaxSonar_Demo.spin by Harrison Jones",13))
  repeat
    SonarDist := Sonar.GetDist  'Gets distance in inches and feeds it into a variable.
    'Now do something with the distance
    Com.Str(String("Distance of:"))
    Com.Dec(SonarDist)
    Com.Str(String(" inches",13))




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