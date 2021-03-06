{****************************************Vinculum Driver*******************************************
This file contains a Vinculum SPI driver and a quick test for the driver.  For demonstration
purposes, the flushing of the splash screen and initialization prompts are not included in the
Start method.  Once you are comfortable with the operation you can remove the initialization to
Start and modify as needed to display or not.

In addition to the I/O pins specified, you should also attach the Vinculum /Reset pin to the
Propeller /Reset pin.  That way everytime you load new code the Vinculum will also be reset.

ReadFile and WriteFile do not report errors.  Use the lower level methods to create more
robust methods.

This code was tested using VDIP1 version 03.63VDAPB

03/27/08        Rev1.0          Chip Curtis, original version.
03/27/08        Rev1.1          Added license


**************************************************************************************************}

{{

┌──────────────────────────────────────────┐
│ Vinculum                                 │
│ Author: Chip Curtis                      │               
│ Copyright (c) 2008 Chip Curtis           │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘
}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000


CON
  #1, CMDStream, CMDRead, CMDWrite, CMDStatus, CMDWriteString, CMDReadFile, CMDWriteFile
  NoData = 2 'This is HIGH when there is no data
  StreamTerminator= $EA 'Used for ADPCM streaming

'********************************************Commands**********************************************
  DIR = 1 'Lists files in the directory
  CD = 2 'Change directory 02 20 0D
  RD = 4 '04 20 file 0D Reads a whole file 
  WRF = 8 '08 20 dword 0D data Write the number of bytes specified in the 1st parameter to the
           'currently open file
  OPW = 9 '09 20 file 0D Open a file for writing or create a new file             
  CLF = $A '0A 20 file 0D Close the currently open file
  RDF = $B '0B 20 dword 0D Read the number of bytes specified in the 1st parameter from the
            'currently open file
  OPR = $E '0E 20 file 0D Open a file for reading
  SEK = $28 '28 20 dword 0D Seek to the byte position specified by the 1st parameter in the
             'currently open file               


OBJ
  text  : "TV_Text"


PUB SPITest

  Text.Start(12) 'Start the video driver
  Start(0, 1, 2, 3) 'Start the SPI driver
  Text.str(string("Started", 13))


  EchoUntilPrompt 'Echo the initialization screen


'Short Command Set
  WriteString(@InitStr) 'Send the initialization string for short command set 
  EchoFIFO 'Echo the result  


'Read the directory
  WriteString(@DirFileStr)
  EchoUntilPrompt


  Text.str(string(13, "Done", 13))




PUB Start(Clk, CS, Out, In)
{{Pass the pin numbers and setup pointers}}

  ClkMask:=1<<Clk 'Save the pin assignments
  CSMask:=1<<CS
  OutMask:=1<<Out
  InMask:=1<<In
  ReadHeaderStr_:=@ReadHeaderStr 'Give the COG the hub address      

  cognew(@SPIStart, @command) 'Start the SPI cog

  
PUB GetStatusWord
{{Returns the status word from the Vinculum chip}}

  command:=CMDStatus 'Start the command
    repeat while command 'Wait for it
  return byteCount 'Return the Status Word


PUB Read (Dest, Count)
{{Reads any number of bytes from the Vinculum and places them in the HUB address, destination}}

  bufferAddress:=Dest 'Pass the address to store the result
  byteCount:=Count 'Pass the number of bytes to transfer
  command:=CMDRead 'Start the read, don't wait for it to finish in case we have other things to do


PUB Write(Source, Count)
{{Writes any number of bytes from the HUB address, Source, to the Vinculum chip}}

  bufferAddress:=Source 'Pass the address of the source 
  byteCount:=Count 'Pass the number of bytes to transfer
  command:=CMDWrite 'Start the write, don't wait for command to finish


PUB WriteString(Source)
{{Writes the null terminated string at bufferAddress to the Vinculum}}
  bufferAddress:=Source 'Pass the address of the string
  command:=CMDWriteString 'Start the write


PUB StreamData(Dest, Source)
{{Stream data from a file name pointer to a HUB location.  This command is used by a modified HSS
driver to stream ADPCM audio}}

  bufferAddress:=Source 'Use the source location because WriteString is called inside the driver
  eepromAddress:=Dest 'The HUB address of the pointer to the ADPCM buffer
  command:=CMDStream 'Start the stream

PUB ReadFile(Dest, Source, Count)
{{Opens a filename pointed to by Source and saves Count bytes to the HUB location at Dest}}
  bufferAddress:=Source 'File Name Pointer use the source location because WriteString is called inside the driver
  eepromAddress:=Dest 'The HUB address of the destination
  byteCount:=Count 'Pass the number of bytes to transfer
  command:=CMDReadFile 'Perform the read

PUB WriteFile(Dest, Source, Count)
{{Opens a filename pointed to by Dest and saves Count bytes from the HUB location at Source}}
  bufferAddress:=Dest 'File Name Pointer use the source location because WriteString is called inside the driver
  eepromAddress:=Source 'The HUB address of the source
  byteCount:=Count 'Pass the number of bytes to transfer
  command:=CMDWriteFile 'Perform the read


PUB EchoUntilPrompt |prompt
{{echoes the FIFO until the prompt is received.  Care must be used with this command so you don't
wait forever.  ALso, the test for a prompt is very simple and only looks for a > followed by at CR}}

  prompt:=FALSE 'Didn't see prompt yet
  
  repeat 'Keep going until command prompt
    Read(@result, 1) 'Get one character
    WaitUntilReady 'Wait for it to be ready    
    text.out(result) 'Echo to screen

    if result==">" 'See the prompt?
      prompt:=TRUE 
    elseif prompt and result:=13 'Seen the prompt and now a CR
      return 'We are done
    else
      prompt:=FALSE 'Keep waiting     
    
      
PUB EchoFIFO
{{Waits for the FIFO to fill and then echoes it to the screen}}

  WaitForFIFO 'Wait until there is data in the FIFO
  repeat while not GetStatusWord & NoData 'Gather up characters until empty
    Read(@result, 1) 'Get one character
    WaitUntilReady 'Wait for it to be ready    
    text.out(result) 'Echo to screen

PUB WaitUntilReady
{{Waits for the driver command to finish}}
  repeat while command


PUB WaitForFIFO
{{Waits until data is in the FIFO}}
  WaitUntilReady 'Make sure the driver is ready
  repeat while GetStatusWord & NoData 'Wait until FIFO full




DAT
   InitStr              byte "SCS",13, 0 'Short command set, binary
   ReadHeaderStr        byte RDF, $20, 0, 0, 0, 8, $0D 'Reads the stream file header
   DirFileStr           Byte DIR, $0D, 0





DAT

{##################################################################################################
This is the assembly driver for the Vinculum chip.  Big warning, the current data sheet for the
chip is wrong.  The SPICLK should idle high.  Data should be changed on the rising edge and read on
the falling edge.
}




                        org
SPIStart
WaitForCommand

'_________________________________________Wait for command_________________________________________


          mov           temp, ClkMask wz        'Gather up all of the outputs Z cleared
          or            temp, CSMask            'so that we can set the direction
          or            temp, OutMask
          muxnz         dira, temp              'Set the outputs

          mov           temp, InMask            'Grab the lone input
          muxz          dira, temp              'and set the direction for input



          rdlong        command, par wz         'check for a command
   if_z   jmp           #WaitForCommand         'Didn't get one


'___________________________________________Run Command____________________________________________

          mov           temp, par               'Get the HUB address of command block
          add           temp, #4                'Now look at the byte count
          rdlong        byteCount, temp         'Store it
          add           temp, #4                'Now the EEPROM address
          rdlong        eepromAddress, temp     'Store it
          add           temp, #4                'Now the buffer address
          rdlong        bufferAddress, temp     'Store it
                        


          cmp           command,#CMDStream wz
   if_e   call          #StreamDataSub          'Returns with Z set
   if_e   jmp           #CommandDone

          cmp           command, #CMDRead wz
   if_e   call          #ReadData
   if_e   jmp           #CommandDone

          cmp           command, #CMDStatus wz
   if_e   call          #ReturnStatus
   if_e   jmp           #CommandDone

          cmp           command, #CMDWriteString wz
   if_e   call          #WriteStringSub
   if_e   jmp           #CommandDone

          cmp           command, #CMDWriteFile wz
   if_e   call          #WriteFileSub
   if_e   jmp           #CommandDone

          cmp           command, #CMDReadFile wz
   if_e   call          #ReadFileSub
   if_e   jmp           #CommandDone

          cmp           command, #CMDWrite wz
   if_e   call          #WriteData
   if_e   jmp           #CommandDone


   if_e   jmp           #CommandDone



CommandDone
                    wrlong  zero, par           'Signal that we're done
                    jmp     #WaitForCommand




{*********************************ReturnStatus*****************************************************
This sub will read the status word and place it in byteCount
**************************************************************************************************}
ReturnStatus
          call          #ReadStatus             'Get the status word returns with Z set
          mov           temp, par               'Get the PAR
          add           temp, #4                'and point at the byte count
          wrlong        data, temp              'Save the status word there

ReturnStatus_ret
          ret
   


{*********************************************ReadData*********************************************
Reads a set number of bytes from the Vinculum to a buffer
**************************************************************************************************}
ReadData

          call          #ReadByte               'Pick up a byte
          wrbyte        data, bufferAddress     'Save it
          add           bufferAddress, #1       'Bump up the pointer
          djnz          byteCount, #ReadData wz 'repeat until done, Z set when done
          
ReadData_ret
          ret



{********************************************WriteData*********************************************
Writes a set number of bytes to the Vinculum
**************************************************************************************************}

WriteData
          rdbyte        data, bufferAddress     'Grab the byte
          call          #WriteByte              'Send it
          add           bufferAddress, #1       'Next byte
          djnz          byteCount, #WriteData wz'Until done
          
WriteData_ret
          ret


{*******************************************WriteString********************************************
Writes a null terminated string to the Vinculum
**************************************************************************************************}
WriteStringSub
          rdbyte        data, bufferAddress wz  'Grab the byte
   if_z   jmp           WriteStringSub_Ret      'A null, all done
   
          call          #WriteByte              'Send it
          add           bufferAddress, #1       'Next byte
          jmp           #WriteStringSub         'Cycle around

WriteStringSub_Ret
          ret

{********************************************CloseFile*********************************************
Closes the opened file
**************************************************************************************************}

CloseFile
          mov           data, #CLF                      'Send the command
          call          #WriteByte

          mov           data, #" "                      'Terminate it
          call          #WriteByte

          mov           bufferAddress, fileName         'Save off the filename
          call          #WriteStringSub                 'that we want to close
          call          #FlushCR                        'Empty the response
          
CloseFile_ret
          ret


{********************************************ReadFile**********************************************
The contents of a filename are transfered to a HUB location.  There is no error reporting, this is
strictly for a high-speed transfer
**************************************************************************************************}
ReadFileSub

          mov           fileName, bufferAddress 'Hang onto the filename address
          mov           streamLength, byteCount 'Save the byte count so it isn't trashed
          call          #OpenFileRead           'Open the file for reading

'_____________________________________________Get Prompt___________________________________________
          call          #ReadByte               'Get a prompt byte
          cmp           data, #">" wz           'Is this the good prompt?
          
   if_nz  jmp           #ReadFileError          'No, flush until CR
          call          #ReadByte               'Get the CR, we don't test it
          
'___________________________________________Start Read_____________________________________________
          call          #SendRDF                        'Command the number of bytes to get
          mov           byteCount, streamLength         'Get the length back into bytecount
          mov           bufferAddress, eepromAddress    'and the address too
          call          #ReadData                       'Read all the data back

ReadFileError
          call          #FlushCR                        'Empty the FIFO
          call          #CloseFile                      'Close the file when done
          
ReadFileSub_ret
          ret




{********************************************WriteFile*********************************************
The contents of HUB memory are written to a filename.  No error reporting
***************************************************************************************************}

WriteFileSub

          mov           fileName, bufferAddress 'Hang onto the filename address
          mov           streamLength, byteCount 'Save the byte count so it isn't trashed
          call          #OpenFileWrite          'Open the file for reading

'_____________________________________________Get Prompt___________________________________________
          call          #ReadByte               'Get a prompt byte
          cmp           data, #">" wz           'Is this the good prompt?
          
   if_nz  jmp           #WriteFileError         'No, flush until CR
          call          #ReadByte               'Get the CR, we don't test it

'___________________________________________Start Write____________________________________________

          mov           data, #WRF                      'Signal a write
          call          #WriteByte                      'Send it off

          mov           data, #" "                      'Space
          call          #WriteByte                      'Send it off
          
          mov           data, streamLength              'Get the length
          call          #SendDWord                      'Send it and terminate the command

          mov           byteCount, streamLength         'Get the length back into bytecount
          mov           bufferAddress, eepromAddress    'and the address too
          call          #WriteData                      'Do the write

WriteFileError
          call          #FlushCR                        'Empty the FIFO
          call          #CloseFile                      'Close the file when done

          test          data, #0
WriteFileSub_ret
      ret




{********************************************StreamData********************************************
First open the file pointed to as the source and then start streaming
**************************************************************************************************}
StreamDataSub

'____________________________________________Open File_____________________________________________
   
          mov           fileName, bufferAddress 'Hang onto the filename address
          call          #OpenFileRead           'Open the file for reading

'_____________________________________________Get Prompt___________________________________________
          call          #ReadByte               'Get a prompt byte
          cmp           data, #">" wz           'Is this the good prompt?
          
   if_nz  jmp           #StreamDataError        'No, flush until CR
          call          #ReadByte               'Get the CR, we don't test it


'___________________________________________Get File Header________________________________________

          mov           byteCount, #7                   'Command length
          mov           bufferAddress, ReadHeaderStr_   'Command location
          call          #WriteData                      'Write the command


          call          #ReadByte                       'Get the LB of length
          mov           streamLength, data              'Save the stream length

          call          #ReadByte                       'Get bits 8..15
          shl           data, #8                        'Shift into that position
          or            streamLength, data              'Toss it on
          
          call          #ReadByte                       'Get bits 16..23
          shl           data, #16                       'Shift into that position
          or            streamLength, data              'Toss it on

          call          #ReadByte                       'Get bits 24..31
          shl           data, #24                       'Shift into that position
          or            streamLength, data              'Toss it on



          mov           byteCount, #6                   'Skip over the sampling rate and prompt          
:Loop
          call          #ReadByte
          djnz          byteCount, #:Loop wz            'Until done




'___________________________________________Start Stream__________________________________________
          mov           byteCount, streamLength
          call          #SendRDF

'______________________________________________Stream_______________________________________________
          mov           bufferAddress, eepromAddress    'Get the address in the correct variable
          rdlong       streamAddr, bufferAddress        'Get the buffer pointer


StreamDataLoop
              'Loop through buffer until we find first null to fill
          mov          streamPtr, #32                           '# of bytes to check
          rdlong       streamAddr, BufferAddress                'Get the buffer pointer

StreamDataBufferLoop
          rdbyte        data, streamAddr                        'Get the current buffer data
          cmp           data, #StreamTerminator wz              'Is it null?
   if_z   jmp           #StreamDataContinue                     'Yes, fill it with data
          add           streamAddr, #1                          'Bump it up
          djnz          streamPtr, #StreamDataBufferLoop        'Continue looking
          jmp           #StreamDataLoop                         'Start at top of buffer again

              
StreamDataContinue
          call          #ReadByte                       'receive byte

                      '------ Store Byte
          wrbyte        data,streamAddr                 'store received byte into buffer
          cmp           data, #StreamTerminator wz      'Are you the terminator?
   if_z   jmp           #StreamDataError                'Yes, just flush
   
          djnz          streamLength, #StreamDataBufferLoop


StreamDataError
          call          #FlushCR                        'Empty the FIFO
          call          #CloseFile                      'Close the file when done
          
StreamDataSub_ret
          ret
          


{*********************************************SendRDF**********************************************
Sends the command to read the number of bytes in streamlength
**************************************************************************************************}

SendRDF

          mov           byteCount, #2                   'Command length, only read and space
          mov           bufferAddress, ReadHeaderStr_   'Command location
          call          #WriteData                      'Write the command for $0B, $20

          mov           data, streamLength               'Get the length
          call          #SendDWord                      'Send it and terminate the command

SendRDF_ret
          ret


{*******************************************SendDWord*********************************************
Will break a long in data into four bytes to send to the Vinculum
**************************************************************************************************}
SendDWord
          mov           byteCount, #4                   'Do this four times

:Loop
          rol           data, #8                        'Shift over for next byte of address
          call          #WriteByte                      'Send the single length byte
          djnz          byteCount, #:Loop               'All four bytes worth

          mov           data, #13                       'Terminate command
          call          #WriteByte                      'Send it off

SendDword_ret
          ret



{******************************************OpenFileWrite*******************************************
Opens a file for writing
***************************************************************************************************}
OpenFileWrite
          mov           data, #OPW              'Signal a file open
          jmp           #OpenFile               'Continue on                        


{******************************************OpenFileRead********************************************
Opens a file for reading
**************************************************************************************************}
OpenFileRead
          mov           data, #OPR              'Signal a file open
OpenFile
          call          #WriteByte              'Send it
          mov           data, #$20              'Add the space
          call          #WriteByte              'Send it
          call          #WriteStringSub         'Send the file open string

OpenFileRead_ret
OpenFileWrite_ret
          ret



{*********************************************FlushCR**********************************************
Reads the Vinculum chip until it sees a CR.  Best used to flush out error codes
**************************************************************************************************}
FlushCR
:Loop
          call          #ReadByte               'Get a byte
          cmp           data, #13 wz            'Until we get a CR
   if_nz  jmp           :Loop                   'Until done

FlushCR_ret
          ret





{********************************************ClockOut*********************************************
This sub will change the clock line from the idle high to a low and back high again
**************************************************************************************************}
ClockOut
          andn          outa, ClkMask           'and back low again 50nS
          or            outa, ClkMask           'Set the clock high 50nS
ClockOut_Ret
          ret




{********************************************ClockIn*********************************************
This sub will Clock data in by moving the CLK line from high to low and back high.    The Vinculum
is so fast that there shouldn't need to be a delay here
**************************************************************************************************}
ClockIn
          or            outa, ClkMask           'Set the clock high 50nS
          andn          outa, ClkMask           'and back low again 50nS


ClockIn_Ret
          ret




{*********************************************ReadByte*********************************************
Reads a single byte of data from the Vinculum and repeats the read if the ST flag is High (no new
data).
**************************************************************************************************}
ReadByte
          call          #ClockOut               'Clock out a null pulse to be safe
          call          #ClockOut               'Clock out a null pulse to be safe, idling high

          or            outa, CSMask wz         'Set CS line high
          or            outa, OutMask           'Output high for a start bit

          call          #ClockOut               'Clock the Start Bit out

          call          #ClockOut               'Clock out the R/W bit

          andn          outa, OutMask           'Data low for Read
          call          #ClockOut               'Clock out the address bit high for status

          mov           bitMask, #$80           'Seed the bit mask
          mov           data, #0                'Clear the data to start


'____________________________________________ReadLoop______________________________________________
:Loop
          call          #ClockIn                'Get the bit clocked in
          mov           tempBit, ina            'You can't test INA directly
          test          tempBit, InMask wz
   if_nz  or            data, bitMask           'High, so set the mask

          shr           bitmask, #1 wz          'Next bit
   if_nz  jmp           #:loop                  'Until done

'___________________________________________TestStatus_____________________________________________
          call          #TestStatus
   if_nz  jmp           #ReadByte               'Didn't get a byte, try again


ReadByte_Ret
          ret


{********************************************ReadStatus********************************************
This sub will read the status word
***************************************************************************************************}
ReadStatus
          call          #ClockOut               'Clock out a null pulse to be safe
          call          #ClockOut               'Clock out a null pulse to be safe, idling high

          or            outa, CSMask wz         'Set CS line high
          or            outa, OutMask           'Output high for a start bit

          call          #ClockOut               'Clock the Start Bit out

          call          #ClockOut               'Clock out the R/W bit

          call          #ClockOut               'Clock out the address bit high for status

          mov           bitMask, #$80           'Seed the bit mask
          mov           data, #0                'Clear the data to start


'____________________________________________ReadLoop______________________________________________
:Loop
          call          #ClockIn                'Get the bit clocked in
          mov           tempBit, ina            'You can't test INA directly
          test          tempBit, InMask wz
   if_nz  or            data, bitMask           'High, so set the mask

          shr           bitmask, #1 wz          'Next bit
   if_nz  jmp           #:loop                  'Until done

'___________________________________________TestStatus_____________________________________________
          call          #TestStatus
          test          data, #0 wz             'Force a Z flag
          
ReadStatus_ret
          ret                                                
          



{*********************************************WriteByte********************************************
Writes a single byte to the Vinculum and repeats if the status bit was high
***************************************************************************************************
}
WriteByte
          call          #ClockOut               'Clock out a null pulse to be safe
          call          #ClockOut               'Clock out a null pulse to be safe, idling high

          or            outa, CSMask wz         'Set CS line high
          or            outa, OutMask           'Output high for a start bit

          call          #ClockOut               'Clock the Start Bit out

          andn          outa, OutMask           'Data low for a write
          call          #ClockOut               'Clock out the R/W bit

          call          #ClockOut               'Clock out the address low for data

          mov           bitMask, #$80           'Seed the bit mask


'____________________________________________WriteLoop_____________________________________________
:Loop
          test          bitMask, data wz        'Is the bit high or low
   if_z   andn          outa, OutMask           'Low, so clear the data line
   if_nz  or            outa, OutMask           'High, so set the data line
          call          #ClockOut               'Clock the bit out

          shr           bitmask, #1 wz          'Next bit
   if_nz  jmp           #:loop                  'Until done

'___________________________________________TestStatus_____________________________________________
          call          #TestStatus             'Get the status bit in the Z flag
   if_nz  jmp           #WriteByte              'Cycle until sent
          
WriteByte_Ret
          ret



{********************************************TestStatus********************************************
Clocks out the single status bit and returns with its value in Z

A 1 is old data
A 0 is new data

So Z is good data
**************************************************************************************************}
TestStatus
          call          #ClockIn                'Get the bit clocked in
          mov           tempBit, ina            'You can't test INA directly
          test          tempBit, InMask wz

          call          #ClockOut               'Return to idle
          andn          outa, CSMask            'Push the CS back low again
          call          #ClockOut               'Return to idle

TestStatus_Ret
   ret






DAT

'__________________________________________Command Block___________________________________________
'Keep all of these in order
command                 long    0               'What should the SPI bus do?
byteCount               long    0               'Hominy bytes to transfer
eepromAddress           long    0               'Address in the memory stick
bufferAddress           long    0               'Address in the HUB
'___________________________________________________________________________________________________


'Spin Startups
ClkMask                 long    0               'Spin will store the Clk pin mask here
CSMask                  long    0               'The CS mask here
OutMask                 long    0               'The Out mask here
InMask                  long    0               'and the In mask here


'Constants
Zero                    long    0               'Constant
ReadHeaderStr_          long    0               'Loaded at start with hub address of message



'Variables
temp                    res     1               'Scratchpad variables
bitMask                 res     1               'Mask for data in or out
data                    res     1               'Data received or sent
tempBit                 res     1               'Temporary bit storage for I/O
streamAddr              res     1               'Address of stream buffer
streamPtr               res     1               'streaming buffer position
streamLength            res     1               'How long is the stream
streamCnt               res     1               'How many bytes have been read
fileName                res     1               'Pointer to the file name

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