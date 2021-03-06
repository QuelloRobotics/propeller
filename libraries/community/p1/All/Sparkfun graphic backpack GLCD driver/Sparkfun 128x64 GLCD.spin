{{
Sparkfun Graphic serial backback/ 128x64 GLCD driver...


File: Sparkfun 128x64 GLCD.spin
Version: 1.0
Author: Harrison Saunders(Aka, Ravenkallen)
Date of creation: 8/11/10
Date of latest update: 8/11/10


See end of file for terms of use.


General Info:
This driver is created for the Sparkun graphic serial backpack and the line of GLCD's they made utilizing the backback.
The backpack and their associated displays are quite easy and flexiable to use. It can be used to draw text, draw lines,
draw circles, draw boxes, reset indivual pixels, change backlight duty cycle, erase blocks...
This driver is also simple and uses a proven serial object
"Parallax serial terminal" as its main communication system... NOTE this driver was made for use with the 128x64
version and although the 128x128 use the same backpack, proper functioning is not guaranteed ( although probable)

Below are some details of the Serial backpack's electrical/ communication characteristics.

VCC: 6 to 7 volts...
Serial inputs accept a 5 volt signal

Power requirements: Uses 220 mA's with the backlight duty cycle at %100

Defualt baud rate is 115_000bps, 8 data bits, one stop bit, no parity...

There is a small pot on the back to adjust the contrast.


Pinout

VIN pin: is the + power input
GND pin: is connected to ground
RX pin: is connected to a Propeller I/O pin
Tx pin: not used(yet). Leave unconnected.


Connecting to Propeller:
Simple, no other external components are needed. Just hook up power and ground, and then place the Rx line on the Prop pin of
your choosing...
  

Notes: Play close attention to the comments on the Drawbox method.


Update 9/29/10....

Updates include...

Outputting decimal numbers via "dec" method

Outputting hex numbers via "hex" method

}}




Con
'' These constants are used by the lcd to communicate.
LCDcommand = 124
LCDerase = 0
LCDdemo = 4
LCDbaud = 7
LCDreverse = 18
LCDdrawline = 12
LCDdrawbox = 15
LCDdrawcircle = 3
LCDHortext  = 24
LCDvertext  = 25
LCDsetpixel = 16
LCDeraseblock = 5
LCDdutycycle = 2






obj
Serio: "parallax serial terminal"


var
byte chararray[21], varstore



pub Start(Rxpin, Txpin, Baudrate)'' Call this function first. You must specify the Serial Rx and Tx pins,
'' along with the baud rate. Calling this method will also clear the screen.


serio.startrxtx(Rxpin, Txpin, 0, Baudrate)
waitcnt(clkfreq/100 + cnt)'' Give time for the serial to intitialize
erasedisplay




pub Writechar(Charbyte)'' Writes a single ascii character to the display...

serio.char(charbyte)



pub Erasedisplay'' This will erase the display and set the cursor back to zero...

serio.char(LCDcommand)
serio.char(LCDerase)





pub Playdemo'' This will play the factory demo...

serio.char(LCDcommand)
serio.char(LCDdemo)



pub Changebaudrate(Baudbyte)'' Changes the baud rate based upon ascii input. Table below..
'' "1" = 4800bps  "2" = 9600bps
'' "3" = 19,200bps  "4" = 38,400
'' "5" = 57,600bps "6" = 115,200bps


serio.char(LCDcommand)
serio.char(LCDbaud)
serio.char(baudbyte)
waitcnt(clkfreq/100 + cnt)


pub Writestring(Stringaddress) '' This will write a string of twenty-one characters to the display... Must be byte sized

repeat 21
 varstore := byte[stringaddress++]
 serio.char(varstore)




pub Reverselcd ''This will simply reverse the background polarity of the screen

serio.char(LCDcommand)
serio.char(LCDreverse)
waitcnt(clkfreq/100 + cnt)



pub Drawbox(X1, Y1, X2, Y2)'' This command  will draw a box and uses decimal values(Instead of ASCII) .
''It will use the variables "X1" and "Y1" for setting "walls" at one angle
'' and then use the variables "X2" and "Y2" for setting the other two at the other end..
'' For instance, if the "X1" variable = 10 the wall on the left will start at the tenth pixel to the right
'' and if the "Y1" variable = 10 the bottom wall will start at the tenth pixel from the bottom. The same applies to the other
'' set of values just in reverse....WARNING, some displays may produce a 5x7 "full" character at the top left part of
'' the screen. It may do this and produce even more when a box is drawn. If it does you may have to erase the whole screen or
'' preform a box erase.

serio.char(LCDcommand)
serio.char(LCDdrawbox)
serio.char(X1)
serio.char(Y1)
serio.char(X2)
serio.char(Y2)
serio.char(1)



pub Drawcircle(X, Y, R)''Draw a circle. This command is similar to the drawbox command,
'' except for the fist two values indicate the center
'' of the circle and the last variable is the value of the radius...

serio.char(LCDcommand)
serio.char(LCDdrawcircle)
serio.char(X)
serio.char(Y)
serio.char(R)
serio.char(1)


pub Movecursorvertical(verticalbyte)'' This will move the cursor up or down by the number of pixels stated in "Verticalbyte"


serio.char(LCDcommand)
serio.char(LCDvertext)
serio.char(verticalbyte)


pub Movecursorhorizontal(horizontalbyte)'' This will move the cursor left or right by
''the number of pixels stated in "Horizontalbyte"

serio.char(LCDcommand)
serio.char(LCDhortext)
serio.char(horizontalbyte)




pub Setpixel(X, Y, Clrorset)'' This command simply sets or resets a pixel. "X" = Horizontal decimal, "Y" = Vertical decimal and "Clrorset"
''determines if the pixel is on or off.  1 = On,  0 = Off

serio.char(LCDcommand)
serio.char(LCDsetpixel)
serio.char(X)
serio.char(Y)
serio.char(Clrorset)



pub eraseblock(X1, X2, Y1, Y2)'' This will erase all of the contents inside the box determined by the four values
'' This command works just like the draw box command 

serio.char(LCDcommand)
serio.char(LCDeraseblock)
serio.char(X1)
serio.char(X2)
serio.char(Y1)
serio.char(Y2)
Waitcnt(clkfreq/200 + cnt)



pub Drawline(x1,y1,x2,y2)'' This command will draw a line and it works similar to the draw box command

serio.char(LCDcommand)
serio.char(LCDdrawline)
serio.char(x1)
serio.char(y1)
serio.char(x2)
serio.char(y2)
serio.char(1)



pub Changeduty(Duty)'' This command will change the display's backlight duty cycle, The data byte must be a decimal value
'' between 0 - 100, with 100 being full on and 0 being full off.

serio.char(LCDcommand)
serio.char(LCDdutycycle)
serio.char(duty)


pub dec(decnumber)'' This command will simply output a decimal number.

serio.dec(decnumber)


pub hex(Hexnumber, digits)'' This command will output a Hex number onto the screen. You may choose how many digits you want with
'' the digit parameter

serio.hex(hexnumber,digits )

pub bin(binnumber, digits)'' This command will just send out a string of numbers in binary format


serio.bin(binnumber, digits)


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