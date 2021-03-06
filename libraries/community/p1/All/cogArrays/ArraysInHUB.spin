{{ ******************************************************************************
   * Arrays In HUB example                                                      *
   * James Burrows Feb 2008                                                     *
   * Version 1.0                                                                *
   ******************************************************************************
   ┌──────────────────────────────────────────┐
   │ Copyright (c) <2008> <James Burrows>     │               
   │   See end of file for terms of use.      │               
   └──────────────────────────────────────────┘

   this object provides the PUBLIC functions:
    -> N/A
  
   this object provides the PRIVATE functions:
    -> N/A
  
   this object uses the following sub OBJECTS:
    -> debug_pc
    -> fullduplexserial


   This example demonstrates using PASM (propeller ASM) to read and write to a block of HUB memory.
   A block of HUB memory is reserved for this - 51 longs as we're using the first LONG to return
   the result back to SPIN in.  LONGS 1-51 makeup the same amount of memory as in the
   "ArraysInCOG.spin" example.
}}


CON
    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000

    ' debug - USE onboard pins
    pcDebugRX       = 31
    pcDebugTX       = 30
     
    ' serial baud rates  
    pcDebugBaud     = 115200 

VAR
    long        stackGPS[20]
    long        asm_result
    long        PASMcogID

    long        largeBlockOfHUBMemory[51]
    
    
OBJ
    debug             : "Debug_PC"


PUB Start     
    ' start the PC debug object
    debug.startx(pcDebugRX,pcDebugTX,pcDebugBaud)

    repeat 6
        debug.putc(".")
        waitcnt(clkfreq/2+cnt)
    debug.putc(13)

    debug.str(string("ArraysInASM"))    

    PASMcogID := cognew(@entry, @largeBlockOfHUBMemory)

    debug.str(string("Running in cog "))
    debug.dec(PASMcogID)
    debug.putc(13)

    repeat
        ' show debug
        debug.str(string("data: "))
        debug.dec(long[@largeBlockOfHUBMemory][0])
        debug.putc(13)

        ' wait 1/2 sec
        waitcnt(clkfreq/2+cnt)        
    

        
DAT
'------------------------------------------------------------------------------------------------------------------------------
'| Entry
'------------------------------------------------------------------------------------------------------------------------------
                        org
entry                   mov     t1,par                      ' get address of HUB variable for SPIN to see

                        mov     ValueOf,#1                  ' setup to write "1" into each HUB memory location

'------------------------------------------------------------------------------------------------------------------------------
'| WRITE to HUB memory
'------------------------------------------------------------------------------------------------------------------------------
andAgain                mov     arrayPointer,par            ' setup pointer
                        add     arrayPointer,#4             
                        mov     ctr,#50

:write1                 wrlong  ValueOf,arrayPointer
                        add     arrayPointer,#4 

                        djnz    ctr,#:write1

'------------------------------------------------------------------------------------------------------------------------------
'| READ from HUB memory
'------------------------------------------------------------------------------------------------------------------------------
                        mov     arrayPointer,par            ' setup pointer
                        add     arrayPointer,#4             '
                        mov     ctr,#50
                        mov     sum,#0

:read1                  rdlong  aValue,arrayPointer
                        add     sum,aValue
                        add     arrayPointer,#4
                        
                        djnz    ctr,#:read1

'------------------------------------------------------------------------------------------------------------------------------
'| WRITE the result (sum) back to the HUB memory
'------------------------------------------------------------------------------------------------------------------------------
                        wrlong  sum,t1                      ' write it back

                        jmp     #andAgain


ValueOf                 res         1
aValue                  res         1                        
t1                      res         1
sum                     res         1
ctr                     res         1
arrayPointer            res         1

FIT 496

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