{{ Program Text_Page_To_Micro
Date    24Aug18
Purpose;
Rev1_24Aug18; Prepared for Obex  
}}                                                                                                                                                
CON
  _clkmode = xtal1 + pll16x                                                      
  _xinfreq = 5_000_000

  WXDO = 0   'rx, serial in Prop P0 <- WXDO, see BS2 program
  WXDI = 1   'tx, serial out Prop P1 -> WXDI, see BS2 program 

CON
   
                                                                                 
VAR
  long  cntr          'utility counter and byte value
  long pollnccntr     'poll no connection counter   
  byte WXCmdRet[16]   'array for Command Reply strings    
  byte WXlistenRetID
  byte WXlistenRetOp
  byte WXreplyRetOp
  byte WXreplyRetID  
  byte WXreplyRet[12] 
  byte WXjoinRetID
  byte WXjoinRetOp  
  byte WXPollRetOp
  byte WXPollRetHandle
  byte WXPollRetId
  byte char
  long CharCnt
  
OBJ
  FDS  : "FullDuplexSerialPlus"
  PST  : "Parallax Serial Terminal"

PUB Main
'Main program structure
  A_Start
  repeat
    B_Main
    waitcnt(clkfreq + cnt)
  C_End

PUB A_Start
'Start up and initialise
'Start PST and wait for keypress
  PST.start(115_200)
  PST.Clear
  PST.Home
  PST.Str(string("press any key to resume. . . "))
  cntr := PST.CharIn
'Start FDS
  FDS.start(WXDO,WXDI,%0000,115_200)   ' Prop rxpin,Prop txpin(see BS2 prog), mode,baudrate
  waitcnt(clkfreq/8 + cnt)
'WX start up and initialize routines
  A2_ListenSetup
  pollnccntr := 0
                                
PUB A2_ListenSetup
'Send the Listen command
  PST.Newline
  PST.str(string("A2; "))                                                                      
  FDS.rxflush   ' Clear RX buffer
  FDS.str(string($FE,"LISTEN:"))
  PST.str(string($FE,"LISTEN:"))   
  FDS.str(string("HTTP"))
  PST.str(string("HTTP"))  
  FDS.str(string(","))
  PST.str(string(","))  
  FDS.str(string("/fptm")) 'see the script of the web page
  PST.str(string("/fptm"))
  FDS.str(string(13,10))
  PST.str(string("13,10"))
  waitcnt(clkfreq/8 + cnt)
'First zero listen return variables and capture return string
   WXlistenRetID := 0
   Z1_WXCmdRet
'fill the listen return varibles
    WXlistenRetID := WXCmdRet[4]
    WXlistenRetOp := WXCmdRet[2]
'now print the listen return in the same format as API - BEWARE THE CHAR 13 - IT IS NEWLINE FOR PST   
   PST.PositionX(35)
    PST.str(string("return in API format "))
    PST.PositionX(65)
    Z2_RetAPI    
 'if the listen return Op is not S, then there is no point in continuing, terminate
'    if WXlistenRetOp <> "S"
'      C_End
    
PUB B_Main  
'main program loop
  B1_PollEvents
  if WXPollRetOp == "P"
    if WXPollRetId == WXlistenRetID
      pollnccntr := 0    'a HTTP POST request has occured, reset no connection counter      
      PST.Newline
      PST.str(string("BMin; P, ID match "))
      B2_PostRequestStart      
'Get the txt argument from the webpage here
      PST.Newline
      PST.str(string("txt string from webpage; "))
      Z1_WXCmdRet       
      PST.str(@WXCmdRet)      
      B3_PostRequestAck
'      PST.Newline
'      PST.str(string("end of B2 and B3---------------------------")) 
  
PUB B1_PollEvents
'Poll for recent events
'Send POLL command
  FDS.rxflush   ' Clear RX buffer
  FDS.str(string($FE,"POLL"))
  FDS.str(string(13,10))
'First zero poll return variables and capture the return string
   WXPollRetOp := 0
   WXPollRetHandle := 0
   WXPollRetId := 0
   Z1_WXCmdRet   
'fill the poll return variables
    WXPollRetOp := WXCmdRet[2]
    WXPollRetHandle := WXCmdRet[4]
    WXPollRetId := WXCmdRet[6]
'now print the poll return in the same format as API - BEWARE THE CHAR 13 - IT IS NEWLINE FOR PST   
'print the first no connection or any other connection like b=G,5,1E
    if (WXPollRetOp <> "N") 
      PST.Newline
      PST.str(string("B1; POLL -> POLL return API format "))
      PST.PositionX(40)
      Z2_RetAPI
'we do not want endless b=N:0,0E returns for no connection.
'print the first no connection then just increment a counter
    if (WXPollRetOp == "N")
      if (pollnccntr == 0)   
        PST.Newline
        PST.str(string("B1; POLL -> POLL return API format  "))
        Z2_RetAPI
'increment and print the current counter value
      pollnccntr := pollnccntr + 1      
      PST.PositionX(55)
      PST.str(string("no conn cntr "))
      PST.Dec(pollnccntr)
      PST.str(string("   "))    
          
PUB B2_PostRequestStart  
'to retrieve the POST request for HTTP txt argument from webpage, use ARG
  PST.PositionX(25)
  PST.str(string("B2; "))
  FDS.rxflush   ' Clear RX buffer
  FDS.str(string($FE,"ARG:"))
  PST.str(string($FE,"ARG:"))   
  FDS.tx(WXPollRetHandle)
  PST.char(WXPollRetHandle)  
  FDS.str(string(","))
  PST.str(string(","))
  FDS.str(string("txt"))
  PST.str(string("txt"))
  FDS.str(string(13))
  PST.str(string("13"))
  waitcnt(clkfreq/8 + cnt)

PUB B3_PostRequestAck
'read the POST request acknowledgement
'First zero reply return variables and send the reply operation for HTTP
  WXreplyRetOp := 0
  WXreplyRetOp := 0
  FDS.str(string($FE,"REPLY:"))
  PST.str(string($FE,"REPLY:"))   
  FDS.tx(WXPollRetHandle)
  PST.char(WXPollRetHandle)  
  FDS.str(string(","))
  PST.str(string(","))  
  FDS.str(string("200")) 'this is rcode, desired HTTP code for the reply
  PST.str(string("200"))
  FDS.str(string(","))
  PST.str(string(","))                        
  FDS.str(string(13))
  PST.str(string("13"))      
'capture the return string, fill the reply return variables
  Z1_WXCmdRet 
  WXreplyRetID := WXCmdRet[4]
  WXreplyRetOp := WXCmdRet[2] 
  PST.PositionX(30)
  PST.str(string("B3; REPLY return API format "))
  PST.PositionX(65)
  Z2_RetAPI
  waitcnt (clkfreq/8 + cnt)

PUB C_End
'Terminate program on error
  PST.Newline
  PST.Str(string("Program terminated due to error. Press any key to finish"))
  cntr := PST.CharIn

PUB Z1_WXCmdRet
'First zero the counter and return string
  cntr := 0
  bytefill(@WXCmdRet,0,16)
   cntr := 0
  bytefill(@WXCmdRet,0,16)
'receive bytes until a valid begin char is received
  repeat   
     waitcnt(clkfreq/100 + cnt) 
     char := FDS.rxcheck
  until char == $FE   
  cntr := 0
  WXCmdRet[cntr] := char
'we have a valid begin char in byte 0, now capture the rest of the byte string and echo on PST    
  repeat
     cntr := cntr + 1
     char := FDS.rxcheck
     WXCmdRet[cntr] := char 
'     Z1A_Echo              'For debug echo the byte string on PST
  until (WXCmdRet[cntr] == $0D) or (cntr > 15)
  waitcnt(clkfreq/8 + cnt)

PRI Z1A_Echo
'Private method to echo the return string - BEWARE THE CHAR 13 - IT IS NEWLINE FOR PST
     PST.Dec(cntr)
     PST.str(string("/"))
     if (WXCmdRet[cntr]) == $0D
        PST.Str(string("13"))
     else
        PST.Char(WXCmdRet[cntr])
     PST.Str(string("/"))
     PST.Hex(WXCmdRet[cntr],2)
     PST.Str(string(" "))

PUB Z2_RetAPI
'print the return in API format
    cntr := 0
    repeat
      case WXCmdRet[cntr]
        $FE : PST.str(string("b"))
        $13 : PST.str(string("13"))
        OTHER : PST.Char (WXCmdRet[cntr])
      cntr := cntr + 1     
    until (WXCmdRet[cntr] == $0D) or (cntr > 15)
    waitcnt(clkfreq/8 + cnt)

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}        