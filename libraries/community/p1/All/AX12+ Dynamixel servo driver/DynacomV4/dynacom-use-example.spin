''                                             example use of DynaComV4           
Con                                      
  _clkmode        = xtal1 + pll16x       
  _xinfreq        = 5_000_000            
                                         
Var                                      
  long a
  long b
                                      
Obj                                      
  dy : "dynacomv4"
                                     
Pub Main

  'example - start dynacom driver using propeller p8 (specify propeller i/o# dynamixels are attached to) @ 1m baudrate
  'dy.start(8, 1_000_000)
    

  'example - get alarm/error byte from servo
  'a := dy.getalarmbyte

  'example - get current position for servo id#2 into 'b'
  'b := dy.getsrvpos(2)


  'example - get servo id#3 current temperature in celsius into 'b' 
  'b := dy.getsrvtmp(3)                                              
    

  'example - get current torq for servo id#4 into 'a'              
  'a := dy.getsrvtrq(4)       (returns +/- # depending on direction of torq)

  'example - get address of _rxbuffer
  'a := dy.getrxbuffadd                                             
                                                                    
                                                                    
  'example - get servo voltage in volts X 10 for servo id#1 into 'b'    
  'b := dy.getsrvvlt(1)                                            


  'example - set servo id#1 to position 512    positions available from 0 to 1023                
  'dy.setsrvpos(1, 512)                                                                           
    

  'example - set servo id#4 'moving speed' to 100     servo mode speeds: 0 = full speed,  1 - 1023 = 0 to full speed
  'dy.setsrvspd(4, 100)                               continuous rotation mode speeds: 0 - 1023 ccw, 1024 - 2047 cw

  'example - set all attached servos speed to 300
  'dy.setsrvspdall(300)

  'example - set a servo to servo mode
  'dy.setservomode(3)   (sets servo id#3 to servo mode)

  
  'example - set servo mode for all attached servos
  'dy.setservomodeall   (sets all attached servos to servo mode)

  
  'example - set a servo to continuous rotation
  'dy.setcontinrotation(4)    (set servo id#4 to continuous rotation)

  
  'example - set all attached servos to continuous rotation
  'dy.setcontrotatall   (set all attached servos to continuous rotation) 

  
  'example - turn off torq for all servos             
  'dy.srvalltrqoff


  'example - turn on torq for all servos
  'dy.srvalltrqon

  'example - turn off torq for servo id#5
  'dy.srvtqoff(5)


  'example - turn on torq for servo id#1
  'dy.srvtqon(1)
  
  
  'example - change currently attached servo to id#2   ******WARNING THIS WILL CHANGE ALL ATTACHED SERVO(S) TO ID# SPECIFIED******
  'dy.chngid(2)

'---------------------------------------------------------------------------------------------------------------------------------------------------------------                                       
                 ' Dynamixel instruction methods

  'example - using dynamixel writedata instruction to set servo id#1 @address 30 to position 512 (WILL WRITE LOW/HIGH BYTES FOR YOU)
  'dy.writedata(1, 30, 512)


  'example - using dynamixel readdata instruction to read 2 bytes from servo id#1 address 36 current position into 'a'
  'a := readdata(1, 36, 2)


  'example - using dynamixel syncwrite instruction to move 2 servos at the same time
  '                      Example                                    
  ' set servo id 1 goal position to 562 at 100 moving speed         
  ' set servo id 2 goal position to 462 at 100 moving speed         
  ' execute syncwrite command                                       
  '                                                                 
  'dy.setbabf(0, 1)       '1st servo id#                           
  'dy.setbabf(1, 50)      'lowbyte position                        
  'dy.setbabf(2, 2)       'high byte position                      
  'dy.setbabf(3, 64)      'low byte speed                          
  'dy.setbabf(4, 0)       'high byte speed                         
  'dy.setbabf(5, 2)       '2nd servo id#                           
  'dy.setbabf(6, 206)     'low byte position                       
  'dy.setbabf(7, 1)       'high byte position                      
  'dy.setbabf(8, 64)      'low byte speed                          
  'dy.setbabf(9, 0)       'high byte speed                         
  'dy.syncwrite(2, 30, 4) 'perform syncwrite of above settings     


  'example - using dynamixel regwrite instruction to set up different servos and wait until you call the action command
  '                                   Example                               
  '                                                                         
  '      Set ID 1 goal position register to 562 with regwrite               
  '      Set ID 2 goal position register to 462 with regwrite               
  '      execute action command                                             
  '                                                                         
  'dy.setbabf(0, 50)           'set goal position to 562                   
  'dy.setbabf(1, 2)            '                                           
  'dy.regwrite(1, 30, 2)       'write id#1 goal position(30) - 2 bytes     
  'dy.setbabf(0, 206)          'set goal position to 462                   
  'dy.setbabf(1, 1)            '                                           
  'dy.regwrite(2, 30, 2)       'write id#2 goal position(30) - 2 bytes     
  'dy.action                   'perform above regwrites                    
                                                                           

  'example - using dynamixel reset instruction to reset currently attached servo(s) to factory baud, speed, id
  'dy.reset($fe)


  'example - using dynamixel ping instruction to query servo id#1
  'dy.ping(1)   returns true(-1) if servo id#1 is present with no error's, or the error byte if servo has an error
  
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