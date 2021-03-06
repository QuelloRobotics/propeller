{
    This demo program will allow you to control up to 16 stepper motors with one cog.
    It requires a step & direction type driver so each motor requires 2 output pins.
    There is no acceleration/deceleration implemented in this program.

    To move a motor, just set the variableX with the number of stepper counts you want it to
    move to.
    This is an Absolute position, not a relative amount to change.
    Assuming it is at "Zero", if you set the variable to 100, it will move to 100.
    Then if you want it to move to 300, it will spin an additional 200 counts since 300-100=200.
    If you want it to go back to "Zero", it would spin 300 counts in the opposite direction.

    I/O pin usage is not important, but they must be one contiguous block of pins.
    The enable pin is up to you to implement if required.
     
    You might have to slow down both the step rate and the strobe width if your stepper motor
    or controller can't handle the speed.
        
    There are no limit switches used in this program.
    In this demo, I just turn the motors backwards to a physical stop to get a fixed reference point
    and consider it to be "Zero".
    


    I/O P10 - Step Pin 1
    I/O P11 - Direction Pin 1 

    I/O P12 - Step Pin 2
    I/O P13 - Direction Pin 2 

    I/O P14 - Step Pin 3
    I/O P15 - Direction Pin 3 

    I/O P16 - Step Pin 4
    I/O P17 - Direction Pin 4 

    I/O P18 - Step Pin 5
    I/O P19 - Direction Pin 5 

    I/O P20 - Step Pin 6
    I/O P21 - Direction Pin 6 

    I/O P22 - Step Pin 7
    I/O P23 - Direction Pin 7

    I/O P24 - Step Pin 8
    I/O P25 - Direction Pin 8 
}



CON
    _clkmode        = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
    _xinfreq        = 5_000_000

    MotorCnt        = 8         ' How many motors are we using

' Motors must be set up using a group of contiguous pins starting at Step1Pin

    StepPin1        = 10+0      ' Movement happens on the Falling edge of our step pulse which is then    
                                '  inverted through driver transistor = rising edge ( Low for 0.5 uS)
                                '  for Superior SD200 step driver.  
    DirPin1         = 10+1      '  Bit set for Negative direction Move, Bit clear for Positive direction move

    StepPin2        = 10+2
    DirPin2         = 10+3
    StepPin3        = 10+4
    DirPin3         = 10+5
    StepPin4        = 10+6
    DirPin4         = 10+7
    StepPin5        = 10+8
    DirPin5         = 10+9
    StepPin6        = 10+10
    DirPin6         = 10+11
    StepPin7        = 10+12
    DirPin7         = 10+13
    StepPin8        = 10+14
    DirPin8         = 10+15
    


VAR
        ' Don't change the order of these variables.
        ' You can delete unused "sets" of variables (Value8 & MotorAt8 = a set for example)
        
        long    Value1      ' Motor Value #1 (the value we want the motor to move to)                
        long    Value2      ' Motor Value #2 (the value we want the motor to move to)
        long    Value3      ' Motor Value #3 (the value we want the motor to move to)
        long    Value4      ' Motor Value #4 (the value we want the motor to move to)
        long    Value5      ' Motor Value #5 (the value we want the motor to move to)                                        
        long    Value6      ' Motor Value #6 (the value we want the motor to move to)               
        long    Value7      ' Motor Value #7 (the value we want the motor to move to)                  
        long    Value8      ' Motor Value #8 (the value we want the motor to move to)                  
        long    MotorAt1    ' Where motor 1 is currently at
        long    MotorAt2    ' Where motor 2 is currently at
        long    MotorAt3    ' Where motor 3 is currently at
        long    MotorAt4    ' Where motor 4 is currently at
        long    MotorAt5    ' Where motor 5 is currently at
        long    MotorAt6    ' Where motor 6 is currently at
        long    MotorAt7    ' Where motor 7 is currently at   
        long    MotorAt8    ' Where motor 8 is currently at   

        long    MotorStack[30]          ' Stack Space for Motor Cog
   
  
PUB Start   | tmp, randomvalue

    ' Rotate backwards to find physical stop 
    repeat tmp from 1 to MotorCnt   ' Rotate backwards to find physical stop
        long[@MotorAt1+(tmp-1)*4]:=400 ' Seed motor initial value to a high Positive value so it will return to 0 CCW     
        long[@Value1+(tmp-1)*4]:=0      ' Seed process variables with 0      

    cognew (MotorControl, @MotorStack)    ' Start the Cog for controlling motors
    waitcnt(clkfreq*2+cnt)                ' Wait for steppers to return to 0

    repeat

        ' Do process stuff here
        ' update variables Value1 through Value6
        ' then call MoveMotors to have them move

        ' for fun, lets invent some random value
        repeat tmp from 1 to MotorCnt   ' update all motors
        
            ' we will only update if the motor has completed its move but this is not necessary
            if long[@Value1+(tmp-1)*4]==long[@MotorAt1+(tmp-1)*4]
                ' get a random value                 
                randomValue?
                long[@Value1+(tmp-1)*4]:= randomvalue / 20000000 ' set the ValueX to the new value
                ' let the MotorControl do the move
    

PRI MotorControl | channel
' Move all motors from where they are (MotorAtX) to ValueX
' Update the MotorAtX variables along the way.

    dira[StepPin1..DirPin5]~~       ' Set all Pins as outputs
    outa[StepPin1..DirPin5]~~       ' Set All Pins HIGH, we don't care about direction pin levels yet


    ' Always try to keep MotorAtX equal to ValueX
    repeat

        'waitcnt(1000+cnt)                           ' Delay while stepping might be necessary for slow motors

        repeat channel from 0 to (MotorCnt-1)
            if long[@Value1+(channel*4)]<>long[@MotorAt1+(channel*4)]
                if long[@Value1+(channel*4)]=<long[@MotorAt1+(channel*4)]
                    outa[DirPin1+(channel*2)]~
                    outa[StepPin1+(channel*2)]~             ' Set Step pin LOW to step motor
                    long[@MotorAt1+(channel*4)]--
                else
                    outa[DirPin1+(channel*2)]~~
                    outa[StepPin1+(channel*2)]~             ' Set Step pin LOW to step motor
                    long[@MotorAt1+(channel*4)]++

'                waitcnt(400+cnt)                           ' Delay while strobing the stepper driver, might be necessary
                outa[StepPin1+(channel*2)]~~        ' Reset Step pin HIGH
         
    
                                                                                          