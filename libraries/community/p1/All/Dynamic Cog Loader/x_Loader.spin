{{                                         
x_Loader - V09.01.16
┌────────────────────────────────────┐
│   Copyright (c) 2009 Carl Jacobs   │
│ (See end of file for terms of use) │
└────────────────────────────────────┘

I2C Driver and EE COG Loader in spin code.

I2C has been done before, but I thought I'd do it again as a little excercise.
This driver is very low level - you'll need to know what you're doing to access
any I2C devices. But the good part is that it will allow you to access ANY I2C
devices. This driver can be used as an object in multiple modules on the same
I2C port - As long as you're only using 1 device at a time.
}}

CON
  EEPROM  = $A0    'I2C address of EEPROM


DAT
  SDA_Pin long 0
  SCL_Pin long 0
  Buf     long 0


PUB Init(SCL, SDA, MemPtr)
{{
Initialise the pins used for I2C communications, as well as a buffer to use for
loading COG images from high EEPROM memory.
If LoadCog is going to be used, then MemPtr needs to point to an area that has
got at least 2048 bytes free.
}}
  SCL_Pin := SCL
  SDA_Pin := SDA
  Buf     := MemPtr


PUB LoadCOG(MemAddr, EntryAddr) : CogNum | ptr
{{
Start a PASM cog by first retrieving the PASM image from EEPROM into the memory
buffer that was passed into Init. The result is -1 on failure, or the cog number
of the cog that was started. 
}}
  CogNum := -1
  if not (Buf and SetEEAddress(MemAddr))
    return
  if not Start(EEPROM, 1)
    return
  ptr := Buf
  'We are fortunate in that EEPROMs will allow continuous reading! Although
  'at this point I am making a grand generalisation about all EEPROMs. 
  repeat constant(496 * 4 - 1)
    byte[ptr++][0] := Read(1)
  byte[ptr][0] := Read(0)
  Stop
  CogNum := CogNew(Buf, EntryAddr)
    

PUB SetEEAddress(hwaddr) | v
  if not Start(EEPROM, 0)
    return
  Write((hwaddr >> 8) & $ff)
  Write(hwaddr & $ff)
  result := 1

    
PUB Stop
{{
Send an I2C stop condition to the bus.
}}
  'set the pins to the idle state 
  outa[SCL_Pin]~~
  outa[SDA_Pin]~~
  'make the I2C pins inputs
  dira[SDA_Pin]~               
  dira[SCL_Pin]~


PUB Start(Address, IsReading) : Ack | addr
{{
Send I2C start condition. This function will also send the address of the
device being communicated with.
Params : Set IsReading to 1 if reading and 0 if writing. See device
         datasheet to know when to read and when to write.
Return : Return 1 for an ACK and 0 for a NAK.   
}}
  'set the pins to the idle state
  outa[SCL_Pin]~~                
  outa[SDA_Pin]~~
  'set the pins as outputs
  dira[SCL_Pin]~~               
  dira[SDA_Pin]~~
  'transmit an I2C start condition
  outa[SDA_Pin]~            
  outa[SCL_Pin]~
  'transmit the device address
  Ack := Write(Address + IsReading)                


PUB Write(byteval) : Ack | val
{{
Write a byte to the I2C device.
Params : The byte to write.
Return : Return 1 for an ACK and 0 for a NAK.
}}
  'bit reverse the address so we can use the LSBs
  val := byteval >< 8                
  repeat 8
    outa[SDA_Pin] := val & 1
    outa[SCL_Pin]~~                                      
    outa[SCL_Pin]~
    val >>= 1
  'see if the message was received OK  
  Ack := GetAck


PUB Read(AckIt) : val
{{
Read a byte from the I2C device.
Return : The byte that was read.
}}
  'SDA Pin to input
  dira[SDA_Pin]~                '
  'initialiase the value to be returned in 
  val := 0
  repeat 8
    outa[SCL_Pin]~~
    'read a single bit                     
    val := (val << 1) | ina[SDA_Pin]
    outa[SCL_Pin]~
  'ACK the byte that was received
  dira[SDA_Pin]~~
  if AckIt
    outa[SDA_Pin]~
  else
    outa[SDA_Pin]~~
  outa[SCL_Pin]~~
  outa[SCL_Pin]~
    

PUB GetAck : Ack
{{
PRI I2CGetAck
  Read the next bit from the I2C device.
  Return : Return 1 for an ACK and 0 from a NAK - although the actual logic state
           returned from the device is opposite to this. 
}}
  'SDA Pin to input
  dira[SDA_Pin]~                '
  outa[SCL_Pin]~~     
  Ack := ina[SDA_Pin]
  outa[SCL_Pin]~
  'Set the SDA Pin is set to output ...    
  dira[SDA_Pin]~~
  outa[SDA_Pin]~
  not Ack


{{
 ┌───────────────────────────────────────────────────────────────────────────┐
 │               Terms of use: MIT License                                   │
 ├───────────────────────────────────────────────────────────────────────────┤ 
 │  Permission is hereby granted, free of charge, to any person obtaining a  │
 │ copy of this software and associated documentation files (the "Software"),│
 │ to deal in the Software without restriction, including without limitation │
 │ the rights to use, copy, modify, merge, publish, distribute, sublicense,  │
 │   and/or sell copies of the Software, and to permit persons to whom the   │
 │   Software is furnished to do so, subject to the following conditions:    │
 │                                                                           │
 │  The above copyright notice and this permission notice shall be included  │
 │          in all copies or substantial portions of the Software.           │
 │                                                                           │
 │THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR │
 │ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  │
 │FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE│
 │  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER   │
 │ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   │
 │   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     │
 │                      DEALINGS IN THE SOFTWARE.                            │
 └───────────────────────────────────────────────────────────────────────────┘ 
}}         