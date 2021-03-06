{
  Another Google Earth KML Logger V1.2

  See end of file for terms of use.

  based upon:
  Google Earth KML Logger V1.0
  www.pnav.net
  paul@hubner.net
  
  Modified by Walter T. Mosscrop, prophead@wmosscrop.com to:
  * Uses MAX 6957 (I/O expansion for a demo board)...
  *   DS17285 (for a Real Time Clock (RTC)...
  *   & MAX3232 for a low-power (3.3V) RS-232 interface
  * Note that the DS17285 does require +5V to operate properly
  * No longer displays to TV
  * Eliminated some unused object references (which sped up compiling/loading)
  * Fixed some synchronization issues between the incoming GPS data and
  *   writing it to the SD card that caused erroneous data to be
  *   occasionally written (or, how to travel faster than Superman?)
  * Now validates NMEA CRC; logs only those sentences that pass validation
  * KML files are now named YYMMDDMM.kml and have their file creation date set
  *   appropriately.
  * Line style now defaults to something a little more visible when displaying
  *  roads, and the line is now clamped to ground for better visibility

  V1.2 adds:
  * Automatic save per the value of SAVE_EVERY_SECONDS. This is in case of
  *   power or other failure; at least the data since the last save will be
  *   retained. Note that you will have to manually append the contents of
  *   FOOTER.TXT to the file for Google Earth to accept the file.
  * Biasing of monitor commands vs. user commands (40-to-1) to improve the
  *   accuracy of the GPS input, especially at 9600 bps.
  * We now check the RTC to see if it's time to save only once per second
  *   (approximately). This greatly reduces the number of commands needed
  *   to be processed by the 6957.
  * The first sentence to be logged is no longer the sentence used to
  *   detect the GPS unit. It is now (correctly) the first sentence issued
  *   after the start of logging.
  * Some GPS sentences can be over 200 bytes in length. We now allow for
  *   sentences of 256 characters, just to be safe.
  * Increased the size of the RS-232 input buffer to 32 characters.
  * If no altitude is received, don't write the value to the card. The Garmin 35
  * doesn't write out the altitude until the unit has a fix.
  
    
  Creative Commons Attribution-Share Alike 3.0
    
  With help from Perry' GPS_IO and Tom Rokicki's SD card routines.
  And lots of help from the Parallax Forums!

  This project captures GPS NMEA strings and saves the track to a Google Earth Compatible KML file.
  * GPS input uses (D)DDMM.mmmm from any GPS that outputs $GPRMC and $GPGGA (per Perry's GPS_IO_mini)
  * SD Card Filename is created using the RTC date/Time as MMDDHHMM.kml
  * Records Latitude, Longitude and Altitude in decimal notation.
                                                                                                           
  ********************************************************************************************************
  There are two text files that are needed on the SD card HEADER.txt and FOOTER.txt which contain specific
  KML formatting. The text of the files is also included at the end of this SPIN in a fake DAT section.

  If you wish to change the line style, these files are the place to do it. references can be found at:
                             http://code.google.com/apis/kml/documentation/
  
  ********************************************************************************************************

USAGE:
  - The system assumes that an SD card is already physically present at all times.
  - The system performs a LED on/off test on all 4 LEDs. 
  - The system checks for the seconds value of the clock to change. Red LED flashes.
  - The system checks for a valid GPS status from the $GPGGA string. Yellow LED Flashes until
    a valid status is received.
  - Green LED steady when ready to begin.
  - Press Start button. Red LED on steady until logging begins.
  - Starts all the external SPIN routines.
  - Creates the KML filename based on the clock. 
  - Logs GPS data and Blue LED is ON while the SD card file is being updated (blinks).
  - Each blink indicates a valid GPS sentence has been received and logged.
    If the Yellow LED blinks, then the CRC for that sentence failed and the values were
    not logged.
  - The Green LED will blink when an automatic save is being performed.
  - Press and hold Stop button until Red LED on, adds the KML footer and completes the file
  - OK to remove card when Green LED is steady. Or...ready for another round via start button.

    It is important to have a CLOSED SD card file or windows will not be able to read it.

    Note: the RS-232 "out" port, although shown in the schematic, is not being used.

                                  10K
                        DAT2 9 ──────────────┐             
                 S        CS 1 ───────────────┼────────────────────────┳─────────────────┐
                 D        DI 2 ───────────────┼──────────────────┳─────┼───────────────┐ │
                         GND 3 ───┐            │                  │     │               │ │
                 C       VCC 4 ───┼────────────╋────┐             │     │               │ │
                 A       CLK 5 ──┼────────────┼────┼───────┳─────┼─────┼─────────────┐ │ └───────────── P4 \                     
                 R       GND 6 ───┻──────┐     │    │       │     │     │             │ └─────────────── P5  \                    
                 D        DO 7 ─────────┼─────┼────┼─┳─────┼─────┼─────┼───────────┐ └───────────────── P6   \                   
                        DAT1 8 ────────┼─────┘    │ 10K  10K  10K  10K        └─────────────────── P7    \ PROPELLER GPIO   
                                  10K    │          ┣─┻─────┻─────┻─────┘     ┌───────────────────────── P3    / (NOTE ORDER!)    
                                                   │                         │    ┌─┳────────────────── P0   /                   
                                                    │                         │    │ 10K²┌─┳─────────── P1  /                                                        ?
              +3.3V ──┳─────────────────────────────┻────┳──────────┳─────┐   │    │ │    │ 10K²┌─┳──── P2 /                                            
                      │                                  │          │     │   │    │     │ │    │ 10K²   
                      │                                 SW 2       SW 1   │   │    │      │     │ │    
                      │                                  │          │     │   │    │ ┌────┘      │   
                      │                                  │ 10K  10K │     │   │    │ │           │
                      │              LED                 ┣──┳───┫  ┌──┼───┘    │ │ ┌─────────┘
                      │              1-4          ┌──────┘         │  │  │   ┌──┐ │ │ │                    
                      ┣────────────┳──────────┐ │                 │  │  │     │ │ │ │                     
                      │            ┣────────┐ │ │ ┌───────────────┘  │  │ 47nF  │ │ │                      
                      │            ┣──────┐ │ │ │ │                  │  │      │ │ │ │
                      │            └────┐ │ │ │ │ │ ┌────────────────┘  └──────╋─┼─┼─┼────────────────────────────────────────────────┐
                      │                   │ │ │ │ │ │ │                          │ │ │ │                                    10K         │
              0.1uF   │   0.1uF           │ │ │ │ │ │ │  R1¹┌──────────────────┐ │ │ │ │ ┌───────────────────────────────────┐        │
           ┌─────────╋───────────────┐  │ │ │ │ │ │ │ ┌─┫1  ISET •    V+ 28┣─┘ │ │ │ │┌────────────────────┐               │        │
           │          │                │  │ │ │ │ │ │ │ ┣──┳┫2  GND      !CS 27┣──┘ │ │ └┫1  !PWR  •M   VCC 24┣───────────────╋── +5V  │
           │          └───────────┐    │  │ │ │ │ │ │ │   └┫3  GND      DIN 26┣────┘ │  │2  N/C    A   SQW 23┣  N/C          │        │
           │ ┌───────────────────┐│    │  │ │ │ │ │ │ └────┫4  DOUT  M SCLK 25┣──────┘  │3  N/C    X VBAUX 22┣─────────┐     │        │ 
       ┌───┼─┫1  C1+  •M   VCC 16┣┘    │  │ │ │ │ │ └──────┫5  P12   A  P31 24┣────────┫4  A/D 0    !RCLR 21┣  N/C         │        │
 0.1uF    └─┫2  V+    A   GND 15┣─────┫  │ │ │ │ └────────┫6  P13   X  P30 23┣────────┫5  A/D 1  D   N/C 20│            10K│        │
       └─────┫3  C1-   X T1OUT 14┣ N/C   │ │ │ └───────────┫7  P14      P29 22┣────────┫6  A/D 2  S  !IRQ 19┣─────────────┘        │
 0.1uF   ┌──┫4  C2+      R1IN 13┣ N/C    │ │ └─────────────┫8  P15   6  P28 21┣────────┫7  A/D 3      !KS 18┣───────────┐            │   
         └───┫5  C2-   3 R1OUT 12┣ N/C    │ └───────────────┫9  P16   9  P27 20┣────────┫8  A/D 4  1   !RD 17┣────────┐             │
 0.1uF ┌────┫6  V-    2  T1IN 11┣ N/C    └─────────────────┫10 P17   5  P26 19┣────────┫9  A/D 5  7   N/C 16│         │              │
        ┌──┫7  T2OUT 3  T2IN 10┣────────────────────────┫11 P18   7  P25 18┣────────┫10 A/D 6  2   !WR 15┣──────┐ │              │
         │ ┌┫8  R2IN  2 R2OUT  9┣────────────────────────┫12 P19      P24 17┣────────┫11 A/D 7  8   ALE 14┣────┐ │ │  10K²        │
         │ │ └───────────────────┘                     ┌───┫13 P20      P23 16┣────┐   ┌┫12 GND    5   !CS 13┣──┳─┼─┼─┼────────────┘        
         │ │                                           │┌──┫14 P21      P22 15┣──┐ │   └────────────────────┘   │ │ │ │            
         │ └── RS-232 INPUT                           ││   └──────────────────┘   │ └─────────────────────────────┼─┼─┼─┘
         └──── RS-232 OUTPUT³                         ││                          └───────────────────────────────┼─┼─┘
                                                       │└──────────────────────────────────────────────────────────┼─┘                        │
                                                       └───────────────────────────────────────────────────────────┘      

Notes:                                                                                            
¹: R1 is used to set maximum LED port current. Minimum value is 39K.                                                                                       
²: This is a pullup used to ensure that:
   * The RTC does not execute any commands at powerup.
     If not implemented, the seconds register is randomly reset at powerup.
   * "Ringing" (per the datasheet) does not occur on the control pins for the 6957.
³: RS-232 output (Port 18) is not currently used and is available for other GPIO if
   desired.
 
}  
CON

  _CLKMODE            = XTAL1 + PLL16X
  _XINFREQ            = 5_000_000
  _stack              = 100 ' Probably overkill
  
  ' Set this to the pins you have connected to the MAX6957
  CS_PIN = 0
  IN_PIN = 1
  SCLK_PIN = 2
  OUT_PIN = 3

  CS_PORT = 20
  ALE_PORT = 21
  WR_PORT = 22
  RD_PORT = 23
  ADDR_DATA_PORT = 24
   
' NAME        PIN
' ----------  ----------------- 
' SDCard Assignments
  SDbase    = 04                                        ' SD Card base pin. 4 pins total
             '05
             '06
             '07

' Momentary Switches                                    
  S1_PORT          = 12                                        ' Start logging
  S2_PORT          = 13                                        ' Stop logging

  LED_RED_PORT     = 17  'LED 4
  LED_YELLOW_PORT  = 16  'LED 3
  LED_GREEN_PORT   = 15  'LED 2
  LED_BLUE_PORT    = 14  'LED 1

  MONITOR_IN_PORT  = 19

' Time, in seconds, between close/reopen of file (to ensure that a minimum of data
' is lost in case of power or other failure).
' Recommended minimum is 30 (to prevent excessive writes to the card).
' Set to -1 to disable.

  SAVE_EVERY_SECONDS = 60

                                                                                 
VAR
  byte s,d,datum[64]                                    ' space for file copying
  byte fname[13]                                        ' BYTESs for SDcard 8.3 filenames
  long monitor_in
  long gps_synch                                        ' 0 => Initializing/idle
                                                        ' 1 => Preparing data
                                                        ' 2 => Data ready
                                                        ' 3 => Invalid CRC
  long cdatetime                                        ' File creation date/time in FAT format
  long nextsavetime                                     ' The time of the next save in seconds
                                                        ' since January 1, 2000
  long lastCnt                                          ' The system cnt value when we
                                                        ' last read the RTC
    
OBJ                                                    
  gps        :  "GPS_IO_AGEL"                           ' Services GPS input           
  fmt        :  "format_AGEL"                           ' Used for reformatting data between NUM, STR, types.
  sdfat      :  "fsrw"                                  ' FAT16 object for SD card logger
  num        :  "Numbers"
  io         :  "MAX_6957_DS17285_IO"                   ' Custom I/O - clock object

PUB start

gps_synch := 0

''Initialize all necessary routines into their cogs as appropriate

Init6957
  gps.start(@MONITOR_IN, @GPS_SYNCH, 4800)              ' start GPS ingest (gets its own cog)

num.init                                                ' numbers and math routines

ControlLoop                                             ' overall loop

pri Init6957
  io.init(CS_PIN, IN_PIN, SCLK_PIN, OUT_PIN, MONITOR_IN_PORT, @MONITOR_IN)

  io.StartNormalOperation(true)

  io.SetGlobalSegmentCurrentReg(15)
  
  io.SetPortSegmentCurrentReg(LED_BLUE_PORT, 0) ' Really BRIGHT LED!!!
  io.SetPortSegmentCurrentReg(LED_GREEN_PORT, 15)
  io.SetPortSegmentCurrentReg(LED_YELLOW_PORT, 6)
  io.SetPortSegmentCurrentReg(LED_RED_PORT, 15)
  
  io.SetPortConfig(LED_BLUE_PORT, io#PORT_CONFIG_LED)
  io.SetPortConfig(LED_GREEN_PORT, io#PORT_CONFIG_LED)
  io.SetPortConfig(LED_YELLOW_PORT, io#PORT_CONFIG_LED)
  io.SetPortConfig(LED_RED_PORT, io#PORT_CONFIG_LED)
  
  io.SetPortBit(LED_BLUE_PORT, 0)
  io.SetPortBit(LED_GREEN_PORT, 0)
  io.SetPortBit(LED_YELLOW_PORT, 0)
  io.SetPortBit(LED_RED_PORT, 0)

  io.DisplayTest(CLKFREQ)
  
  ' Redundant, but we want to make sure it's an input
  io.SetPortConfig(S1_PORT, io#PORT_CONFIG_INPUT)
  io.SetPortConfig(S2_PORT, io#PORT_CONFIG_INPUT)

             
PUB ControlLoop | flag, timenow                         ' primary pervasive loop

repeat
  io.SetPortBit(LED_RED_PORT, 0)
  io.SetPortBit(LED_GREEN_PORT, 0)
  io.SetPortBit(LED_YELLOW_PORT, 0)
  io.SetPortBit(LED_BLUE_PORT, 0)                       
  
  CheckForClock                                         ' Make sure the clock is available

  CheckForSatellite                                     ' make sure GPS is active before continuing

  io.SetPortBit(LED_GREEN_PORT, 1)

  repeat until io.GetPortBit(S1_PORT) == 1              ' Wait for switch closure

  repeat until io.GetPortBit(S1_PORT) == 0              ' Wait for switch open

  NextSaveTime := GetClockForComparison + SAVE_EVERY_SECONDS ' Set up first save time
   
  io.SetPortBit(LED_GREEN_PORT, 0)
  io.SetPortBit(LED_RED_PORT, 1)
  
  sdfat.mount(SDbase)                                   ' mount the SD card on pins P4 to P7
 
  CreateKML                                             ' create a GPS timestamp-named log file for the SD card

  flag := 0
  
  io.SetPortBit(LED_RED_PORT, 0)

  sdfat.popen(@fname, "a") 
  
  gps_synch := 0                                        ' Ignore any previous gps data

  repeat until flag == 1                                
   case io.GetPortBit(S2_PORT)                          
    0:                                                  ' switch is open                                                
      ' do we need to do a save?
      if SAVE_EVERY_SECONDS > 0
        if (cnt - lastCnt) > clkfreq                    ' Has at least a second elapsed?
          lastCnt := cnt
          
          if GetClockForComparison => NextSaveTime      ' Is it time to do a save?
            io.SetPortBit(LED_GREEN_PORT, 1)
            sdfat.pclose                                ' close and reopen file to save
            sdfat.popen(@fname, "a")
            io.SetPortBit(LED_GREEN_PORT, 0)
            NextSaveTime += SAVE_EVERY_SECONDS          ' Set up next save time

      if gps_synch == 2
        GELog                                           ' format into a KML file for logging
        gps_synch := 0
      elseif gps_synch == 3                             ' Invalid CRC
        toggle(LED_YELLOW_PORT)
        gps_synch := 0   
    1:                                                  ' switch is closed
      io.SetPortBit(LED_RED_PORT, 1)
      sdfat.pclose
      copyfile(string("footer.txt"), @fname)            ' Add predefined KML Footer information to log file
      RemoveCard                                        ' insure SD file is closed.
      flag := 1

  io.SetPortBit(LED_GREEN_PORT, 1)
  repeat until io.GetPortBit(S2_PORT) == 0              ' Wait for switch open      

PUB GetClockForComparison | century, year, month, date, hours, minutes, seconds, comparevalue, control_b_reg
' Returns a value that can be used for interval detection until approximately the year 2068
' In other words, not Y2100 compliant...

  ' Prevent clock from updating date/time registers during reads
  
  control_b_reg := io.ReadClockRegister(io#CONTROL_B)

  io.WriteClockRegister(io#CONTROL_B, control_b_reg | io#control_b_set)

  year    := io.ReadClockRegister(io#YEAR)
  month   := io.ReadClockRegister(io#MONTH)
  date    := io.ReadClockRegister(io#DATE)
  hours   := io.ReadClockRegister(io#HOURS)
  minutes := io.ReadClockRegister(io#MINUTES)
  seconds := io.ReadClockRegister(io#SECONDS)

  ' Allow clock to update once again
  
  io.WriteClockRegister(io#CONTROL_B, control_b_reg)

  comparevalue := year * 31536000 ' number of seconds in 365 days

  case month
    1, 3, 5, 7, 8, 10, 12:
      comparevalue += CONSTANT (31 * 24 * 3600)
    2:
      comparevalue += CONSTANT (28 * 24 * 3600)
      if year // 4 == 0
      comparevalue += CONSTANT (24 * 3600) ' number of seconds in a day
    other:
      comparevalue += CONSTANT (30 * 24 * 3600)

  comparevalue += date * CONSTANT (24 * 3600)
  comparevalue += hours * 3600
  comparevalue += minutes * 60
  comparevalue += seconds

return comparevalue       

PUB CreateKML | century, year, month, date, hours, minutes, seconds, datetime, control_b_reg
'' MMDDHHMM.kml - Creates a string to name the primary data log based on input date information from GPS

  ' Prevent clock from updating date/time registers during reads
  
  control_b_reg := io.ReadClockRegister(io#CONTROL_B)

  io.WriteClockRegister(io#CONTROL_B, control_b_reg | io#control_b_set)

  io.SetClockRamBank(1)
  century := io.ReadClockRegister(io#BANK_1_CENTURY)
  io.SetClockRamBank(0)

  year    := io.ReadClockRegister(io#YEAR)
  month   := io.ReadClockRegister(io#MONTH)
  date    := io.ReadClockRegister(io#DATE)
  hours   := io.ReadClockRegister(io#HOURS)
  minutes := io.ReadClockRegister(io#MINUTES)
  seconds := io.ReadClockRegister(io#SECONDS)

  ' Allow clock to update once again
  
  io.WriteClockRegister(io#CONTROL_B, control_b_reg)

  datetime := month  * 1000000
  datetime += date   * 10000
  datetime += hours  * 100
  datetime += minutes
  
  cdatetime := sdfat.filedate(century, year, month, date, hours, minutes, seconds) 

  fmt.sprintf(@fname,string("%08d"),datetime)             ' converts string to integer then into fixed 4 digit string. Works with leading zeros
  
  byte[@fname+8]  := "."                                  ' add the file extension
  byte[@fname+9]  := "k"
  byte[@fname+10] := "m"
  byte[@fname+11] := "l"
  byte[@fname+12] := 0

  copyfile(string("header.txt"), @fname)                  ' Add KML Header information to kmllog file

 
PUB GElog | idx, DD, d8, decDD, lockstatus
'' Google Earth KML writer
'' Paul Hubner 2008. GPL v3 share and share alike
'' This routine uses the GPS_IO_mini (any of them) to capture Lat, Lon and Alt. Then it writes these to an SD card in
'' Decimal Degrees.  The log file can be directly opened with Google Earth to see your path.

' If we don't have an altitude, we don't have a fix, so don't write to the SD card
if (byte[gps.altitude] > 0)

' WRITING DATA TO SD CARD

  io.SetPortBit(LED_BLUE_PORT, 1)

'Longitude
  DD     := num.ToStr(atoi(gps.longitude,3),Num#DEC3)   ' whole degrees - DEC# is the number of digits needed in the string
  SDwrite(string("-"))                                  ' Correct sign for western hemisphere, manually for now
  if atoi(gps.longitude,3) > 99                         ' Write whole characters to the file that's open.
    sdfat.pputc(byte[DD+0])                             ' Write hundreds IF applicable
  sdfat.pputc(byte[DD+1])                               ' Write tens
  sdfat.pputc(byte[DD+2])                               ' Write ones
  d8 := atoi(gps.longitude+3,2) * 100_000 / 6           ' 8 digit, frac degrees. intermediate needed before conv to string for accuracy.
  d8 += atoi(gps.longitude+6,4) * 10 /6             
  decDD    := num.ToStr(d8,Num#DEC7)                           ' string of the decimal component
  SDwrite(string("."))                                  ' insert the space between DD and d6
  repeat idx from 1 to 6                                ' 0 byte is blank!
     sdfat.pputc(byte[decDD+idx])                       ' Write decimal characters to the file that's open.
  SDwrite(string(","))                                  ' comma separator

'Latitude
  DD     := num.ToStr(atoi(gps.latitude,2),Num#DEC3)   ' whole degrees - write as is. It is only 2 digits
  sdfat.pputc(byte[DD+1])                               ' Write tens
  sdfat.pputc(byte[DD+2])                               ' Write ones
  SDwrite(string("."))                                  ' insert the space between DD and d6
  d8 := atoi(gps.latitude+2,2) * 100_000 / 6            ' intermediate needed before conv to string for accuracy.
  d8 += atoi(gps.latitude+5,4) * 10 /6             
  decDD    := num.ToStr(d8,Num#DEC7)                    ' 7byte string of the decimal component
  repeat idx from 1 to 6                                ' 0 byte is blank!
     sdfat.pputc(byte[decDD+idx])                       ' Write decimal characters to the file that's open.
  SDwrite(string(","))                                  ' comma separator

'Altitude  
  SDwrite(gps.altitude)                                 ' now we can just write the entire GPS input with no alteration
  SDwrite(string(" "))
                                                        ' KML files call for SPACE delimiter between GPS coordinates
  waitcnt(clkfreq / 8 + cnt)                            ' Make the LED flash a little longer...
  io.SetPortBit(LED_BLUE_PORT, 0)


PUB CopyFile(src,dst) | loop, N, idx
'' copies SDcard file.  Need to genericize ReadCard for any filename.
'' OPEN and CLOSE on file is very time intensive compared to reading and writing actual data.

  N := 64                                               ' number of bytes to read per loop. Make sure VAR array 'datum' matches.
  loop := 0                                             ' keep track of number of iterations
  repeat                                                ' main copy loop

    sdfat.popen(src, "r")                               ' open SRC
    repeat N * loop                                     ' count through the file to get to where we left off last time 
      datum := sdfat.pgetc                              ' put pointer at next character location

    idx := 0
    repeat N                                            
      datum[idx] := sdfat.pgetc                         ' current interesting character
      if datum[idx] < 0                                 ' check for end of file(NULL)
        quit                                            ' abort loop on EOF
      idx++                                             ' increment the pointer position in the READ file
    sdfat.pclose                                        ' close src

    sdfat.popend(dst, "a", cdatetime)                   ' open DST    
    idx := 0                                            ' reset index position for loop out
    repeat N
      if datum[idx] < 0                                 ' check for end of file(NULL)
        quit                                            ' abort loop on EOF
      if datum[idx] == 255                              ' check for end of file(255)
        quit                                            ' abort loop on 255 EOF. Not sure why it it 255 and not -1
      sdfat.pputc(datum[idx])                           ' copy char out
      idx++                                             ' increment array pointer
    sdfat.pclose                                        ' close dst
    
    loop++                                              ' get next N bytes from SRC file

    if datum[idx] < 0                                   ' check for end of file(NULL)
      quit
    if datum[idx] == 255                                ' check for end of file(255)
      quit

  sdfat.pclose                                          ' close dst

 
PUB Removecard
''routine to insure the SD card file is closed. Open files appear as corrupted to windows.

  sdfat.pclose                                          ' close SD card

PUB SDwrite(strAddr )                                   ' Writes the string located at strAddr to the SD card
  repeat strsize(strAddr)                               ' loop for each character in string
    sdfat.pputc(byte[strAddr++])                        ' Write the character to the file that's open

Pub CheckForSatellite 
  
repeat
  repeat 4
   toggle(LED_YELLOW_PORT)
while gps_synch < 2                 

io.SetPortBit(LED_YELLOW_PORT, 0)     

PUB CheckForClock | seconds

  io.StartClock(CS_PORT, ALE_PORT, WR_PORT, RD_PORT, ADDR_DATA_PORT)

' Read seconds value, wait, then make sure it's not the same value
  seconds := io.ReadClockRegister(io#SECONDS)

  repeat
    repeat 4
      toggle(LED_RED_PORT)

  while(seconds == io.ReadClockRegister(io#SECONDS))

  io.SetPortBit(LED_RED_PORT, 0)

PUB atoi( pptr,c)| ptrr, sign                           ' convert c characters into number
  result := sign := 0
  if byte[pptr] == "-"
      sign++
      pptr++
  c--    
  repeat ptrr from 0 to c
    if byte[pptr+ptrr] == 0                             ' stop if null
         quit
         
    if byte[pptr+ptrr] == "."                           ' stop at decimal point
         quit
    else     
       result := result * 10 + (byte[pptr+ptrr] - "0")
  if sign == 1
    result := -result

PUB Toggle(pin) | bit
  repeat 2
    bit := !bit
    io.SetPortBit(pin, bit)
    waitcnt(500_0000 + cnt)
 
DAT  'COPY INTO SEPARATE TEXT FILES AND PLACE ON THE SD CARD.
{
HEADER.TXT
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
  <Document>
    <name>DataLog</name>
    <Style id="transBluePoly">
      <LineStyle>
        <color>7dff0000</color>
        <width>7</width>
      </LineStyle>
      <PolyStyle>
        <color>7dff0000</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>GPS Log</name>
      <styleUrl>#transBluePoly</styleUrl>
      <LineString>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>clampedToGround</altitudeMode>
        <coordinates>

FOOTER.TXT
        </coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>

}

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