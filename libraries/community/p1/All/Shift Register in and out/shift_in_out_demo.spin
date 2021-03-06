CON
  _clkmode = xtal1 + pll16x                             ' use crystal x 16
  _xinfreq = 5_000_000                                  ' 5 MHz cyrstal (sys clock = 80 MHz)


  '##Set Pin Numbers
  
  SR_CLOCK = 21
  SR_STROBE = 20
  SR_DATA  = 23
  {
  SR_CLOCK = 18
  SR_STROBE = 17
  SR_DATA  = 16
  }  
  '## set number of inputs and outputs
  num_inputs = 16
  num_outputs = 8

obj
  shift : "shift input and output"
  debug : "simpledebug"

pub main | data_out ,data_in ,i
   debug.start(115200) ' Enable Serial debug))       
   shift.init(sr_clock,sr_strobe,sr_data,num_inputs,num_outputs) 
   waitcnt(clkfreq +cnt)   '###wait to enable PST
   

   data_out := %1110_1010_1110_1010
   data_out := %0000_0000_0000_0001
   data_out := %0000_0001

   repeat      
       'data_out <-= 1  ''#cycle outputs
       repeat i from 0 to num_outputs-1
         data_in :=shift.in_out((data_out << i ))
         'debug.dec(data_out << i)
         debug.str(string(13))
         debug.dec(data_in) 
         waitcnt(clkfreq/20 +cnt)
            
       'data_in :=shift.in_out(data_out)    ''## send data out and assign return value (inputs) to data_in
       
              '## print input
     ' debug.str(string(13))
       waitcnt(clkfreq/200 +cnt)   '## pause 500ms