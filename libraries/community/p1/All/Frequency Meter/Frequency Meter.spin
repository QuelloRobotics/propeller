{{

Frequency Meter 0.4
By: Dave Fletcher

This object monitors the clock frequency present on a specified pin.

}}
CON
  SAMPLESIZE            = 64 ' Higher == more samples == more precision. 
  BUFFERSTART           = 2  ' buffer[0] is a lock; buffer[1] is a pin mask.
  TOTALSIZE             = SAMPLESIZE + BUFFERSTART
  BUFFEREND             = TOTALSIZE - 1 
  
VAR
  LONG cog
  LONG buffer[TOTALSIZE]

PUB start
  {{ Starts a cog. }}
  stop
  buffer[0] := 1 ' Start up in waiting state.
  result := cog := cognew(@detector, @buffer) + 1

PUB report(pin) | ctr, tmp 
{{
  Runs a test cycle and reports. Blocks until test is complete.

  Note that if the specified pin sticks high or low and never pulses (or if it
  pulses for a fewer number of times than SAMPLESIZE), this method will never
  return. This is due to the WAITPNE assembly instruction which is currently
  used for detection. Perhaps some other method would allow timeout. Room for
  future improvement here.
}}
           
  ' Set pin we want a report on.                               
  buffer[1] := 1 << pin

  tmp := 1
  repeat while tmp
  
    ' Unlock the buffer and start sampling.                               
    buffer[0] := 0

    ' While buffer[0] is zero, we are waiting for output.                              
    repeat while buffer[0] == 0

    ' Sample crossed 32 bit bounds of the cnt register, chuck it
    ' and take another sample. Since my poor brain can't figure out
    ' how to normalize this easily, chuck it and try again ;-)                                             
    if buffer[BUFFERSTART] > buffer[BUFFEREND]                                     
      next                                                                         

    ' Sample was good, break out of this loop.
    tmp := 0
                                                                           
  ' Okay, we have a buffer full of data now. Process and return result.                
  repeat ctr from BUFFERSTART to BUFFEREND - 1
    tmp += buffer[ctr + 1] - buffer[ctr]                                      
  return CLKFREQ / (tmp / SAMPLESIZE)

PUB stop
  {{ Stops the cog if it was running. }}
  if cog
    cogstop(cog - 1)
    cog := 0
    
DAT
                        ORG 0

detector
  :mainloop             MOV :t1, par            ' get buffer pointer
                        MOV :lock, :t1          ' set lock pointer
                        ADD :t1, #4             ' offset for lock
   
                        WRLONG :one, :lock      ' assert waiting state
  :wait                 RDLONG :t2, :lock        
                        TJNZ :t2, #:wait        ' wait for clear

                        RDLONG :pin, :t1        ' set pin mask
                        ADD :t1, #4             ' offset for pin mask

                        MOV :ctr, #SAMPLESIZE   ' set counter
  :loop                 WAITPNE :zero, :pin     ' wait for pos edge
                        WAITPEQ :zero, :pin     ' wait for neg edge (pulse)
                        MOV :t2, cnt            ' capture time
                        WRLONG :t2, :t1         
                        ADD :t1, #4             ' next buffer position
                        DJNZ :ctr, #:loop       ' capture loop

                        JMP #:mainloop          ' main loop
  
  :ctr                  LONG                    0
  :lock                 LONG                    0
  :pin                  LONG                    0
  :t1                   LONG                    0
  :t2                   LONG                    0
  :zero                 LONG                    0
  :one                  LONG                    1

                        FIT 496