{{ Clock.spin
─────────────────────────────────────────────────
File: clock.spin
Version: 1.0
Copyright (c) 2014 Joe Lucia
See end of file for terms of use.

Author: Joe Lucia                                      
─────────────────────────────────────────────────

Clock Object with individual 5 timers, no cog, call Update periodically 

}}
var
  long  ClockMilliseconds
  long  ClockMillisecondsR      '' total milliseconds since Start, does not get reset      
  long  ClockSeconds
  long  ClockSecondsR           '' total seconds since Start, does not get reset
  long  ClockMinute
  long  ClockMinutesR
  long  ClockHour
  long  ClockDay
  long  ClockMonth

  long  isRunning
  long  lastCnt

  long  ticksperms

  long  ClockTimers[20]         ' 5 timers, 4 longs each = Hrs,Min,Sec,Milli
    
pub Start
  ticksperms := clkfreq/1000                                                    
  ResetC
  ClockMillisecondsR:=ClockSecondsR:=0
  longfill(@ClockTimers, 0, 20)                         ' 5 timers, 4 longs each
  isRunning:=true
  return isRunning

pub Stop
  isRunning:=false
  return isRunning

pub Resume
  lastCnt:=cnt
  isRunning:=true
  return isRunning

pub Update | c, t                                       '' Update running counters
  if not isRunning
    return

  repeat while (c:=cnt-lastCnt) => ticksperms
    ClockMilliseconds++
    ClockMillisecondsR++
    repeat t from 0 to 3
      ClockTimers[(4*t)+3]++
    lastCnt+=ticksperms
    
  repeat while ClockMilliseconds => 1000
    ClockSeconds++
    ClockSecondsR++
    repeat t from 0 to 3
      ClockTimers[(4*t)+2]++
    ClockMilliseconds-=1000
  repeat while ClockSeconds => 60
    ClockMinute++
    ClockMinutesR++
    repeat t from 0 to 3
      ClockTimers[(4*t)+1]++
    ClockSeconds-=60
  repeat while ClockMinute => 60
    ClockHour++
    repeat t from 0 to 3
      ClockTimers[(4*t)]++
    ClockMinute-=60
  repeat while ClockHour => 24
    ClockDay++
    ClockHour-=24
   
CON '' Timers
pub TMilliseconds(t)
  Update
  return ClockTimers[(4*t)+3]

pub TSeconds(t)
  Update
  return ClockTimers[(4*t)+2]

pub TMinutes(t)
  Update
  return ClockTimers[(4*t)+1]

pub THours(t)
  Update
  return ClockTimers[4*t]

CON '' Current Time
pub Milliseconds
  Update
  return ClockMilliseconds

pub Seconds
  Update
  return ClockSeconds

pub Minute
  Update
  return ClockMinute

pub Hour
  Update
  return ClockHour

pub Day
  Update
  return ClockDay

pub TimeInSeconds
  Update
  return ClockSecondsR

pub TimeInMinutes
  Update
  return ClockMinutesR

pub TimeInMilliseconds
  Update
  return ClockMillisecondsR

CON '' Set/Reset the Clock
pub Set(d, h, m, s)                                     '' Set the Clock
  ClockDay:=d
  ClockHour:=h
  ClockMinute:=m
  ClockSeconds:=s
  ClockMilliseconds:=0
  lastCnt := cnt

pub TReset(t)   '' Reset a Timer
  longfill(@ClockTimers[4*t], 0, 4)

pub ResetC      '' Reset the Clock
  ClockMilliseconds:=ClockSeconds:=ClockMinute:=ClockHour:=ClockDay:=0
  ClockMillisecondsR:=ClockSecondsR:=ClockMinutesR:=0
  lastCnt:=cnt

CON '' Delays
pub Delay(ms) | x
  x := ClockMillisecondsR
  repeat until (ClockMillisecondsR-x) > ms 
    Update
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