''********************************************
''*  Solar_Path_Demo                         *
''*  Solar Calculator Object                 *
''*  Author: Gregg Erickson                  *
''*  December 2011                           *
''*  See MIT License for Related Copyright   *
''*  See end of file and objects for .       *
''*  related copyrights and terms of use     *
''*                                          *
''*  This uses code from FullFloat32 &       *
''*  equations and equations from a          *
''*  version of "Solar Energy Systems        *
''*  Design" by W.B.Stine and R.W.Harrigan   *
''*  (John Wiley and Sons,Inc. 1986)         *
''*  retitled "Power From The Sun"           *
''*  http://www.powerfromthesun.net/book.html*
''********************************************

{{ This Demonstrates the use of the Solar Object to
calculate the azimuth and angle of the sun's
position and solar time over a day then outputs it
to the Parallax Serial Terminal and a 2x16 LCD as
well as driving two servos for a two axis laser
drive system to trace a sundial or path in the sky.


The solar object calculates a good approximation
of the position (altitude and azimuth) of the sun
at any time (local clock or solar) during the day
as well as events such as solar noon, sunrise,
sunset, twilight(astronomical, nautical, civil),
and daylength. Derived values such as the equation
of time, time meridians, hour angle, day of the year
and declination are also provided.

Please note: The code is fully documented and is purposely less
compact than possible to allow the user to follow and/or
modify the formulas and code.
}}
{The inputs include date, local/solar time,latitude,
longitude and daylight savings time status. Adjustments
are made for value local time zones, daylight savings
time, leap year, seasonal tilt of the earth,
retrograde of earth rotation, and ecliptic earth
orbit (Perihelion,apihelion) and atmospheric refraction.

Potential Level of Error: The equations used are good
approximations adequate for small photovoltaic panels,
flat panel or direct apeture thermal collectors. A quick
check against NOAA data indicates a match within a
degree and minute.  More refinement may be needed for
concentrating collectorsthat focus light through a lense
or parabolic reflector. The equation of time formula
achieves an error rate of roughly 16 seconds with a max of
38 seconds. The error would need to have an average error
in the seconds of degrees and seconds of time to effectively
target the whole image on the target.

Additional error from mechanical tracking devices will
also add to the error.  Some report that these low
precision forumulas may be within a degree of angle and
a minute or so of time compared to the apparent direction
from the perspective of the observer. However, precise
verification has not been verified as calculated by this
code and/or processor. The error also increases as the
altitude gets closer to the horizon due to atmospheric
disortion and diffraction, especially at sunset and sunrise.
It may be intuitive but the accuracy is not valid when
the sun dips below the horizon such as beyond the artic
and antartic circles or at night.

In summary, this code is appropriate for two axis flat
panel tracking applications where accuracy within a degree
or two would result in negligible losses according to the
cosine effect. It would also be an effective "predictive"
complement to light sensor tracking algorims that can "hunt"
or require rapid movement during cloudy condition.  The
user should verify function, accuracy and validity of
output for any specific application.  No warranty is implied
or expressed.  Use at your own risk...

}


CON
  _clkmode = xtal1 + pll16x  '80 mhz, compensates for slow FP Math
  _XinFREQ = 5_000_000       'Can run slower to save power


  _leftServoPin = 8            'Servo Pin for Azimuth
  _rightServoPin = 9           'Servo Pin for Altitude
  _updateFrequencyInHertz = 50 'Servo Update Frequency
  leftServospan=169.0          'Azimth Angle in Degrees that Servo Rotates
  LSP_scalar=1077              'Scalar when Servo is Positive, adjust using max angle for correct physical angle
  LSN_scalar=1040              'Scalar when Servo is Negative, adjust using max angle for correct physical angle
  rightServospan=160.0         'Angle in Degrees that Altitude Servo Rotates
  RSP_scalar=1084              'Scalar when Servo is Positive, adjust using max angle for correct physical angle
  RSN_scalar=1029              'Scalar when Servo is Negative, adjust using max angle for correct physical angle



VAR


Long Az_Change              'test variables
Long Alt_Change             'Test variables

'-------Angular Variables----(FP=Floating Point, I=Integer)
Long Latitude, Longitude    'FP:Latitude & Longitude of Observer
Long Altitude, Azimuth      'FP:Angle of Sun Above Horizon and Heading
Long SunriseAz,SunsetAz     'FP:Azimuth at Sunrise and Sunset
Long HourAngle              'FP:Angle ofSun from Noon, Due to Rotation
Long HorizonHourAngle       'FP:HourAngle at Sunset and Sunrise
Long HorizonRefraction      'FP:Angle of Atmospheric Refraction at Sunset and Sunrise
Long Declination            'FP:Tilt of Earth Relative to Solar Plain
Long North,East,Height      'FP:Northerning, Easterning, Height of Target A
Long HelioAz,HelioAlt,HelioE'FP:Angle to Point a Heliostat to Hit Target A with Error
Long Theta                  'FP:Angle of Reflect Between Sun and Target Vectors

'-------Time Variable--------(FP=Floating Point, I=Integer)
Long Sunrise,Sunset         'FP:Solar Time at Sunrise and Sunset
Long LCT,SCT                'FP:Local Clock Time, Solar Clock Time
Long Meridian               'FP:Longitude of Time Zone Meridian
Long Month,Day,Year         'Integer:Year,Month & Day of the Year
Long NDays                  'FP:Day of Year starting with Jan 1st=1
Long Hour,Minute, Second,AMPM 'Integer:Local Time Hour, Min & Sec
Long SolarTime,ClockTime    'FP:Local Time in Hours Adj to Solar Noon
Long DST                    'FP:Day Light Saving Time, =1.0 if true
Long Daylight               'FP:Hours of Daylight in a Day
Long EOT,EOT2,EOT3          'FP:Equation of Time, Apparent Shift in
                               'Solar Noon Due to Earth's Orbital
                               'Elipse from Apogee(far) to Perigee(near)


Long LocalRise,LocalSet     'Local Clock Time for Sunrise and Sunset
Long TimeString
Byte DateStamp[11], TimeStamp[11]
Long ServoPulse

Obj

  S:    "Solar2.4"                 'Solar Almanac Object
  PST:  "Parallax Serial Terminal" 'For Output & Troubleshooting
  term: "Simple_Serial"            'Serial Output for 2x16 LCD

  FStr: "FloatString"              'Conversions for Output
  Fmath:"Float32Full"              'The Full Version is needed for ATAN,ACOS,ASIN
  ser:  "PWM2C_SEREngine.spin"     'Servo Object


Pub main| n, Az_Test,Alt_Test

'-------------------Start Objects-------------
Fmath.start        'Start Floating Point Math Object
term.init(27,27,19_200)     ' Initiate Simple Serial to 2x16 LCD
ifnot(ser.SEREngineStart(_leftServoPin, _rightServoPin, _updateFrequencyInHertz))
    reboot                  ' Start Servo Object


'-------------------Set Defaults--------------


Az_test:=180
Alt_Test:=0

Alt_Change:=1
Az_Change:=1

repeat

      waitcnt(clkfreq/2+cnt)

      'Create Test Altitude and Azimuth with +/- change base upon limits

      If Alt_Test==78
         Alt_Change:=-1
      If Alt_Test==-30
         Alt_Change:=1

      If Az_Test==250
         Az_Change:=-1
      If Az_Test==110
         Az_Change:=1

      Alt_Test:=Alt_test+Alt_Change
      Az_Test:=Az_test+Az_Change
      azimuth:=fmath.ffloat(Az_Test)
      altitude:=fmath.ffloat(Alt_Test)

      'Transmit location to LCD Readout

      term.tx($80)
      term.str(string("Azimuth Altitude"))
      term.tx($94)
      term.str(string("                "))
      term.tx($94)
      term.str(FStr.FloatToString(Azimuth))
      term.str(string("   "))
      term.str(FStr.FloatToString(Altitude))


      'Azimuth:=180.0  'Use these lines of code to set azimuth
      'Altitude:=0.0  'Use these lines of code to set azimuth

      'Move Servos
      servopulse:=fmath.ftrunc(fmath.fmul(fmath.fdiv(Altitude,rightservospan),1500.0))
      if servopulse>0 'Harware Adjustment to match specific servo
         servopulse:=RSP_scalar*servopulse/1000
      else
         servopulse:=RSN_scalar*servopulse/1000
      servopulse:=650#>(1500-(ServoPulse))<#2250
      ser.rightPulseLength(ServoPulse)

      Azimuth:=fmath.fsub(Azimuth,180.0)
      servopulse:=fmath.ftrunc(fmath.fmul(fmath.fdiv(Azimuth,leftservospan),1500.0))

      if servopulse>0 'Harware Adjustment to match specific servo
         servopulse:=LSP_scalar*servopulse/1000
      else
         servopulse:=LSN_scalar*servopulse/1000

      servopulse:=650#>(1500-(ServoPulse))<#2250
      ser.leftPulseLength(ServoPulse)


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