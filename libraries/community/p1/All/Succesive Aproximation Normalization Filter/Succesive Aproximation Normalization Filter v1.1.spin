{
****************************************************
* Succesive Aproximation Normalization Filter v1.1 *
* Author: Beau Schwabe                             *
* Copyright (c) 2013 Parallax                      *
* See end of file for terms of use.                *
****************************************************
 History:
          Version 1.0             07-19-2013              initial release
          Version 1.1             07-19-2013              added Assembly SAN Option          

 Purpose:
          Take a data value where you know the upper and lower limits and
          "normalize" the data so that it proportionally scales to a binary
          weighted value.

          For instance, say you have a potentiometer that reads 204 on one extreme
          and 8453 on the other extreme.  ...And the current value is 2834.
          You want to scale that to a 12-Bit number?  Simply load the Data,
          BitResolution, RefLOW, RefHIGH variables and call the function.  The
          returned value will contain the result. 1306 in this case. 


          Yes, you could apply the formula ...

               Data = [(Data-RefLOW)/(RefHIGH-RefLOW)]*(2^BitResolution)
               
          ... but this function avoids any floating point, and gets the job done
          using only shift and adds. 

VAR  
'--------------------------------------------------------
'   Variables must remain in this order for both optons

long    Data,BitResolution,RefLOW,RefHIGH
'--------------------------------------------------------

Here you have two options:

    1) Run the Assembly SAN filter:
        Asm(@Data)

    2) Run the SPIN SAN filter:   
        Data := Spin(Data,BitResolution,RefLOW,RefHIGH)
        
}

PUB STOP
PUB Asm(DataAddress)
    cognew(@PASM,DataAddress)
PUB Spin(_Data,_BitResolution,_RefLOW,_RefHIGH)|Temp,RefMID

    Temp := 0
    repeat _BitResolution 
      RefMID := _RefHIGH
      RefMID += _RefLOW
      RefMID >>= 1
      if _Data > RefMID
         _RefLOW := RefMID
         Temp := Temp<<1 +1
      else
         _RefHIGH := RefMID
         Temp := Temp<<1
    result := Temp 

DAT
              org
'------------------------------------------ Get Variables
PASM          mov       pTemp,par       
              rdlong    pData,pTemp
              add       pTemp,#4
              rdlong    pResolution,pTemp
              add       pTemp,#4
              rdlong    pRefLOW,pTemp
              add       pTemp,#4
              rdlong    pRefHIGH,pTemp
              add       pTemp,#4
              mov       pTemp,#0
'------------------------------------------ Apply Filter
Loop          mov       pRefMID,  pRefHIGH  
              add       pRefMID,  pRefLOW
              shr       pRefMID,  #1
              sub       pRefMID,  pData         wc,nr
         if_c mov       pRefLOW,  pRefMID       'If pData >  pRefMID ; RefLOW  = pRefMID
        if_nc mov       pRefHIGH, pRefMID       'If pData =< pRefMID ; RefHIGH = pRefMID
              rcl       pTemp,#1
              djnz      pResolution, #Loop
              wrlong    pTemp,par
'------------------------------------------ Exit COG        
              cogid     pTemp
              cogstop   pTemp

pData         long      0
pResolution   long      0
pRefLOW       long      0
pRefHIGH      long      0
pRefMID       long      0
pTemp         long      0
              
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