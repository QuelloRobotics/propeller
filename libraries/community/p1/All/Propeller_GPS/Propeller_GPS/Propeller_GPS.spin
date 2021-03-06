{{
*****************************
*    Propeller_GPS  v 1.0   *
*   Author:  L. Wendell     *
*      3DogPottery.Com      *
*****************************
v1.0 - 3/28/2019 - original version

    You can make your own GPS unit with a Parallax Propeller and two
    very inexpensive modules that are available on eBay for about
    eight dollars each.  Specifically, the NEO-7M Satallite
    Positioning Module and the I2C 128 x 64 OLED.  The OLED uses the
    SSD1306 controller.  

 
      CONNECTIONS

      NEO-7M GPS Satellite Positioning Module    
      GND   to     GND
      VDD   to     3.3 Volts
      TXD   to     Propeller P0  (input)
      RXD   to     Propeller P1  (Not Used)

 
      I2C IIC Serial 128X64 128*64 OLED  
      Gnd   to     Gnd
      VCC   to     3.3 Volts
      SCL   to     Propeller P2
      SDA   to     Propeller P3

}}
CON
  _clkmode = xtal1 + pll16x    'pLL16x means Multiply chrystal freq. by 16
  _xinfreq = 5_000_000

  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq     'This calculates the clock frequency to obtain
  _Ms_001   = _ConClkFreq / 1_000                        'the correct constant for milliseconds

    LF  = 10    'Line Feed                     
    CR  = 13    'Carriage Return                   
    CLS = 16    'Screen Clear


  ''NEO-7M GPS Satellite Positioning Module
    GPS_RX = 0      '<--------------- Change these to the Propeller pins 
    GPS_TX = 1      '                 you would like to use.
   
  '' I2C IIC Serial 128X64 128*64 OLED  
    SCL = 2         '<--------------- Change these to the Propeller pins 
    SDA = 3         '                 you would like to use.

  ''Time Offset to Convert from UTC to Your Local Time
    OffSet = 7.0    '<--------------- This is the offset for the Pacific Time Zone
                    '                 Change this to YOUR Time Zone Offset.

OBJ
   F32:      "F32_1_6"                  'Math Engine                                                                             
   GPS:      "FullDuplexSerialPlus"     'GPS Modual Communications 
   FS:       "FloatString-v1_2"         'Float to String library

VAR
   byte GPS_Char, PM                    '
   long StringData, NorthDeg_F, NorthMin_F, WestDeg_F, WestMin_F
   long Hours_F, Minutes_F, Seconds_F, Speed_F, Altitude_F
   byte characterToStringPointer, characterToString[255]
                                             
PUB Main 

'********* Configuration ****************************************************************

 ''Start Serial Communications with GPS Unit
   gps.Start(GPS_RX, GPS_TX, 0, 9600)
                                
 ''Start Math Object 
   F32.start  

   Initialize(SCL)        'Wake UP OLED
   Pause(100)
   OLED_Init              'Initalize OLED     
   Pause(100)
   OLED_Clear             'Clear the OLED Screen
  
'********* Main Loop ******************************************************************** 

   repeat
      GPS_Char := gps.rx             'Get a character
      if GPS_Char == "$"             'Is it a dollar sign
         repeat 3                    'Discard following G and P and fetch 4th character
            GPS_Char := gps.rx         
         if GPS_Char == "R"          'Check for "R"
            repeat until gps.rx == ","
          '********* Time ****************************************************************
            repeat 2                  'Get Hours
               buildString(gps.rx)    
            StringData := builtString(True)  
            Hours_F := F32.FSub(F32.atof(StringData), OffSet)  'Convert to Local Time
             if F32.FCmp(0.0, Hours_F) == 1                 'Check for negative time...
              Hours_F := F32.FAdd(Hours_F, 24.0)           'if so, add 24 hours
            PM := F32.FCmp(Hours_F, 12.0)
            if PM == 1
               Hours_F := F32.FSub(Hours_F, 12.0)
            repeat 2                                        'Get Minutes
               buildString(gps.rx)    
            StringData := builtString(True)  
            Minutes_F := F32.atof(StringData)
            repeat 2                                        'Get Seconds
               buildString(gps.rx)    
            StringData := builtString(True)  
            Seconds_F := F32.atof(StringData)
             repeat 2                                       'Skip 2 commas
                repeat until gps.rx == ","
          '********* North Latitude ******************************************************
            repeat 2            'Get North Latitude degrees            
               buildString(gps.rx)    
            StringData := builtString(True) 
            NorthDeg_F := F32.atof(StringData)    'Conveert North Latitude Deg to Float
            repeat 8                              'Get North Latitude Minutes            
               buildString(gps.rx)    
            StringData := builtString(True) 
            NorthMin_F := F32.atof(StringData)    'Conveert North Latitude Minutes to Float
          '********* Westh Longitude **************************************************** 
             repeat 2                             'Skip 2 commas
                repeat until gps.rx == ","
            repeat 3                              'Get West Longitude Minutes            
               buildString(gps.rx) 
            StringData := builtString(True)   
            WestDeg_F := F32.atof(StringData)     'Convert West Longitude Deg to Float
            repeat 8                              'Get West Longitude Minutes            
               buildString(gps.rx)    
            StringData := builtString(True) 
            WestMin_F := F32.atof(StringData)     'Conveert North Latitude Minutes to Float
          '********* Speed ***************************************************************
             repeat 2                             'Skip 2 commas
                repeat until gps.rx == ","
            repeat 5                              'Get North Latitude Minutes            
               buildString(gps.rx)    
            StringData := builtString(True) 
            Speed_F := F32.FloatRound(F32.FMul(F32.atof(StringData), 1.15078))   'Speed in MPH  Rounded **
            repeat until GPS.rx == CR             'Discarde remaining char until carriage return  
          '********* Orthometric Height **************************************************  
         elseif gps.rx =="G"
            repeat 9                              'Skip 9 commas
                  repeat until gps.rx == ","
            repeat until GPS_Char == ","
               GPS_Char := gps.rx
               buildString(GPS_Char)
            StringData := builtString(True)
            Altitude_F := F32.FloatRound(F32.FMul(F32.atof(StringData), 3.28284)) 'Altitude in Feet Rounded **
            repeat until gps.rx == CR              'Discarde remaining char until carriage return
            Print

PRI Print  

    Start(SCL)                       'Print Time
    Write(SCL, $78)       
    Page_Addressing 
    Page(0)
    Write(SCL, $40)   
    str(String("    PROPELLER GPS"))
    Stop(SCL) 

    Start(SCL)                       'Print Time
    Write(SCL, $78)       
    Page_Addressing 
    Page(2)
    Write(SCL, $40)   
    str(String("TIME: "))
    str(FS.floattostring(Hours_F))     
    str(String(":"))
    str(FS.floattostring(Minutes_F))                     
    str(String(":"))
    str(FS.floattostring(Seconds_F))     
       if PM == 1                                         
          str(String(" PM"))
       else
          str(String(" AM"))   
    Stop(SCL) 

    Start(SCL)                       'Print Latitude  
    Write(SCL, $78)
    Page_Addressing
    Page(3)
    Write(SCL, $40)             
    str(String("LAT:"))             
    str(FS.floattostring(NorthDeg_F))
    str(String(" DEG "))   
    str(FS.floattoformat(NorthMin_F, 5, 2))  
    str(String(" MIN")) 
    Stop(SCL)

    Start(SCL)                       'Print Longitude
    Write(SCL, $78)
    Page_Addressing
    Page(4)                               
    str(String("LON:"))              
    str(FS.floattostring(WestDeg_F))  
    str(String(" DEG "))   
    str(FS.floattoformat(WestMin_F, 5, 2))
    str(String(" MIN"))
    Stop(SCL)

    Start(SCL)                       'Print Speed 
    Write(SCL, $78)
    Page_Addressing
    Page(5)                              
    Write(SCL, $40)
    str(String("SPEED: "))
    str(FS.floattostring(Speed_F))
    str(String(" MPH")) 
    Stop(SCL)

    Start(SCL)                       'Print Altitude
    Write(SCL, $78)
    Page_Addressing
    Page(6)                                 
    Write(SCL, $40)
    str(String("ALT: "))
    str(FS.floattostring(Altitude_F))
    str(String(" FEET"))  
    Stop(SCL)

    Start(SCL)                       'Print Time
    Write(SCL, $78)       
    Page_Addressing 
    Page(7)
    Write(SCL, $40)   
    str(String("           L. WENDELL"))
    Stop(SCL) 



PRI OLED_Clear | _i
  Start(SCL)
  Write(SCL, $78)     'Address with Write Bit             
  Horizontal_Addressing
  Write(SCL, $40)     'Control Byte Data     'All following information data only. All data will be stored on GDDRAM 
                                                 'and the column address pointer will be increased by one after each write.
  repeat _i from 0 to 1023                  
     Write(SCL, $00)                          'Since Page Addressing Mode was selected (above), the column address pointer 
                                                 'is incremented by 1 until it reaches the column end addrss. The column 
  Stop(SCL)                                  'address pointer is then reset to the column start address. Users have to set 
  return                                         'the new page and column addresses in order to access the next page RAM content.
  
PRI OLED_Init | ackBit
                         
  Start(SCL)       'Drives Data Low while Clock is High

  repeat                          
     ackBit := 0
     ackBit += Write(SCL, $78)   'Address with Write Bit
  while ackbit > 0
    
''Software Initiation Commands                                                                       
        
  ackBit := 0                   ''Turn Display Off 
  repeat                         'Display is turned ON
     ackBit := 0
     ackBit += Write(SCL, $80)   'Display Off = $AE  Display On = $AF           
     ackBit += Write(SCL, $AE)   'RESET Value = $AE                
  while ackBit > 0
   
  repeat                        ''Set Oscillator Frequency      
     ackBit := 0
     ackBit += Write(SCL, $80)   'Set display clock divide ratio. Dclock = Focs/D                     
     ackBit += Write(SCL, $D5)   
     ackBit += Write(SCL, $80)
     ackBit += Write(SCL, $80)   'RESET Value = $80  (1 - 16 = $00 to $8F)
  while ackBit > 0

  repeat                        ''Set Multiplex Ratio.  Here, it is set to 63 (N + 1).   
     ackBit := 0
     ackBit += Write(SCL, $80)   'i.e., the second byte following the command = 63.  
     ackBit += Write(SCL, $A8)   'RAM locations 0 to 63 will be multiplexed to the display. 
     ackBit += Write(SCL, $80)   '  
     ackBit += Write(SCL, $3F)   'RESET Value = $3F = 64MUX ($3F + 1) = 64.  64 coms will be switched.
  while ackBit > 0                                                                                       

  repeat                        ''Set Display Offset 
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command 
     ackBit += Write(SCL, $D3)   'Shift from 0 to 63 Com's      
     ackBit += Write(SCL, $80)
     ackBit += Write(SCL, $00)   'RESET Value = $00
  while ackBit > 0
  
  repeat                        ''Set Start Line Address                                    
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command
     ackBit += Write(SCL, $40)   'RESET Value = $40
  while ackBit > 0
                  
  repeat                        ''Set Charge Pump Regulator  
     ackBit := 0
     ackBit += Write(SCL, $80)   'Charge Pump Setting
     ackBit += Write(SCL, $8D)   'Enable charge pump during display On 
     ackBit += Write(SCL, $80)   
     ackBit += Write(SCL, $14)   'RESET Value + $10 Charge Pump Disabled
  while ackBit > 0
                 
  repeat                        ''Set Segment Re-Map   
     ackBit := 0
     ackBit += Write(SCL, $80)   'Column address 127 is mapped to SEG0.   
     ackBit += Write(SCL, $A1)   'This flips the memory image horizontally.  
    'ackBit += Write(SCL, $A0)   'RESET Value = $A0
  while ackBit > 0
  
  repeat                       ''Set Com Output Scan Direction 
     ackBit := 0
     ackBit += Write(SCL, $80)  'Scan from COM[N-1] to COM0 Where N is the Multiplex ratio.        
     ackBit += Write(SCL, $C8)  'Set to Remap Mode $C8   
   'ackBit += Write(SCL, $C0)   'RESET Value = $C0
  while ackBit > 0
                               ''Set COM pins hardware onfiguration.          ** For Accomidating to Hardware Config of OLED Screen **
  repeat                         'Setting here is RESET, i.e.,                 $02 = 00   Sequential  Com Pin Config & Disable L/R Remap                   
     ackBit := 0
     ackBit += Write(SCL, $80)   'Setting here is RESET, i.e.,                 $12 = 01   Alternative Com Pin Config & Disable L/R Remap  
     ackBit += Write(SCL, $DA)   'and Disable COM Left to Right.               $22 = 10   Sequential  Com Pin Config & Enable  L/R Remap 
     ackBit += Write(SCL, $80)   '                                             $32 = 11   Alternative Com Pin Config & Enable  L/R Remap
     ackBit += Write(SCL, $12)   'RESET Value = $12
  while ackBit > 0                                   
                   
  repeat                        ''Set Contrast Control  
     ackBit := 0
     ackBit += Write(SCL, $80)   'Set Contrast Control Register
     ackBit += Write(SCL, $81)   'Settings are from 1 t 256
     ackBit += Write(SCL, $80)
     ackBit += Write(SCL, $7F)   'RESET Value = $7F
  while ackBit > 0
                       
  repeat                        ''Set Pre-charge Period for Phase 1 and Phase 2 
     ackBit := 0
     ackBit += Write(SCL, $80)   'Lower Nybble sets Phase 1 period from 1 to 15. Reset = $02  
     ackBit += Write(SCL, $D9)   'Upper Nubble sets Phase 2 period from 1 t 15.  Reset = $02
     ackBit += Write(SCL, $80)   '
     ackBit += Write(SCL, $22)   'RESET Value = #22
  while ackBit > 0
                 
  repeat                        ''Entire Display On   
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command    '$A4: Display on and follows GDDRAM
     ackBit += Write(SCL, $A4)   'RESET Value = $A4       '$A5: Display on and does not follow GDDRAM
  while ackBit > 0
                  
  repeat                        ''Set Normal or Inverse Display   
     ackBit := 0                 '$A6 = Normal Display 
     ackBit += Write(SCL, $80)   '$A7 = Negative of RAM Contents
     ackBit += Write(SCL, $A6)   'RESET Value = $A6   
  while ackBit > 0
  
  repeat                         ''Adjust the VCOMH regulator output
     ackBit := 0
     ackBit += Write(SCL, $80)    'Control Byte Command
     ackBit += Write(SCL, $DB)   
     ackBit += Write(SCL, $80)
     ackBit += Write(SCL, $30)    '~0.83*vref
  while ackBit > 0
                   
  repeat                        ''Deactivate Scroll   <------- Not needed? 
     ackBit := 0
     ackBit += Write(SCL, $80)   
     ackBit += Write(SCL, $2E)      
  while ackBit > 0
                  
  repeat                         ''Turn Display On   
     ackBit := 0                  'Display is turned ON   
     ackBit += Write(SCL, $80)    'Display Off = $AE  Display On = $AF           
     ackBit += Write(SCL, $AF)    'RESET Value = $AE                
  while ackBit > 0
  
  Stop(SCL)
  return

PRI Horizontal_Addressing | ackBit
  repeat                       ''Set Addressing Mode to Horizontal 
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command       
     ackBit += Write(SCL, $20)   'Addressng Mode Command
     ackBit += Write(SCL, $80)   ' 
     ackBit += Write(SCL, $00)   'Set Addressing Mode to Horizontal   
  while ackBit > 0
  
   repeat                        ''Set Column Addresses for Horizontal Mode 
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command       
     ackBit += Write(SCL, $21)   'Set Column Address Command 
     ackBit += Write(SCL, $80)   ' 
     ackBit += Write(SCL, $00)   'Set Column Start to 0   
     ackBit += Write(SCL, $80)   ' 
     ackBit += Write(SCL, $7F)   'Set Column End to 127  
   while ackBit > 0
   
  repeat                        ''Set Page Start and Page End for Horizontal Mode 
     ackBit := 0
     ackBit += Write(SCL, $80)   'Control Byte Command       
     ackBit += Write(SCL, $22)   'Page Start and End Command Command 
     ackBit += Write(SCL, $80)   ' 
     ackBit += Write(SCL, $00)   'Set Page Start to 0   
     ackBit += Write(SCL, $80)   ' 
     ackBit += Write(SCL, $07)   'Set Page End to 7  
  while ackBit > 0
  return      

PRI Page_Addressing | ackBit
                     
  repeat                         ''Set Addressing Mode 
     ackBit := 0
     ackBit += Write(SCL, $80)    'Control Byte Command       
     ackBit += Write(SCL, $20)    'Set Memory Addressing Mode
     ackBit += Write(SCL, $80)    ' 
     ackBit += Write(SCL, $10)    'Page Addressing Mode Selected. RESET Value = $10 (Page Addressing Mode)  
  while ackBit > 0
                       
  repeat                          ''Set the Lower and Upperstart Column Address  
     ackBit := 0
     ackBit += Write(SCL, $80)     'Control Byte Command 
     ackBit += Write(SCL, $00)     'Set the lower nybble start column address ($00 to $0F)
     ackBit += Write(SCL, $80)     '
     ackBit += Write(SCL, $10)     'Set the upper nybble start column address ($10 to $1F)
  while ackBit > 0
  return                                                                                                                                                                        

PRI Page(PageNum) | Char, ackBit  ''Select Page (Segment)
   case PageNum 
      0 : Char := $B0
      1 : Char := $B1
      2 : Char := $B2
      3 : Char := $B3
      4 : Char := $B4
      5 : Char := $B5
      6 : Char := $B6
      7 : Char := $B7
  
  ackBit := 1
   repeat                
      ackBit := 0
      ackBit := Write(SCL, $80)   
      ackBit := Write(SCL, Char)   
   while ackBit > 0
   
PRI Pause(ms) | _t
 ''Delay program ms milliseconds
   _t := cnt - 1088                   'Sync with system counter
   repeat (ms #> 0)                  'Delay must be > 0
      waitcnt(_t += _MS_001)

PRI str(stringptr)              
''Sends zero terminated string.
   repeat strsize(stringptr)
      tx(byte[stringptr++])

PRI tx(char)
''Character Lookup     
   case char
      "0".."9":                      
         SendByte(@Zero[(char - "0") * 6]) 
      "A".."Z":
         SendByte(@A[(char - "A") * 6])
      " ": SendByte(@Space)
      ":": SendByte(@Colon)
      ".": SendByte(@Period)
      "&": SendByte(@Ampsnd)
      ",": SendByte(@Comma)
      "+": SendByte(@Plus)
      "-": SendByte(@Minus)
          
PRI SendByte(char) | _x
''Sends a Character to the OLED Panel
    repeat _x from 0 to 5 
       Write(SCL, BYTE[char][_x])
    return

PUB buildString(character) '' 4 Stack longs
   ifnot(characterToStringPointer)
      bytefill(@characterToString, 0, 255)
   if(characterToStringPointer and (character == 8))
      characterToString[--characterToStringPointer] := 0
   elseif(character and (characterToStringPointer <> 254))
      characterToString[characterToStringPointer++] := character

PUB builtString(resetString) '' 4 Stack Longs
   characterToStringPointer &= not(resetString)
   return @characterToString

PRI Initialize(SCL_Pin) | SDA_Pin             
    SDA_Pin := SCL_Pin + 1                   
    outa[SCL_Pin] := 1                      
   dira[SCL_Pin] := 1                  
   dira[SDA_Pin] := 0                   
   repeat 9                        
      outa[SCL_Pin] := 0               
      outa[SCL_Pin] := 1              
      if ina[SDA_Pin]                      
         quit                          

PRI Start(SCL_Pin) | SDA_Pin                  
    SDA_Pin := SCL_Pin + 1                      
    outa[SCL_Pin]~~                        
    dira[SCL_Pin]~~                       
    outa[SDA_Pin]~~                           
    dira[SDA_Pin]~~                         
    outa[SDA_Pin]~                         
    outa[SCL_Pin]~                      
  
PRI Stop(SCL_Pin) | SDA_Pin                    
    SDA_Pin := SCL + 1
    outa[SCL]~~                        
    outa[SDA]~~                        
    dira[SCL]~                        
    dira[SDA]~                         

PRI Write(SCL_Pin, data) : ackbit | SDA_Pin       
    SDA_Pin := SCL_Pin + 1
    ackbit := 0 
    data <<= 24
    repeat 8                           
       outa[SDA_Pin] := (data <-= 1) & 1   
       outa[SCL_Pin]~~                      
       outa[SCL_Pin]~
    dira[SDA_Pin]~                         
    outa[SCL_Pin]~~
    ackbit := ina[SDA_Pin]                 
    outa[SCL_Pin]~
    outa[SDA_Pin]~                         
    dira[SDA_Pin]~~

DAT

   ''Characters for OLED Screen (5x8 characters)
      Zero   byte  $3E, $41, $41, $41, $3E, $00
      One    byte  $00, $42, $7F, $40, $00, $00 
      Two    byte  $72, $49, $49, $49, $4E, $00
      Three  byte  $22, $41, $49, $49, $36, $00
      Four   byte  $08, $0C, $0A, $7F, $08, $00
      Five   byte  $27, $45, $45, $45, $39, $00
      Six    byte  $3E, $49, $49, $49, $32, $00
      Seven  byte  $01, $01, $71, $09, $07, $00
      Eight  byte  $36, $49, $49, $49, $36, $00
      Nine   byte  $26, $49, $49, $49, $36, $00

      Period byte  $00, $00, $00, $60, $60, $00
      Comma  byte  $50, $30, $00, $00, $00, $00
      Space  byte  $00, $00, $00, $00, $00, $00
      Colon  byte  $00, $14, $00, $00, $00, $00
      Ampsnd byte  $36, $49, $55, $22, $50, $00
      Plus   byte  $08, $08, $3E, $08, $08, $00
      Minus  byte  $08, $08, $08, $08, $00, $00

      A      byte  $7E, $09, $09, $09, $7E, $00
      B      byte  $7f, $49, $49, $49, $36, $00
      C      byte  $3E, $41, $41, $41, $22, $00
      D      byte  $7F, $41, $41, $41, $3E, $00
      E      byte  $7F, $49, $49, $49, $41, $00
      F      byte  $7F, $09, $09, $09, $01, $00
      G      byte  $3E, $49, $49, $49, $3A, $00
      H      byte  $7F, $08, $08, $08, $7F, $00
      I      byte  $00, $41, $7F, $01, $00, $00
      J      byte  $30, $40, $40, $40, $3F, $00
      K      byte  $7F, $08, $14, $22, $41, $00
      L      byte  $7F, $40, $40, $40, $40, $00
      M      byte  $7F, $02, $04, $02, $7F, $00
      N      byte  $7f, $02, $08, $20, $7f, $00
      O      byte  $3E, $41, $41, $41, $3E, $00
      P      byte  $7F, $09, $09, $09, $06, $00
      Q      byte  $3E, $41, $41, $41, $5E, $00
      R      byte  $7F, $09, $09, $09, $76, $00
      S      byte  $26, $49, $49, $49, $32, $00
      T      byte  $01, $01, $7F, $01, $01, $00
      U      byte  $3F, $40, $40, $40, $3F, $00
      V      byte  $1F, $20, $40, $20, $1F, $00
      W      byte  $7F, $20, $10, $20, $7F, $00
      X      byte  $63, $14, $08, $14, $63, $00
      Y      byte  $03, $04, $78, $04, $03, $00
      Z      byte  $61, $51, $49, $45, $43, $00

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