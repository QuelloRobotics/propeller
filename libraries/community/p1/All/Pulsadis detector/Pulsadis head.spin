{{
The mains input signal is fed to the ADC as described in the parallax litterature.
In this case, I used a 230 Volts to 6 Volts transformer feeding a potentiometer,
the cursor of which feeding the ADC via a series of R= 150 K and C = 220 K.
The French version is connected directly to the mains via a capacitive divider, providing at the same time an
attenuated value of the mains, but also feeding the chip via a rectifier and an voltage regulator.
The ADC value is based on 10 bits and should then vary between 0 and 1023.
You should tune the potentiometer to have minimal values under 200 and maximal values over 800.
Make sure you don't clip the signal.
On my side I used the great ViewPort tool and looked to the ADC value like on a scope.
Otherwise it should be easy to launch an extra Cog analyzing value of ADC and lighting LEDs
when signal goes outside desired ranges. 
}}

CON
_clkmode = xtal1 + pll16x
_clkfreq = 80_000_000

ADCbits = 10       ' ADC resolution : 10 bits, max sampling 78 KHz, OK for Pulsadis application  (8 bits in original software)
                                                                                
' I/O pins
fbpin               = 7             ' ADC converter feedback pin (BPIN)
adcpin              = 6             ' ADC converter feedin pin (APIN)
testpinA            = 26            ' to put a scope for debug, same pins as keyboard connector if any
testpinB            = 27            ' to put a scope for debug, same pins as keyboard connector if any

' pins used to communicate serially with controller if any
rxpin = -1                           ' receiver disabled 
txpin = 25
baudrate = 19200

TicksPerSample      = 113800        ' adjusted number of clock ticks loop 700 times per second 

' various tresholds
Treshold1       = 175           ' used in 175 Hz detector in extracting 175 Hz from noise
Treshold2       = 4             ' number of positive measures needed in start bit detection to declare a valid startbit
Treshold3       = 6             ' used in collectframe method: max number of positive pulses allowed during expected silence 
Treshold4       = 3             ' to decide whether we have enough positive samples to declare a bit one
Treshold5       = 12            ' max num of positive pulses allowed in header silence (after startbit)

' state machine statii
#1, Idle, StartbitReceived,HeaderReceived, FrameCollected, Error, UnknownError

' error codes
#1, NoError, HeaderSpaceTooNoisy, InterBitGapTooNoisy  ', ADCoverdriven  , ADCunderdriven

  yes           = 1
  no            = 0

OBJ
   com: "Full-Duplex_COMEngine.spin"  
VAR                             
long status                     ' trivial state machine status
long ADCvalue                   ' where ADC stores conversion result
long mespos                     ' number of positive measures counter
long maxmespos                  ' keep track of maximum reached
long SubCarrierPresent          ' contains YES or NO
long vec[40]                    ' used to store number of positive pulses for each bit in the frame
long vec2[40]                   ' same but for the spaces between bits, should ideally be zero
long vecpulse[32]               ' used to store timing in the pulse stretcher method
long endofstartbittimestamp     ' remember when startbit finished 
long endofheadertimestamp       ' when end of header is expected
long startdatatimestamp         ' when start of data expected
long errorcode                  ' main error code
long Stack[30]

PUB start
  com.COMEngineStart(RXpin, TXpin, baudRate)  ' be ready to talk to the controller
  
  Cognew(@asm_entry, @ADCvalue) ' launch ADC program in a new COG, result shall be into ADCvalue
  
  Cognew(PulseStretcher,@stack)' load the pulse stretcher   (mainly used for debug)

  Status := Idle
  repeat                                 ' Main loop: very simple Finite State Machine    
    case status
      Idle:                     WaitStartbit
      StartBitReceived:         HeaderSpace
      HeaderReceived:           CollectFrame
      FrameCollected:           ProcessFrame
      Error:                    ProcessError
      Other:                    ProcessUnknownError   ' should never happen but ...

Pub Waitstartbit 
  com.writestring(string(" waiting for start bit",13))  
  mespos := 0
  maxmespos := 0
 
  repeat
    Detect175Hz                          ' check for presence of 175 Hz during 200 milliseconds

    if SubCarrierPresent == Yes          ' if yes
      mespos++                             ' increment counter of positive measures
      maxmespos := mespos                  ' and keep track of the maximum consecutive ones
      endofstartbittimestamp := cnt        ' take note of last positive sample  timing
    else
      mespos := 0                        ' if no simply reset the counter

    ' now, if 175 HZ not present (or anymore present) in the last measure
    ' AND we had a consecutive series of positive measures > threshold2
    ' then we can consider having received the pulsadis frame startbit
    if mespos == 0 and maxmespos => Treshold2
      status := StartBitReceived     ' notify status
          com.writebyte(13)
          com.writestring(string(" Start bit detected, # of consecutive pulses : "))
          com.writebyte("0"+ maxmespos)
          com.writebyte(13)
     return      

Pub HeaderSpace
{ We enter thisd method just after having received a startbit
We are supposed to have silence during 2.75 seconds after end of this startbit
We could simply nsleep for that time, however we will check for 2.2 seconds if we don't have
175 Hz present, which would indicate an error condition
Then we wait without checking till the expected end of first silence }
  com.writestring(string(" Check header",13))
  endofheadertimestamp := endofstartbittimestamp + 204_000_000 ' preset: 2.75 seconds after end of startbit  ===== debug ====
  mespos := 0
  repeat 11                     ' this will take 11 * 200 milliseconds
    Detect175Hz
    if SubCarrierPresent == Yes
      mespos++                  ' to check is this silence period is not too noisy
      
  waitcnt(endofheadertimestamp) ' wait till Header finished

  if mespos >  treshold5   ' too much noise?
    status := error                                        ' yes
    errorcode := HeaderSpaceTooNoisy
      com.writebyte(13)
      com.writestring(string(" too much noise on header space, # of pulses : "))
      com.writebyte("0"+mespos)
      com.writebyte(13)
  else
    status := HeaderReceived                               ' OK
    errorcode := NoError
 
Pub CollectFrame    |  i  , FrameIndex
{
Now we will simply repeat 40 times 2.5 serconds instructions to check if the first second
contains enough 175 Hz samples to declare we have a bit "one" or not and to check if the following
1.5 seconds of silence is not too noisy, in which case we would raise an error condition
The vector VEC will contain the number of positive samples per bit
The vector VEC2 will contain the same for interbit gap, it should ideally be zero
}
  com.writestring(string(" collecting frame",13))
  startdatatimestamp := endofheadertimestamp
  repeat frameindex from 0 to 39                                 ' collect 40 times
    mespos := 0                                         
    repeat 5                        ' sample five times 200 milliseconds: we detect for one second
      Detect175Hz                   ' is the sample positive ?
      if SubCarrierPresent == Yes
        mespos++                    ' increase counter of positive samples
    vec[frameindex] := mespos       ' store number of positive samples 

    mespos := 0                     ' space is expected to be without positive samples for 1.5 seconds 
    repeat 6                        ' so we will tally the presence of 175 HZ where it should not be for 1.2 seconds  
      Detect175Hz
      if SubcarrierPresent == Yes                            
        mespos++
    vec2[frameindex] := mespos

    startdatatimestamp := startdatatimestamp + 200_000_000     ' Then we keep the system sleeping until the end of the space 
    
    if mespos > treshold3            ' if expected silences too noisy, then raise the flag
      status := error
      errorcode :=  interbitgaptoonoisy

    waitcnt(StartDataTimestamp) ' leave collect frame finish even in case of error, to avoid false startbits
    
  status := FrameCollected

Pub Detect175Hz    | i , Nextcnt , cumultot, cumul[5]
{ This is the heart of the program, where we will sample the input signal 140 times during a
period of 200 milliseconds. After some computations we will decide whther or not we consider
that 175 Hz is present and return from the method with a YES or NO in the Subcarrierpresent
variable. 
}
  ' init variables
  Repeat i from 1 to 4
    Cumul[i] := 0
  i := 0
  
  repeat 140           'sampling loop: 140 samples in a total of 200 milliseconds
    Nextcnt := cnt     ' save current timestamp
    i++                            ' increment index
    cumul[i] := cumul[i] + ADCvalue  'add input voltage in the right vector element
    if i  > 3
      i := 0
    waitcnt(NextCnt + TicksPerSample )     ' wait for end of sampling period

  Cumultot := ||(cumul[1] - cumul[3]) + ||(cumul[2] - cumul[4]) 
   pulse(testpina,1)     ' debug, let's show we are alive

  if cumultot => Treshold1             ' do we have enough Cumultot to declare that 175 Hz is present ?
    pulse(testpinb,1)                  ' yes, lets' show we have positive detection
    SubCarrierPresent := Yes           ' and declare it to the calling procedure
  else
    SubCarrierPresent := No            ' otherwise declare nothing special
 
Pub ProcessFrame  |  i
{
As the significance of the bits is different from country to country and even from city to city,
we can only provide the pattern of the 40 bits in a frame. This is done via serial communications to
an external terminal or to another Propeller (see pulsadis controller.spin file).
}
  com.writestring(string(" processing frame",13))
  repeat i from 0 to 39                          ' print number of pulses during bit transmission time
    com.writebyte(vec[i]+"0")
  com.writebyte(13)

  repeat i from 0 to 39                          ' print number of parasitic pulses during expected silence time
    com.writebyte(vec2[i]+"0")
  com.writebyte(13)  

  repeat i from 0 to 39                          ' decide whether bit is Mark or Space
    if vec[i] > Treshold4
      vec[i] := 1
    else
      vec[i] := 0
    
  repeat i from 0 to 39                         ' print frame graphic image
    if vec[i]  == 1
      com.writebyte("+") 
    else
      com.writebyte("-")
  com.writebyte(13)
  
  status := idle                                 ' wait for next frame start      

Pub ProcessError
  case ErrorCode
    NoError:                    com.writestring(string(" No Error, what happens?",13))
    HeaderSpaceTooNoisy:        com.writestring(string(" Header Space too noisy",13))
    interbitgaptoonoisy:        com.writestring(string(" Inter-bit gap too noisy",13))
    Other:                      com.writestring(string(" Other error ?????",13))
  Errorcode := NoError                                  ' reset error code
  Status := Idle                                        ' return to idle loop
  
Pub ProcessUnknownError
  com.writestring(string(" Unknown error",13))
  Errorcode := NoError                                  ' reset error code
  Status := Idle                                        ' return to idle loop 

pub pulse(pin,duration)   ' duration in blocks of 5 milliseconds 
    vecpulse[pin] := duration

pub PulseStretcher   | i
 ' this method desynchronizes its call from the pulse duration in order to make sure the signal is long enough to
  ' be visible on a scope, but not blocking the program during that time 
  ' one time unit means 5 milliseconds: because downto 1 millisecond would require to do it in assembler
  ' SPIN is too slow. I just finish debugging the PASM version and will publish it on OBEX
  repeat
    repeat i from 0 to 31
      if vecpulse[i] > 0
        dira[i]~~                 ' make sure pin as output  
        outa[i]~~                 ' pin up
        vecpulse[i] := vecpulse[i] - 1
      else
        outa[i]~                ' pin down 
        'dira[i]~                ' release pin         ' debug       
    waitcnt(cnt+400_000) ' for 5 milliseconds. Don't try to go downto 1 millisecond: SPIN is too slow.


DAT
' Assembly program  for ADC
' standard from counters applications examples in the Parallax documentation
org
asm_entry mov dira,asm_dira 'make pins (ADC) and  (DAC) outputs
        movs ctra,#adcpin 'POS W/FEEDBACK mode for CTRA
        movd ctra,#fbpin
        movi ctra,#%01001_000
        mov frqa,#1
        mov asm_cnt,cnt 'prepare for WAITCNT loop
        add asm_cnt,asm_cycles
:loop   waitcnt asm_cnt,asm_cycles 'wait for next CNT value
        mov asm_sample,phsa 'capture PHSA and get difference
        sub asm_sample,asm_old
        add asm_old,asm_sample
        wrlong asm_sample, par 'write the value to main memory
        jmp #:loop 'wait for next sample period
' Data
asm_cycles    long |< ADCbits - 1 'sample time
asm_dira      long |< fbpin 'output mask
asm_cnt       res 1
asm_old       res 1
asm_sample    res 1