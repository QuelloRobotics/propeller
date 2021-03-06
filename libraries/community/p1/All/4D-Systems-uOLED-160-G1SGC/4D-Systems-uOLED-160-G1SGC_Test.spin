{{
File.......... 4D-Systems-uOLED-160-G1SGC_Test.spin
Purpose....... Test code for the for the various methods of the SW interface to the
               4D Systems uOLED-160-G1SGC display.
Author........ Jim Edwards
E-mail........ jim.edwards4@comcast.net
History....... v1.0 - Initial release
Copyright..... Copyright (c) 2011 Jim Edwards
Terms......... See end of file for terms of use.
}}

OBJ

  Delay         : "Clock"
  Fmt           : "Format"  
  Oled          : "4D-Systems-uOLED-160-G1SGC"
  
CON

  ' General constants
  
  _CLKMODE      = XTAL1 + PLL16X                        
  _XINFREQ      = 5_000_000
  TestJoystick  = TRUE                      ' Set false if hardware doesn't have joystick/button
  TestSound     = TRUE                      ' Set false if hardware doesn't have speaker
  TestSD        = TRUE                      ' Set false if hardware doesn't have SD card

VAR

  byte strbuf[64]                           ' Text buffer for assembling formatted strings
  byte pixels[200]                          ' Pixels buffer for assembling image to draw
  byte sector_data[Oled#MemCardSectorSize]  ' Sector data buffer for memory card operations 
  word tune[64]                             ' Tunes buffer for assembling note, duration tuple values

PUB DisplayTests  

  repeat
    DisplaySetup(TRUE)
    TestDisplayGetDeviceInfo
    Delay.PauseSec(5)
    TestDisplayReplaceBackgndColor
    Delay.PauseSec(1)
    TestDisplaySetPixelsOffOn
    Delay.PauseSec(1)
    TestDisplaySetContrast
    Delay.PauseSec(1)
    TestDisplaySetPowerOffOn
    Delay.PauseSec(1)
    TestDisplayReset
    Delay.PauseSec(1)
    TestDisplaySetSleep
    Delay.PauseSec(1)
    if (TestJoystick)
      TestJoystickGetStatus1
      Delay.PauseSec(1)
      TestJoystickGetStatus2
      Delay.PauseSec(1)
      TestJoystickWaitStatus
      Delay.PauseSec(1)
    if (TestSound)
      TestSoundPlayNoteOrFrequency
      Delay.PauseSec(1)
      TestSoundPlayTune
      Delay.PauseSec(1)
    TestGraphicsAddDrawBitmap
    Delay.PauseSec(1)
    TestGraphicsDrawCircle
    Delay.PauseSec(1)
    TestGraphicsDrawTriangle
    Delay.PauseSec(1)
    TestGraphicsDrawImage
    Delay.PauseSec(1)
    TestGraphicsSetBackgndColor
    Delay.PauseSec(1)
    TestGraphicsDrawLine
    Delay.PauseSec(1)
    TestGraphicsDrawPixel
    Delay.PauseSec(1)
    TestGraphicsReadPixel
    Delay.PauseSec(1)
    TestGraphicsScreenCopyPaste
    Delay.PauseSec(1)
    TestGraphicsDrawPolygon
    Delay.PauseSec(1)
    TestGraphicsReplaceColor
    Delay.PauseSec(1)  
    TestGraphicsSetPenMode
    Delay.PauseSec(1)
    TestGraphicsDrawRectangle
    Delay.PauseSec(1)
    TestTextSetOpacity
    Delay.PauseSec(1)
    TestTextDrawStrFixed     
    Delay.PauseSec(1)
    TestTextDrawNumFixed    
    Delay.PauseSec(1)
    TestTextDrawCharFixed
    Delay.PauseSec(1)
    TestTextDrawStrScaled
    Delay.PauseSec(1)
    TestTextDrawNumScaled
    Delay.PauseSec(1)
    TestTextDrawCharScaled
    Delay.PauseSec(1)
    TestTextDrawButton
    Delay.PauseSec(1)
    TestDisplayScroll
    Delay.PauseSec(1)
    if (TestSD)
      TestMemCardClearSectors(0, 100)
      Delay.PauseSec(1)
      TestMemCardWriteReadBytes(20, 50)
      Delay.PauseSec(1)
      TestMemCardWriteReadSectors(20, 50)
      Delay.PauseSec(1)
      TestMemCardSaveLoadImages(100)
      Delay.PauseSec(1)
      TestBuildScriptOnSD(300)
      TestMemCardRunObject(300)
      Delay.PauseSec(1)  
      TestMemCardRunScript(300)
      Delay.PauseSec(1)
      TestMemCardDisplayVideo(500)
      Delay.PauseSec(1)
    DisplayTestTitle(string("Complete!"), 0)
    Delay.PauseSec(1)
    DisplaySetup(FALSE)
    TestShutdown

PRI DisplaySetup(init_enable)

  if (init_enable)
    Oled.DisplayInitialize
  Oled.DisplaySetErrorCheckingOff
  Oled.DisplayClearScreen
  Oled.DisplayReplaceBackgndColor(0, 0, 0) 
  Oled.DisplaySetContrast(12)
  Oled.TextSetOpaque
  Oled.TextSetFont(Oled#TextFontSet5x7)
  Oled.GraphicsSetPenModeSolid

PRI DisplayTestTitle(title_str_addr, pause_secs)

  Oled.DisplayClearScreen
  Oled.TextDrawStrFixed(0, 0, Oled#TextFontSet5x7, 255, 255, 255, string("TEST:"))  
  Oled.TextDrawStrFixed(0, 1, Oled#TextFontSet5x7, 255, 255, 0, title_str_addr)
  Delay.PauseSec(pause_secs)
  
PRI DisplayTestTitleFull(title_str_addr, r_test, g_test, b_test, r_title, g_title, b_title, pause_secs)

  Oled.DisplayClearScreen
  Oled.TextDrawStrFixed(0, 0, Oled#TextFontSet5x7, r_test, g_test, b_test, string("TEST:"))  
  Oled.TextDrawStrFixed(0, 1, Oled#TextFontSet5x7, r_title, g_title, b_title, title_str_addr)
  Delay.PauseSec(pause_secs)

PRI WaitForJoystickPress | status

  repeat
    status := Oled.JoystickGetStatus(Oled#JoystickOptionReturnStatus)
    if ((status == Oled#JoystickStatusUpPress) OR (status == Oled#JoystickStatusLeftPress) OR (status == Oled#JoystickStatusDownPress) OR (status == Oled#JoystickStatusRightPress) OR (status == Oled#JoystickStatusFirePress))
      return

PRI WaitForJoystickPressTimeout(timeout_secs) | status, idle_start

  idle_start := cnt
  repeat
    status := Oled.JoystickGetStatus(Oled#JoystickOptionReturnStatus)
    if (status <> Oled#JoystickStatusNoPress)
      idle_start := cnt
    if ((cnt - idle_start) => (5* clkfreq))
      return 

PRI TestDisplayGetDeviceInfo | dev_type, hw_rev, fw_rev, hor_res, vert_res, index
    
  DisplayTestTitle(string("DisplayGetDeviceInfo"), 1)
  Oled.DisplayGetDeviceInfo(Oled#DisplayInfoOutputSerial, @dev_type, @hw_rev, @fw_rev, @hor_res, @vert_res)

  index := Fmt.bprintf(@strbuf, 0, string("dev_type = [%x hex] "), dev_type.byte[0])  
  case dev_type.byte[0]
    Oled#DisplayInfoDeviceTypeuOLED:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("uOLED")) 
    Oled#DisplayInfoDeviceTypeuLCD:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("uLCD"))  
    Oled#DisplayInfoDeviceTypeuVGA:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("uVGA")) 
    other:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("unknown"))
  strbuf[index] := 0
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)

  Fmt.sprintf(@strbuf, string("hw_rev = %d"), hw_rev.byte[0])
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
   
  Fmt.sprintf(@strbuf, string("fw_rev = %d"), fw_rev.byte[0])
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)

  index := Fmt.bprintf(@strbuf, 0, string("hor_res = [%x] "), hor_res.byte[0])  
  case hor_res.byte[0]
    Oled#DisplayInfoResolution220Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("220 pixels"))
    Oled#DisplayInfoResolution128Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("128 pixels")) 
    Oled#DisplayInfoResolution320Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("320 pixels")) 
    Oled#DisplayInfoResolution160Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("160 pixels"))   
    Oled#DisplayInfoResolution64Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("64 pixels")) 
    Oled#DisplayInfoResolution176Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("176 pixels")) 
    Oled#DisplayInfoResolution96Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("96 pixels")) 
    other:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("unknown"))
  strbuf[index] := 0
  Oled.TextDrawStrFixed(0, 5, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  
  index := Fmt.bprintf(@strbuf, 0, string("vert_res = [%x] "), vert_res.byte[0])  
  case vert_res.byte[0]
    Oled#DisplayInfoResolution220Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("220 pixels"))
    Oled#DisplayInfoResolution128Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("128 pixels")) 
    Oled#DisplayInfoResolution320Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("320 pixels")) 
    Oled#DisplayInfoResolution160Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("160 pixels"))   
    Oled#DisplayInfoResolution64Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("64 pixels")) 
    Oled#DisplayInfoResolution176Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("176 pixels")) 
    Oled#DisplayInfoResolution96Pixels:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("96 pixels")) 
    other:
      index := Fmt.bprintf(@strbuf, index, string("%s"), string("unknown"))
  strbuf[index] := 0
  Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)

PRI TestDisplayReplaceBackgndColor

  DisplayTestTitle(string("DisplayReplaceBackgndColor"), 2)
 
  Oled.DisplayReplaceBackgndColor(0, 255, 0) ' Green
  DisplayTestTitleFull(string("DisplayReplaceBackgndColor"), 0, 0, 0, 0, 0, 0, 0)  
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("GREEN  "))
  Delay.PauseSec(2) 

  Oled.DisplayReplaceBackgndColor(255, 255, 0) ' Yellow
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("YELLOW "))
  Delay.PauseSec(2)  

  Oled.DisplayReplaceBackgndColor(255, 0, 0) ' Red
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("RED    "))
  Delay.PauseSec(2)  
  DisplaySetup(FALSE)
   
PRI TestDisplaySetPixelsOffOn

  DisplayTestTitle(string("DisplaySetPixelsOff/On"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Pixels off "))
  Delay.PauseSec(2)  
  Oled.DisplaySetPixelsOff
  Delay.PauseSec(2) 
  Oled.DisplaySetPixelsOn
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Pixels on "))
  Delay.PauseSec(2)    

PRI TestDisplaySetContrast

  DisplayTestTitle(string("DisplaySetContrast"), 2)
  Oled.DisplayReplaceBackgndColor(255, 255, 0) ' Yellow
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("YELLOW"))
  DisplayTestTitleFull(string("DisplaySetContrast"), 0, 0, 0, 0, 0, 0, 1)
  Oled.DisplayFadeoutContrast(200)
  DisplaySetup(FALSE)

PRI TestDisplaySetPowerOffOn

  Oled.DisplayClearScreen 
  Oled.TextDrawStrFixed(3, 2, Oled#TextFontSet5x7, 255, 255, 255, string("Display power off in:"))
  Oled.TextDrawCharScaled("5", 80, 32, Oled#TextFontSet5x7, 0, 255, 0, 2, 2)
   
  Oled.TextDrawStrFixed(3, 7, Oled#TextFontSet5x7, 255, 255, 0, string("Restart in ~5 seconds"))
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("4", 80, 32, Oled#TextFontSet5x7, 0, 255, 0, 2, 2)  
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("3", 80, 32, Oled#TextFontSet5x7, 255, 255, 0, 2, 2)  
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("2", 80, 32, Oled#TextFontSet5x7, 255, 255, 0, 2, 2)  
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("1", 80, 32, Oled#TextFontSet5x7, 255, 0, 0, 2, 2)  
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("0", 80, 32, Oled#TextFontSet5x7, 255, 0, 0, 2, 2)  
  Delay.PauseSec(1)

  Oled.DisplayClearScreen    
  Delay.PauseMSec(20)    
  Oled.DisplaySetPowerOff
  Delay.PauseSec(1)
  Oled.DisplaySetPowerOn
  Delay.PauseSec(1)
  DisplaySetup(TRUE)
  DisplayTestTitle(string("DisplayPowerOff/On Done"), 2)

PRI TestDisplayReset

  Oled.DisplayClearScreen 
  Oled.TextDrawStrFixed(5, 2, 0, 255, 255, 255, string("Display reset in:"))
  Oled.TextDrawCharScaled("5", 80, 32, Oled#TextFontSet5x7, 0, 255, 0, 2, 2)
   
  Oled.TextDrawStrFixed(3, 7, 0, 255, 255, 0, string("Restart in ~5 seconds"))
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("4", 80, 32, Oled#TextFontSet5x7, 0, 255, 0, 2, 2) 
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("3", 80, 32, Oled#TextFontSet5x7, 255, 255, 0, 2, 2) 
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("2", 80, 32, Oled#TextFontSet5x7, 255, 255, 0, 2, 2) 
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("1", 80, 32, Oled#TextFontSet5x7, 255, 0, 0, 2, 2) 
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("0", 80, 32, Oled#TextFontSet5x7, 255, 0, 0, 2, 2) 
  Delay.PauseSec(1)

  Oled.DisplayClearScreen    
  Delay.PauseMSec(20)    
  Oled.DisplayReset
  Delay.PauseSec(2)
  DisplaySetup(TRUE)
  DisplayTestTitle(string("DisplayReset Done"), 2) 

PRI TestDisplaySetSleep

  ' Note that this command seems to wait on the display ack until the wake event has occurred.
  
  DisplayTestTitle(string("DisplaySetSleep"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Press joystick to wake!"))
  Delay.PauseSec(1) 
  Oled.DisplaySetSleep(Oled#DisplaySleepModeWakeOnJoystick, 0)
  Oled.DisplayReset
  Delay.PauseSec(2)
  DisplaySetup(TRUE)

PRI TestJoystickGetStatus1 | idle_start, status

  DisplayTestTitle(string("JoystickGetStatus1"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Press any joystick"))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("position to test"))  
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 255, 0, string("Exits if idle >= 5 Secs"))
  Delay.PauseSec(1)
  idle_start := cnt

  repeat
    status := Oled.JoystickGetStatus(Oled#JoystickOptionReturnStatus)
    case status
      Oled#JoystickStatusNoPress:
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = No press    "))
      Oled#JoystickStatusUpPress:
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Up press    "))
      Oled#JoystickStatusLeftPress:                                
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Left press  "))
      Oled#JoystickStatusDownPress:
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Down press  "))
      Oled#JoystickStatusRightPress:                                 
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Right press "))
      Oled#JoystickStatusFirePress:
        Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Fire press  "))
        
    Oled.TextDrawStrFixed(0, 7, Oled#TextFontSet5x7, 0, 255, 0, @strbuf) 
    if (status <> Oled#JoystickStatusNoPress)
      idle_start := cnt
    Fmt.sprintf(@strbuf, string("Idle time = %d Secs"), (cnt - idle_start) / clkfreq)
    Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
    if ((cnt - idle_start) => (5* clkfreq))
      return 

PRI TestJoystickGetStatus2

  DisplayTestTitle(string("JoystickGetStatus2"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Press any joystick"))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("position to test"))  
  Oled.JoystickGetStatus(Oled#JoystickOptionWaitForPressRel)

PRI TestJoystickWaitStatus | status

  DisplayTestTitle(string("JoystickWaitStatus"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Press any joystick"))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("position to test"))
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 255, 0, string("Exits if idle >= 5 Secs"))
  Delay.PauseSec(1)
  
  status := Oled.JoystickWaitStatus(Oled#JoystickOptionWaitForPress, 5000)
  case status
    Oled#JoystickStatusTimeout:
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick time-out"))
    Oled#JoystickStatusUpPress:
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Up press"))
    Oled#JoystickStatusLeftPress:                                
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Left press"))
    Oled#JoystickStatusDownPress:
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Down press"))
    Oled#JoystickStatusRightPress:                                 
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Right press"))
    Oled#JoystickStatusFirePress:
      Fmt.sprintf(@strbuf, string("%s"), string("Joystick = Fire press"))
        
  Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  Delay.PauseSec(1) 
    
PRI TestSoundPlayNoteOrFrequency | octave

  DisplayTestTitle(string("SoundPlayNoteOrFrquency"), 1)
  Repeat octave from 1 to 84
    Oled.SoundPlayNoteOrFrequency(octave, 50)

PRI TestSoundPlayTune | index

  DisplayTestTitle(string("SoundPlayTune"), 1)  
  Repeat index from 0 to 9
    tune[2 * index] := (index + 1) * 1000
    tune[(2 * index) + 1] := 200 
  
  Oled.SoundPlayTune(@tune, 10)

PRI TestGraphicsAddDrawBitmap

  ' Add following bitmap character to memory:
  '
  ' [b7][b6][b5][b4][b3][b2][b1][b0]  Data Bits
  '               ‣   ‣                data1 (18 hex)
  '           ‣           ‣            data2 (24 hex)
  '       ‣                   ‣        data3 (42 hex)
  '   ‣                           ‣    data4 (81 hex)
  '   ‣                           ‣    data5 (81 hex)
  '       ‣                   ‣        data6 (42 hex)
  '           ‣           ‣            data7 (24 hex)
  '               ‣   ‣                data8 (18 hex)
  
  DisplayTestTitle(string("GraphicsAddDrawBitmap"), 1)
  Oled.GraphicsAddBitmap(0, $18, $24, $42, $81, $81, $42, $24, $18)
  Oled.GraphicsDrawBitmap(0, 20, 40, 255, 0, 0)
  Oled.GraphicsDrawBitmap(0, 28, 48, 0, 255, 0)
  Oled.GraphicsDrawBitmap(0, 36, 56, 0, 0, 255)
  Delay.PauseSec(1)

PRI TestGraphicsDrawCircle

  DisplayTestTitle(string("GraphicsDrawCircle"), 1)
  Oled.GraphicsDrawCircle(50, 50, 10, 255, 0, 0)  ' Red circle
  Oled.GraphicsDrawCircle(70, 70, 20, 0, 255, 0)  ' Green circle
  Oled.GraphicsDrawCircle(90, 90, 30, 0, 0, 255)  ' Blue circle
  Delay.PauseSec(1)

PRI TestGraphicsDrawTriangle

  DisplayTestTitle(string("GraphicsDrawTriangle"), 1)
  Oled.GraphicsDrawTriangle(10, 50, 0, 70, 20, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(30, 50, 30, 70, 50, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(80, 50, 60, 70, 80, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(20, 90, 0, 90, 10, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(50, 90, 30, 90, 30, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(80, 90, 60, 90, 80, 110, 0, 0, 255)
  Delay.PauseSec(1)

PRI TestGraphicsDrawImage | byte_cnt, color_mode, color, height, index, width, x, y

  DisplayTestTitle(string("GraphicsDrawImage"), 1)  

  x := 40
  y := 40
  width := 10
  height := 10

  Oled.TextDrawStrFixed(0, 5, Oled#TextFontSet5x7, 0, 255, 0, string("8 bit color mode"))   
  color_mode := Oled#GraphicsImageColorMode256
  byte_cnt := width * height

  color := $E0  ' Red    
  Repeat index from 0 to byte_cnt
    pixels[index] := color
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 50, width, height, color_mode, @pixels)
  Delay.PauseSec(1)

  color := $1C  ' Red    
  Repeat index from 0 to byte_cnt
    pixels[index] := color
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 50, width, height, color_mode, @pixels)
  Delay.PauseSec(1)

  color := $03  ' Red    
  Repeat index from 0 to byte_cnt
    pixels[index] := color
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 50, width, height, color_mode, @pixels)
  Delay.PauseSec(1)

  Oled.TextDrawStrFixed(0, 8, Oled#TextFontSet5x7, 0, 255, 0, string("16 bit color mode"))    
  color_mode := Oled#GraphicsImageColorMode65K
  byte_cnt := width * height * 2

  color := Oled#Rgb565Red
  Repeat index from 0 to byte_cnt step 2
    pixels[index] := color.byte[1]
    pixels[index + 1] := color.byte[0]
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 75, width, height, color_mode, @pixels)
  Delay.PauseSec(1)

  color := Oled#Rgb565Green
  Repeat index from 0 to byte_cnt step 2
    pixels[index] := color.byte[1]
    pixels[index + 1] := color.byte[0]
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 75, width, height, color_mode, @pixels)
  Delay.PauseSec(1)

  color := Oled#Rgb565Blue
  Repeat index from 0 to byte_cnt step 2
    pixels[index] := color.byte[1]
    pixels[index + 1] := color.byte[0]
  Repeat index from 0 to 157 step 13
    Oled.GraphicsDrawImage(index, 75, width, height, color_mode, @pixels)
  Delay.PauseSec(1)


PRI TestGraphicsSetBackgndColor

  DisplayTestTitle(string("GraphicsSetBackgndColor"), 2)
 
  Oled.GraphicsSetBackgndColor(0, 255, 0) ' Green
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("GREEN  "))
  Delay.PauseSec(1) 

  Oled.GraphicsSetBackgndColor(255, 255, 0) ' Yellow
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 0, 0, string("YELLOW "))
  Delay.PauseSec(1)  

  Oled.GraphicsSetBackgndColor(255, 0, 0) ' Red
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 0, 0, string("RED    "))
  Delay.PauseSec(1)

  Oled.GraphicsSetBackgndColor(0, 0, 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 0, 0, string("       "))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 0, 0, string("       "))
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 0, 0, string("       "))

PRI TestGraphicsDrawLine

  DisplayTestTitle(string("GraphicsDrawLine"), 1)
  Oled.GraphicsDrawLine(10, 50, 100, 50, 255, 0, 0)
  Delay.PauseSec(1)
  Oled.GraphicsDrawLine(100, 50, 10, 80, 0, 255, 0)
  Delay.PauseSec(1)
  Oled.GraphicsDrawLine(10, 80, 100, 80, 0, 0, 255)
  Delay.PauseSec(1)
  Oled.GraphicsDrawLine(100, 80, 10, 50, 255, 0, 0)
  Delay.PauseSec(1)
  Oled.GraphicsDrawLine(10, 50, 10, 80, 0, 255, 0)
  Delay.PauseSec(1)
  Oled.GraphicsDrawLine(100, 80, 100, 50, 0, 0, 255)
  Delay.PauseSec(1)

PRI TestGraphicsDrawPixel | index, x, y, red8, green8, blue8

  DisplayTestTitle(string("GraphicsDrawPixel"), 1)
  index := 0
  repeat x from 50 to 100 step 5
    case index
      0:
        red8 := 255
        green8 := 0
        blue8 := 0
      1:
        red8 := 0
        green8 := 255
        blue8 := 0
      2:
        red8 := 0
        green8 := 0
        blue8 := 255
    index := (index + 1) // 3
    repeat y from 50 to 100
      Oled.GraphicsDrawPixel(x, y, red8, green8, blue8)
  Delay.PauseSec(1)

PRI TestGraphicsReadPixel | index, x, xi, y, red8_in, green8_in, blue8_in, red8_out, green8_out, blue8_out, rgb565

  DisplayTestTitle(string("GraphicsReadPixel"), 1)
  x := 80
  y := 26
  
  repeat index from 0 to 2
  
    case index
      0:
        red8_out := 255
        green8_out := 0
        blue8_out := 0
        Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, string("Red Pixels: "))
      1:
        red8_out := 0
        green8_out := 255
        blue8_out := 0
        Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, string("Green Pixels: "))
      2:
        red8_out := 0
        green8_out := 0
        blue8_out := 255
        Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, string("Blue Pixels: "))
        
    repeat xi from x to (x + 10)
      Oled.GraphicsDrawPixel(xi, y, red8_out, green8_out, blue8_out)
          
    rgb565 := Oled.GraphicsReadPixel(x, y, @red8_in, @green8_in, @blue8_in)
    Fmt.sprintf(@strbuf, string("rgb565 = %x hex  "), rgb565)
    Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, @strbuf)
    Fmt.sprintf(@strbuf, string("red8_in = %x hex  "), red8_in)
    Oled.TextDrawStrFixed(0, 5, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, @strbuf)
    Fmt.sprintf(@strbuf, string("green8_in = %x hex  "), green8_in)
    Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, @strbuf)
    Fmt.sprintf(@strbuf, string("blue8_in = %x hex  "), blue8_in)
    Oled.TextDrawStrFixed(0, 7, Oled#TextFontSet5x7, red8_out, green8_out, blue8_out, @strbuf)
    Delay.PauseSec(4)

PRI TestGraphicsScreenCopyPaste | xs, ys, xd, yd, width, height

  DisplayTestTitle(string("GraphicsScreenCopyPaste"), 1)
  Oled.GraphicsDrawCircle(40, 40, 4, 0, 0, 255)  ' Blue circle
  xs := 30
  ys := 30
  xd := 32
  yd := 31
  repeat 66
    Oled.GraphicsScreenCopyPaste(xs, ys, xd, yd, 20, 20)
    xs += 2
    ys++
    xd += 2
    yd++

PRI TestGraphicsDrawPolygon | x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6, red8, green8, blue8

  DisplayTestTitle(string("GraphicsDrawPolygon"), 1)
  Oled.GraphicsDrawPolygon3(10, 30, 10, 50, 50, 30, 0, 255, 0)
  Delay.PauseSec(1)
  Oled.GraphicsDrawPolygon4(60, 30, 60, 50, 110, 50, 90, 30, 0, 0, 255)
  Delay.PauseSec(1)
  Oled.GraphicsDrawPolygon5(50, 70, 30, 80, 40, 90, 60, 90, 70, 80, 255, 255, 255)
  Delay.PauseSec(1)
  Oled.GraphicsDrawPolygon6(100, 70, 90, 80, 100, 90, 110, 90, 120, 80, 110, 70, 255, 0, 0)
  Delay.PauseSec(1)

PRI TestGraphicsReplaceColor

  DisplayTestTitle(string("GraphicsReplaceColor"), 1)
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawCircle(50, 80, 30, 0, 0, 255)  ' Blue circle
  Delay.PauseSec(1)
  Oled.GraphicsReplaceColor(40, 70, 60, 90, 0, 0, 255, 0, 255, 0)
  Delay.PauseSec(1)  
  
PRI TestGraphicsSetPenMode

  DisplayTestTitle(string("GraphicsSetPenMode"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Wire-frame Circles:"))
  Oled.GraphicsSetPenModeWireFrame 
  Oled.GraphicsDrawCircle(50, 50, 10, 255, 0, 0)  ' Red circle
  Oled.GraphicsDrawCircle(70, 70, 20, 0, 255, 0)  ' Green circle
  Oled.GraphicsDrawCircle(90, 90, 30, 0, 0, 255)  ' Blue circle
  Delay.PauseSec(2)
  
  DisplayTestTitle(string("GraphicsSetPenMode"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Solid Circles:"))
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawCircle(50, 50, 10, 255, 0, 0)  ' Red circle
  Oled.GraphicsDrawCircle(70, 70, 20, 0, 255, 0)  ' Green circle
  Oled.GraphicsDrawCircle(90, 90, 30, 0, 0, 255)  ' Blue circle
  Delay.PauseSec(2)

  DisplayTestTitle(string("GraphicsSetPenMode"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Wire-frame Triangles:"))
  Oled.GraphicsSetPenModeWireFrame   
  Oled.GraphicsDrawTriangle(10, 50, 0, 70, 20, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(30, 50, 30, 70, 50, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(80, 50, 60, 70, 80, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(20, 90, 0, 90, 10, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(50, 90, 30, 90, 30, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(80, 90, 60, 90, 80, 110, 0, 0, 255)
  Delay.PauseSec(2)
   
  DisplayTestTitle(string("GraphicsSetPenMode"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Solid Triangles:"))
  Oled.GraphicsSetPenModeSolid   
  Oled.GraphicsDrawTriangle(10, 50, 0, 70, 20, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(30, 50, 30, 70, 50, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(80, 50, 60, 70, 80, 70, 255, 0, 0)
  Oled.GraphicsDrawTriangle(20, 90, 0, 90, 10, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(50, 90, 30, 90, 30, 110, 0, 0, 255)
  Oled.GraphicsDrawTriangle(80, 90, 60, 90, 80, 110, 0, 0, 255)
  Delay.PauseSec(1)
 
PRI TestGraphicsDrawRectangle

  DisplayTestTitle(string("GraphicsDrawRectangle"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Wire-frame Rectangles:"))    
  Oled.GraphicsSetPenModeWireFrame
  Oled.GraphicsDrawRectangle(20, 50, 100, 100, 255, 0, 0)
  Oled.GraphicsDrawRectangle(30, 60, 90, 90, 0, 255, 0)
  Oled.GraphicsDrawRectangle(40, 70, 80, 80, 0, 0, 255) 
  Delay.PauseSec(2)
  
  DisplayTestTitle(string("GraphicsDrawRectangle"), 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Solid Rectangles:"))  
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawRectangle(20, 50, 100, 100, 255, 0, 0)
  Oled.GraphicsDrawRectangle(30, 60, 90, 90, 0, 255, 0)
  Oled.GraphicsDrawRectangle(40, 70, 80, 80, 0, 0, 255) 
  Delay.PauseSec(1)
  
PRI TestTextSetOpacity

  DisplayTestTitle(string("TextSetOpacity"), 1)
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawRectangle(20, 35, 140, 100, 255, 165, 0)
  Oled.TextSetTransparent
  Oled.TextDrawStrScaled(28, 50, Oled#TextFontSet8x12, 0, 0, 0, 1, 1, string("Transparent  ")) 
  Oled.TextSetOpaque
  Oled.GraphicsSetBackgndColor(255, 255, 255)   
  Oled.TextDrawStrScaled(28, 70, Oled#TextFontSet8x12, 0, 0, 0, 1, 1, string("  Opaque "))
  Oled.GraphicsSetBackgndColor(0, 0, 0) 
  Delay.PauseSec(1) 
  DisplaySetup(FALSE)

PRI TestTextDrawStrFixed

  DisplayTestTitle(string("TextDrawStrFixed"), 1)  
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet5x7, 0, 255, 255, string("! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"))
  Delay.PauseSec(2)
   
  DisplayTestTitle(string("TextDrawStrFixed"), 1)  
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawStrFixed(0, 4, Oled#TextFontSet8x8, 0, 255, 255, string("! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"))
  Delay.PauseSec(2)

  DisplayTestTitle(string("TextDrawStrFixed"), 1)
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet8x12, 0, 255, 255, string("! @ # $ % ^ & * ( ) _ + - = 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z { } [ ] | \ ; : ' < > ? , . /"))
  Delay.PauseSec(1)                                          

PRI TestTextDrawNumFixed

  DisplayTestTitle(string("TextDrawNumFixed"), 1)  
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawNumFixed(0, 4, Oled#TextFontSet5x7, 0, 255, 255, 65536)
  Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawNumFixed(0, 7, Oled#TextFontSet8x8, 0, 255, 255, 262144)
  Oled.TextDrawStrFixed(0, 9, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawNumFixed(0, 7, Oled#TextFontSet8x12, 0, 255, 255, 1048576)
  Delay.PauseSec(1)

PRI TestTextDrawCharFixed

  DisplayTestTitle(string("TextDrawCharFixed"), 1)  
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawCharFixed("A", 0, 4, Oled#TextFontSet5x7, 0, 255, 255)
  Oled.TextDrawCharFixed("B", 2, 4, Oled#TextFontSet5x7, 0, 255, 255)
  Oled.TextDrawCharFixed("C", 4, 4, Oled#TextFontSet5x7, 0, 255, 255) 
  Oled.TextDrawStrFixed(0, 6, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawCharFixed("A", 0, 7, Oled#TextFontSet8x8, 0, 255, 255)
  Oled.TextDrawCharFixed("B", 2, 7, Oled#TextFontSet8x8, 0, 255, 255)
  Oled.TextDrawCharFixed("C", 4, 7, Oled#TextFontSet8x8, 0, 255, 255) 
  Oled.TextDrawStrFixed(0, 9, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawCharFixed("A", 0, 7, Oled#TextFontSet8x12, 0, 255, 255)
  Oled.TextDrawCharFixed("B", 2, 7, Oled#TextFontSet8x12, 0, 255, 255)
  Oled.TextDrawCharFixed("C", 4, 7, Oled#TextFontSet8x12, 0, 255, 255) 
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestTextDrawStrScaled

  DisplayTestTitle(string("TextDrawStrScaled"), 1) 
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawStrScaled(0, 35, Oled#TextFontSet5x7, 0, 255, 255, 1, 1, string("W=1, H=1"))
  Oled.TextDrawStrScaled(0, 45, Oled#TextFontSet5x7, 0, 255, 255, 2, 2, string("W=2, H=2"))
  Delay.PauseSec(2)
   
  DisplayTestTitle(string("TextDrawStrScaled"), 1) 
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawStrScaled(0, 35, Oled#TextFontSet8x8, 0, 255, 255, 1, 1, string("W=1, H=1"))
  Oled.TextDrawStrScaled(0, 45, Oled#TextFontSet8x8, 0, 255, 255, 2, 2, string("W=2, H=2"))
  Delay.PauseSec(2)

  DisplayTestTitle(string("TextDrawStrScaled"), 1)
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawStrScaled(0, 35, Oled#TextFontSet8x12, 0, 255, 255, 1, 1, string("W=1, H=1"))
  Oled.TextDrawStrScaled(0, 45, Oled#TextFontSet8x12, 0, 255, 255, 2, 2, string("W=2, H=2"))
  Delay.PauseSec(1)   

PRI TestTextDrawNumScaled

  DisplayTestTitle(string("TextDrawNumScaled"), 1) 
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawNumScaled(0, 35, Oled#TextFontSet5x7, 0, 255, 255, 1, 1, 1)
  Oled.TextDrawNumScaled(0, 45, Oled#TextFontSet5x7, 0, 255, 255, 2, 2, 2)
  Delay.PauseSec(2)
   
  DisplayTestTitle(string("TextDrawNumScaled"), 1) 
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawNumScaled(0, 35, Oled#TextFontSet8x8, 0, 255, 255, 1, 1, 1)
  Oled.TextDrawNumScaled(0, 45, Oled#TextFontSet8x8, 0, 255, 255, 2, 2, 2)
  Delay.PauseSec(2)

  DisplayTestTitle(string("TextDrawNumScaled"), 1)
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawNumScaled(0, 35, Oled#TextFontSet8x12, 0, 255, 255, 1, 1, 1)
  Oled.TextDrawNumScaled(0, 45, Oled#TextFontSet8x12, 0, 255, 255, 2, 2, 2)
  Delay.PauseSec(1)

PRI TestTextDrawCharScaled

  DisplayTestTitle(string("TextDrawCharScaled"), 1) 
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, string("Font 0 (5x7):"))
  Oled.TextDrawCharScaled("1", 0, 35, Oled#TextFontSet5x7, 0, 255, 255, 1, 1)
  Oled.TextDrawCharScaled("2", 20, 35, Oled#TextFontSet5x7, 0, 255, 255, 2, 2)
  Oled.TextDrawStrFixed(0, 7, Oled#TextFontSet5x7, 0, 255, 0, string("Font 1 (8x8):"))
  Oled.TextDrawCharScaled("1", 0, 68, Oled#TextFontSet8x8, 0, 255, 255, 1, 1)
  Oled.TextDrawCharScaled("2", 20, 68, Oled#TextFontSet8x8, 0, 255, 255, 2, 2)
  Oled.TextDrawStrFixed(0, 11, Oled#TextFontSet5x7, 0, 255, 0, string("Font 2 (8x12):"))
  Oled.TextDrawCharScaled("1", 0, 98, Oled#TextFontSet8x12, 0, 255, 255, 1, 1)
  Oled.TextDrawCharScaled("2", 20, 98, Oled#TextFontSet8x12, 0, 255, 255, 2, 2)
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestTextDrawButton

  DisplayTestTitle(string("DemoTextButtons"), 1) 
  Oled.GraphicsSetPenModeSolid
  Oled.TextSetTransparent
  Oled.TextDrawButton(Oled#TextButtonStateUp, 5, 25, 200, 0, 0, Oled#TextFontSet5x7, 255, 255, 255, 1, 1, string(" FIRST "))
  Oled.TextDrawButton(Oled#TextButtonStateUp, 30, 49, 0, 200, 0, Oled#TextFontSet8x8, 255, 255, 255, 1, 1, string(" NEXT "))
  Oled.TextDrawButton(Oled#TextButtonStateUp, 5, 75, 0, 0, 200, Oled#TextFontSet8x12, 255, 255, 255, 2, 2, string(" LAST "))
  Delay.PauseSec(2)
   
  Oled.TextDrawButton(Oled#TextButtonStateDown, 5, 25, 200, 0, 0, Oled#TextFontSet5x7, 0, 0, 0, 1, 1, string(" FIRST "))
  Delay.PauseSec(1)
  Oled.TextDrawButton(Oled#TextButtonStateDown, 30, 49, 0, 200, 0, Oled#TextFontSet8x8, 0, 0, 0, 1, 1, string(" NEXT "))
  Delay.PauseSec(1)
  Oled.TextDrawButton(Oled#TextButtonStateDown, 5, 75, 0, 0, 200, Oled#TextFontSet8x12, 0, 0, 0, 2, 2, string(" LAST "))
  Delay.PauseSec(1)
  DisplaySetup(FALSE)

PRI TestDisplayScroll

  DisplayTestTitle(string("TestDisplayScroll"), 1)
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawRectangle(20, 50, 100, 100, 255, 0, 0)
  Oled.GraphicsDrawRectangle(30, 60, 90, 90, 0, 255, 0)
  Oled.GraphicsDrawRectangle(40, 70, 80, 80, 0, 0, 255)

  Oled.DisplayScrollControl(Oled#DisplayScrollLeft, Oled#DisplayScrollSpeedMin)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Slow left scroll"))
  Delay.PauseSec(2) 
  Oled.DisplayScrollEnable
  Delay.PauseSec(4) 
  Oled.DisplayScrollDisable
  Delay.PauseSec(1) 

  Oled.DisplayScrollControl(Oled#DisplayScrollLeft, Oled#DisplayScrollSpeedMax)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Fast left scroll"))
  Delay.PauseSec(2)  
  Oled.DisplayScrollEnable
  Delay.PauseSec(4) 
  Oled.DisplayScrollDisable
  Delay.PauseSec(1) 

  Oled.DisplayScrollControl(Oled#DisplayScrollRight, Oled#DisplayScrollSpeedMin)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Slow right scroll"))
  Delay.PauseSec(2) 
  Oled.DisplayScrollEnable
  Delay.PauseSec(4) 
  Oled.DisplayScrollDisable
  Delay.PauseSec(1) 

  Oled.DisplayScrollControl(Oled#DisplayScrollRight, Oled#DisplayScrollSpeedMax)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Fast right scroll"))
  Delay.PauseSec(2)  
  Oled.DisplayScrollEnable
  Delay.PauseSec(4) 
  Oled.DisplayScrollDisable
  Delay.PauseSec(1) 
  
PRI TestMemCardClearSectors(start_sector_addr, num_sectors) | index, sector_addr

  DisplayTestTitle(string("MemCardClearSectors"), 1)
    
  repeat index from 0 to (Oled#MemCardSectorSize - 1)
    sector_data[index] := $00
    
  Oled.TextDrawStrFixed(4, 2, Oled#TextFontSet8x12, 0, 255, 0, string("Clearing "))
  Oled.TextDrawStrFixed(4, 3, Oled#TextFontSet8x12, 0, 255, 0, string(" Sector  "))

  repeat sector_addr from start_sector_addr to (start_sector_addr + num_sectors)
    Oled.MemCardWriteSector(sector_addr, @sector_data)
    Oled.TextDrawNumScaled(30, 55, Oled#TextFontSet8x12, 0, 255, 255, 3, 3, sector_addr)

  Delay.PauseSec(1)

PRI TestMemCardWriteReadBytes(start_mem_addr, num_bytes) | count, data, match, mem_addr, str_index

  DisplayTestTitle(string("MemCardWriteReadBytes"), 1)
  str_index := Fmt.bprintf(@strbuf, 0, string("Writing %d bytes starting at memory address "), num_bytes)
  str_index := Fmt.bprintf(@strbuf, str_index, string("%d:"), start_mem_addr)
  strbuf[str_index] := 0
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  Oled.MemCardSetAddressPointer(start_mem_addr)
  data := 0
  mem_addr := start_mem_addr
  
  repeat count from 1 to num_bytes
    str_index := Fmt.bprintf(@strbuf, 0, string("byte %d [addr = "), count)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d] = "), mem_addr)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d  "), data)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 5, Oled#TextFontSet5x7, 0, 255, 255, @strbuf)
    Oled.MemCardWriteByte(data)
    mem_addr++
    data += 5
    Delay.PauseMSec(50)
    
  Delay.PauseSec(1)
  match := TRUE
  str_index := Fmt.bprintf(@strbuf, 0, string("Reading %d bytes starting at memory address "), num_bytes)
  str_index := Fmt.bprintf(@strbuf, str_index, string("%d:"), start_mem_addr)
  strbuf[str_index] := 0
  Oled.TextDrawStrFixed(0, 7, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  Oled.MemCardSetAddressPointer(start_mem_addr)
  mem_addr := start_mem_addr
   
  repeat count from 1 to num_bytes
    data := Oled.MemCardReadByte
    str_index := Fmt.bprintf(@strbuf, 0, string("byte %d [addr = "), count)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d] = "), mem_addr)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d  "), data)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 9, Oled#TextFontSet5x7, 0, 255, 255, @strbuf)
    mem_addr++ 
    if (data <> ((count - 1) * 5))
      match := FALSE
    Delay.PauseMSec(50) 
  
  if (match)
    Oled.TextDrawStrFixed(0, 12, Oled#TextFontSet5x7, 255, 255, 255, string("All bytes matched!"))
  else
    Oled.TextDrawStrFixed(0, 12, Oled#TextFontSet5x7, 255, 0, 0, string("At least one bytes did not match!"))  
  Delay.PauseSec(2)

PRI TestMemCardWriteReadSectors(start_sector_addr, num_sectors) | count, data, index, match, sector_addr, str_index

  DisplayTestTitle(string("MemCardWriteReadSectors"), 1)
  str_index := Fmt.bprintf(@strbuf, 0, string("Writing %d sectors starting at sector address "), num_sectors)
  str_index := Fmt.bprintf(@strbuf, str_index, string("%d:"), start_sector_addr)
  strbuf[str_index] := 0
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  data := 0
  sector_addr := start_sector_addr
        
  repeat count from 1 to num_sectors
    str_index := Fmt.bprintf(@strbuf, 0, string("sect %d [addr = "), count)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d] = "), sector_addr)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d "), data)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 5, Oled#TextFontSet5x7, 0, 255, 255, @strbuf)
    repeat index from 0 to (Oled#MemCardSectorSize - 1)
      sector_data[index] := data    
    Oled.MemCardWriteSector(sector_addr, @sector_data)
    sector_addr++   
    data += 5
    
  Delay.PauseSec(1)
  match := TRUE
  str_index := Fmt.bprintf(@strbuf, 0, string("Reading %d sectors starting at sector address "), num_sectors)
  str_index := Fmt.bprintf(@strbuf, str_index, string("%d:"), start_sector_addr)
  strbuf[str_index] := 0
  Oled.TextDrawStrFixed(0, 7, Oled#TextFontSet5x7, 0, 255, 0, @strbuf)
  sector_addr := start_sector_addr
  
  repeat count from 1 to num_sectors
    str_index := Fmt.bprintf(@strbuf, 0, string("sect %d [addr = "), count)
    str_index := Fmt.bprintf(@strbuf, str_index, string("%d]  "), sector_addr)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 9, Oled#TextFontSet5x7, 0, 255, 255, @strbuf)
    Oled.MemCardReadSector(sector_addr, @sector_data)
    sector_addr++ 
    repeat index from 0 to (Oled#MemCardSectorSize - 1)
      data := sector_data[index]
      if (data <> ((count - 1) * 5))
        match := FALSE

  if (match)
    Oled.TextDrawStrFixed(0, 12, Oled#TextFontSet5x7, 255, 255, 255, string("All sectors matched!"))
  else
    Oled.TextDrawStrFixed(0, 12, Oled#TextFontSet5x7, 255, 0, 0, string("At least one sector did not match!"))  
  Delay.PauseSec(2)

PRI TestMemCardSaveLoadImages(start_sector_addr) | image_num_bytes, image_num_sectors, image_sector_addr, image_sector_offset, index

  DisplayTestTitle(string("TestMemCardSaveLoadImages"), 1)
  image_num_bytes := 2 * (Oled#GraphicsPixelWidth * (Oled#GraphicsPixelHeight - 30))
  image_num_sectors := image_num_bytes / Oled#MemCardSectorSize 
  image_sector_offset := image_num_sectors + 1
  
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Drawing image 1:      "))  
  Oled.GraphicsSetPenModeSolid
  Oled.GraphicsDrawRectangle(0, 30, 159, 127, 255, 255, 255)
  Oled.GraphicsDrawRectangle(30, 70, 50, 90, 255, 0, 0)
  Oled.GraphicsDrawRectangle(70, 70, 90, 90, 0, 255, 0)
  Oled.GraphicsDrawRectangle(110, 70, 130, 90, 0, 0, 255)
  Delay.PauseSec(1)
  image_sector_addr := start_sector_addr
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Saving image 1 to uSD:"))
  Oled.MemCardSaveImage(0, 30, Oled#GraphicsPixelWidth, Oled#GraphicsPixelHeight - 30, image_sector_addr)

  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Drawing image 2:      "))  
  Oled.GraphicsDrawRectangle(0, 30, 159, 127, 255, 255, 255)
  Oled.GraphicsDrawCircle(40, 80, 10, 255, 0, 0) 
  Oled.GraphicsDrawCircle(80, 80, 10, 0, 255, 0)
  Oled.GraphicsDrawCircle(120, 80, 10, 0, 0, 255)
  Delay.PauseSec(1)   
  image_sector_addr += image_sector_offset
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Saving image 2 to uSD:"))
  Oled.MemCardSaveImage(0, 30, Oled#GraphicsPixelWidth, Oled#GraphicsPixelHeight - 30, image_sector_addr)

  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Drawing image 3:      "))  
  Oled.GraphicsDrawRectangle(0, 30, 159, 127, 255, 255, 255)
  Oled.GraphicsDrawTriangle(40, 70, 30, 90, 50, 90, 255, 0, 0)
  Oled.GraphicsDrawTriangle(80, 70, 70, 90, 90, 90, 0, 255, 0)
  Oled.GraphicsDrawTriangle(120, 70, 110, 90, 130, 90, 0, 0, 255)
  Delay.PauseSec(1) 
  image_sector_addr += image_sector_offset
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Saving image 3 to uSD:"))
  Oled.MemCardSaveImage(0, 30, Oled#GraphicsPixelWidth, Oled#GraphicsPixelHeight - 30, image_sector_addr)
  
  repeat 2
    image_sector_addr := start_sector_addr
    repeat index from 0 to 2
      case index
        0:
          Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Loading image 1 from uSD:"))
        1:
          Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Loading image 2 from uSD:"))
        2:
          Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Loading image 3 from uSD:"))
      Oled.MemCardLoadImage(0, 30, Oled#GraphicsPixelWidth, Oled#GraphicsPixelHeight - 30, Oled#GraphicsImageColorMode65K, image_sector_addr)
      Delay.PauseSec(1)        
      image_sector_addr += image_sector_offset 
      
  DisplaySetup(FALSE)
    
PRI TestBuildScriptOnSD(script_start_sector_addr) | cmd, color_rgb565, delay_msecs, radius, script_addr, x, y  
  
  script_addr := script_start_sector_addr * Oled#MemCardSectorSize 
  Oled.MemCardSetAddressPointer(script_addr)

  cmd := Oled#GsgcGraphicsDrawCircle
  x := 40
  y := 80
  radius := 10
  color_rgb565 := Oled.Red8Blue8Green8_To_Rgb565(255, 0, 0) 
  Oled.MemCardWriteByte(cmd)
  Oled.MemCardWriteByte(x)
  Oled.MemCardWriteByte(y)
  Oled.MemCardWriteByte(radius)
  Oled.MemCardWriteByte(color_rgb565.byte[1])
  Oled.MemCardWriteByte(color_rgb565.byte[0])  

  delay_msecs := 1000
  Oled.MemCardWriteByte(Oled#GsgcScriptDelay)
  Oled.MemCardWriteByte(delay_msecs.byte[1])
  Oled.MemCardWriteByte(delay_msecs.byte[0])
  
  x := 80
  color_rgb565 := Oled.Red8Blue8Green8_To_Rgb565(0, 255, 0)
  Oled.MemCardWriteByte(cmd)
  Oled.MemCardWriteByte(x)
  Oled.MemCardWriteByte(y)
  Oled.MemCardWriteByte(radius)
  Oled.MemCardWriteByte(color_rgb565.byte[1])
  Oled.MemCardWriteByte(color_rgb565.byte[0])

  Oled.MemCardWriteByte(Oled#GsgcScriptDelay)
  Oled.MemCardWriteByte(delay_msecs.byte[1])
  Oled.MemCardWriteByte(delay_msecs.byte[0])

  x := 120
  color_rgb565 := Oled.Red8Blue8Green8_To_Rgb565(0, 0, 255)
  Oled.MemCardWriteByte(cmd)
  Oled.MemCardWriteByte(x)
  Oled.MemCardWriteByte(y)
  Oled.MemCardWriteByte(radius)
  Oled.MemCardWriteByte(color_rgb565.byte[1])
  Oled.MemCardWriteByte(color_rgb565.byte[0])

  Oled.MemCardWriteByte(Oled#GsgcScriptDelay)
  Oled.MemCardWriteByte(delay_msecs.byte[1])
  Oled.MemCardWriteByte(delay_msecs.byte[0])

  Oled.MemCardWriteByte(Oled#GsgcScriptExit)

PRI TestMemCardRunObject(obj_sector_addr) | obj_addr

  DisplayTestTitle(string("TestMemCardRunObject"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Red circle drawn from uSD:"))
  obj_addr := obj_sector_addr * Oled#MemCardSectorSize
  Oled.MemCardRunObject(obj_addr)
  Delay.PauseSec(3) 
  
PRI TestMemCardRunScript(script_start_sector_addr) | script_addr

  DisplayTestTitle(string("TestMemCardRunScript"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("Red, green, blue circles drawn from uSD:"))
  Delay.PauseSec(1)    
  script_addr := script_start_sector_addr * Oled#MemCardSectorSize
  Oled.MemCardRunScript(script_addr)
  Delay.PauseSec(5)  ' Need to wait long enough for script to execute and exit 

PRI TestMemCardDisplayVideo(video_start_sector_addr) | delay_msecs, num_images, height, image_sector_offset, index, str_index, video_sector_addr, width, xpos

  DisplayTestTitle(string("TestMemCardDisplayVideo"), 1)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("< Building video on uSD >"))
  Oled.GraphicsSetPenModeSolid
  delay_msecs := 50
  num_images := 12
  width := 128
  height := 64
  xpos := 35
  video_sector_addr := video_start_sector_addr
  image_sector_offset := (2 * width * height) / Oled#MemCardSectorSize

  repeat index from 1 to num_images
    str_index := Fmt.bprintf(@strbuf, 0, string("Drawing image %d:      "), index)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 0, 255, @strbuf)
    Oled.GraphicsDrawRectangle(15, 64, 142, 127, 0, 0, 255)
    Oled.GraphicsDrawCircle(xpos, 96, 10, 255, 255, 0)
    Delay.PauseMSec(250)
    str_index := Fmt.bprintf(@strbuf, 0, string("Saving image %d to uSD:"), index)
    strbuf[str_index] := 0
    Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 0, 255, @strbuf)
    Oled.MemCardSaveImage(0, 64, width, height, video_sector_addr)
    video_sector_addr += image_sector_offset
    xpos += 5

  Oled.GraphicsDrawRectangle(15, 64, 142, 127, 0, 0, 0)
  Oled.TextDrawStrFixed(0, 2, Oled#TextFontSet5x7, 0, 255, 0, string("< Running video from uSD >"))
  Oled.TextDrawStrFixed(0, 3, Oled#TextFontSet5x7, 0, 0, 0, string("                       "))
  Delay.PauseSec(1)
  Oled.MemCardDisplayVideo(0, 64, width, height, Oled#GraphicsImageColorMode65K, delay_msecs, num_images, video_start_sector_addr)
  Delay.PauseSec(2) 
  DisplaySetup(FALSE)
  
PRI TestShutdown

  Oled.TextDrawStrFixed(8, 1, Oled#TextFontSet5x7, 255, 255, 255, string("Shutdown in:"))
  Oled.TextDrawCharScaled("5", 80, 30, Oled#TextFontSet8x12, 0, 255, 0, 2, 2)
  Oled.TextDrawStrFixed(3, 8, Oled#TextFontSet5x7, 255, 255, 0, string("Restart in 10 seconds"))
  Delay.pauseSec(1)
  
  Oled.TextDrawCharScaled("4", 80, 30, Oled#TextFontSet8x12, 0, 255, 0, 2, 2) 
  Delay.pauseSec(1)
  Oled.TextDrawCharScaled("3", 80, 30, Oled#TextFontSet8x12, 255, 255, 0, 2, 2) 
  Delay.pauseSec(1)
  Oled.TextDrawCharScaled("2", 80, 30, Oled#TextFontSet8x12, 255, 255, 0, 2, 2) 
  Delay.pauseSec(1)
  Oled.TextDrawCharScaled("1", 80, 30, Oled#TextFontSet8x12, 255, 0, 0, 2, 2) 
  Delay.PauseSec(1)
  Oled.TextDrawCharScaled("0", 80, 30, Oled#TextFontSet8x12, 255, 0, 0, 2, 2)
  
  Oled.TextDrawStrFixed(2, 11, Oled#TextFontSet5x7, 0, 255, 0, string("Safe to turn power off"))
  Oled.TextDrawStrFixed(2, 12, Oled#TextFontSet5x7, 0, 255, 0, string(" after screen clears!")) 
  Delay.PauseSec(4)
  Oled.DisplayClearScreen
  Delay.PauseMSec(20)    
  Oled.DisplaySetPowerOff
  Delay.PauseSec(10)
  Oled.DisplaySetPowerOn

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