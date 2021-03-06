{{
=================================================================================================
  File....... uSDPropLoader
  Version.... 0.1
  Purpose.... Needed a prop loader that reads from uSD base on the filename given
               
  Author..... MacTuxLin (Kenichi Kato)
               -- see below for terms of use
  E-mail..... MacTuxLin@gmail.com
  Started.... 25 Mar 2011
  Updated....
        25 Mar 2011
                1. Refer to demo file.
        28 Mar 2011
                1. Completed v0.1

  Usage: (see demo)
  =================

  uSDPropLoader.Start(DOPin, CLKPin, DIPin, CSPin, WPPin, CDPin, _rtc_DAT, _rtc_CLK)

  'Loop thru firmware per onboard prop
  uSDPropLoader.PinRESn, PinP31, PinP30, Version, Command, fileNameStrPtr)

  uSDPropLoader.Stop  
=================================================================================================
}}
CON
  #1, ErrorConnect, ErrorVersion, ErrorChecksum, ErrorProgram, ErrorVerify
  #0, Shutdown, LoadRun, ProgramShutdown, ProgramRun


OBJ
  uSD   : "SD-MMC_FATEngine.spin"
  Str   : "ASCII0_STREngine.spin"


VAR
  long P31, P30, LFSR, Ver, Echo

  byte tempByte[2]

  byte watchByte


PUB Start(DOPin, CLKPin, DIPin, CSPin, WPPin, CDPin, _rtc_DAT, _rtc_CLK)


  ifnot(uSD.FATEngineStart(DOPin, CLKPin, DIPin, CSPin, WPPin, CDPin, _rtc_DAT, _rtc_CLK, -1))
    reboot


  'Mounting uSD drive. Please note to add your own catches here.
  uSD.mountPartition(0)


  return



PUB Stop

  uSD.unmountPartition
  uSD.FATEngineStop

  return



PUB Connect(PinRESn, PinP31, PinP30, Version, Command, fileNameStrPtr) : Error

  'Openfile
  if (Str.stringCompareCI(Str.trimString(uSD.openFile(fileNameStrPtr, "R")), Str.trimString(fileNameStrPtr)))
    'Error as non-zero => not equal
    Error := String("File Open Error")
    return


  'File Open Successful

  
  'set P31 and P30
  P31 := PinP31
  P30 := PinP30

  'RESn low
  outa[PinRESn] := 0            
  dira[PinRESn] := 1
  
  'P31 high (our TX)
  outa[PinP31] := 1             
  dira[PinP31] := 1
  
  'P30 input (our RX)
  dira[PinP30] := 0             

  'RESn high
  outa[PinRESn] := 1            

  'wait 100ms
  waitcnt(clkfreq / 10 + cnt)

  'Communicate (may abort with error code)
  'if Error := \Communicate(Version, Command, CodePtr)
  if Error := \Communicate(Version, Command)   '<--No Need CodePtr, use read
    dira[PinRESn] := 0

  'P31 float
  dira[PinP31] := 0

  
  'Close file
  uSD.closeFile
  

PRI Communicate(Version, Command) | ByteCount

  'Init
  bytefill(@tempByte, 0, 2)


  'output calibration pulses
  BitsOut(%01, 2)               

  'send LFSR pattern
  LFSR := "P"                   
  repeat 250
    BitsOut(IterateLFSR, 1)

  'receive and verify LFSR pattern
  repeat 250                   
    if WaitBit(1) <> IterateLFSR
      abort ErrorConnect

  'receive chip version      
  repeat 8
    Ver := WaitBit(1) << 7 + Ver >> 1

  'if version mismatch, shutdown and abort
  if Ver <> Version
    BitsOut(Shutdown, 32)
    abort ErrorVersion

  'send command
  BitsOut(Command, 32)

  'handle command details
  if Command          

    'send long count
    uSD.fileSeek(8)
    tempByte[0] := uSD.readByte
    uSD.fileSeek(9)
    tempByte[1] := uSD.readByte    
    ByteCount := tempByte[0] | tempByte[1] << 8
    BitsOut(ByteCount >> 2, 32)


    uSD.fileSeek(0)
    'send bytes
    repeat ByteCount
      watchByte := uSD.readByte                        
      BitsOut(watchByte, 8)                            



    'allow 250ms for positive checksum response
    if WaitBit(25)
      abort ErrorChecksum

    'eeprom program command
    if Command > 1
    
      'allow 5s for positive program response
      if WaitBit(500)
        abort ErrorProgram
        
      'allow 2s for positive verify response
      if WaitBit(200)
        abort ErrorVerify
                

PRI IterateLFSR : Bit

  'get return bit
  Bit := LFSR & 1
  
  'iterate LFSR (8-bit, $B2 taps)
  LFSR := LFSR << 1 | (LFSR >> 7 ^ LFSR >> 5 ^ LFSR >> 4 ^ LFSR >> 1) & 1
  

PRI WaitBit(Hundredths) : Bit | PriorEcho

  repeat Hundredths
  
    'output 1t pulse                        
    BitsOut(1, 1)
    
    'sample bit and echo
    Bit := ina[P30]
    PriorEcho := Echo
    
    'output 2t pulse
    BitsOut(0, 1)
    
    'if echo was low, got bit                                      
    if not PriorEcho
      return
      
    'wait 10ms
    waitcnt(clkfreq / 100 + cnt)

  'timeout, abort
  abort ErrorConnect

  
PRI BitsOut(Value, Bits)

  repeat Bits

    if Value & 1
    
      'output '1' (1t pulse)
      outa[P31] := 0                        
      Echo := ina[P30]
      outa[P31] := 1
      
    else
    
      'output '0' (2t pulse)
      outa[P31] := 0
      outa[P31] := 0
      Echo := ina[P30]
      Echo := ina[P30]
      outa[P31] := 1

    Value >>= 1

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