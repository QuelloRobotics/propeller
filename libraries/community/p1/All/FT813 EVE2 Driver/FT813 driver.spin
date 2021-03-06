{{┌──────────────────────────────────────────┐
  │ FT813 driver                             │  20Mbps send / 10Mbps receive using cog counters
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2020 Chris Gadd            │                             3V3       
  │ See end of file for terms of use.        │                     ┌─────┐                                            
  └──────────────────────────────────────────┘                   ┌─┤2   1├──┘        
                                                           MISO─┼─┤4   3├──SCK                       
                                                             CS─┼─┤6   5├──MOSI                                                  
                                                              ┌──┼─┤8   7├           
                                                              │ ┤10  9├           
                                                                │ ┤12 11├           
                                                        3V3 or 5V│ ┤14 13├ 3V3 or 5V 
                                                                │ ┤16 15├          
                                                              └──┼─┤18 17├──┘        
                                                                 ┣─┤20 19├─┐         
                                                                  └─────┘          
                                                         
                                                         
  
}}             
VAR
  long  spi_address, spi_data   ' used by host_command, read, and write methods to pass parameters to and from PASM routine
  long  clear_color             ' set by set_clearColor method, used to set the background screen color
  word  dl_ptr, cmd_ptr         ' pointer to next register in display list and command list
  byte  font_type               ' font used by the textAlt and textStr methods  
  byte  touch_tag               ' automatically updated by PASM routine, contains tag value of touched object
  byte  cog          

PUB Null                                                '' Not a top-level object

PUB Start(cs_pin,miso_pin,mosi_pin,sck_pin) : okay      '' Configure SPI pins and initialize display

  stop                          
  cs_mask     := |< cs_pin      
  miso_mask   := |< miso_pin    
  mosi_mask   := |< mosi_pin    
  sck_mask    := |< sck_pin
  mosi        := mosi_pin
  sck         := sck_pin
  
  address_ptr := @spi_address                           ' address of register to read or write
  data_ptr    := @spi_data                              ' data sent to and received from register
  tag_ptr     := @touch_tag                             ' contains value of tag currently being touched - continually updated by PASM routine
  okay := cog := cognew(@entry, 0) + 1                 
  InitDisplay

PUB Stop                                                '' Stop PASM driver if running
  if cog
    cogstop(cog~ - 1)                                  

PUB dlstart                                             '' Start a new display list - always use at beginning of command list
  repeat until rd16(_REG_CMD_READ) == rd16(_REG_CMD_WRITE)
  cmd_ptr := rd16(_REG_CMD_WRITE)
  cmd(_CMD_DLSTART)
  cmd(_CLEAR_COLOR_RGB | clear_color)
  cmd(_CLEAR | %111)                                                 

PUB dlswap                                              '' Swap display list and make active - always use at end of command list
  cmd(_CMD_DLSWAP)
  cmd(_DISPLAY)
  wr16(_REG_CMD_WRITE,cmd_ptr)

PUB track(x,y,w,h,t)                                    '' x & y coords, width, height, tag
  cmd(_CMD_TRACK)                                     
  cmd(y << 16 | x)                                      
  cmd(h << 16 | w)
  cmd(t)

PUB tracker                                             '' Returns tracker value in upper 16 bits, tag id in low 8 bits
  return rd32(_REG_TRACKER)

PUB touchTag                                            '' Returns value of tag currently being touched
  return touch_tag
  
PUB coldstart                                           '' Restore co-processor to default reset state
  cmd(_CMD_COLDSTART)

PUB addPropfont(ptr) | i, address, pattern, char        '' writes PropFont to FT813 RAM at address specified by ptr - ptr must be long-aligned
  repeat i from 0 to 127                                '   requires ~3.7s to complete
    wr8(ptr + i,16)                                     ' set all character widths to 16
  wr32(ptr + 128,1)                                     ' bitmap format 1 (1 bit == 1 pixel) 
  wr32(ptr + 132,2)                                     ' line_stride = 2 bytes per line
  wr32(ptr + 136,16)                                    ' width in pixels = 16          
  wr32(ptr + 140,32)                                    ' height in pixels = 32         
  wr32(ptr + 144,ptr + 148)                             ' start pixel data at 148
  ptr += 148
  repeat char from $00 to $7F
    address := (char & !1) << 6 + $8000                                         ' Multiply the character value (stripped of lsb) by 64 and add the character ROM offset             
    repeat 32                                                                   ' Repeat for all lines of the character                                                             
      pattern := 0                                                                                                                                                                  
      repeat i from 0 to 30 step 2                                              ' Two characters are stored at each address                                                         
        pattern := pattern << 1 | (long[address] >> (i + char & 1)) & 1         ' Read from the character ROM address, shifting if necessary to select the correct character        
      address += 4                                                              ' Address the next line in the character ROM                                                        
      wr8(ptr,pattern >> 8)                                                                                                                                                         
      wr8(ptr + 1,pattern & $FF)                                                                                                                                                    
      ptr += 2      

PUB addFont(dest_ptr,src_ptr,num) | ls, h, i            '' copies num bytes into FT813 dest_ptr from src_ptr, src_ptr must point to a metrics block
  ls := long[src_ptr + 132]                             '   dest_ptr must be long-aligned
  h  := long[src_ptr + 140]
  repeat i from 0 to 143 step 4                         '  write character widths, format, line-stride, font-width, and font-height
    wr32(dest_ptr + i,long[src_ptr + i])
  wr32(dest_ptr + 144, dest_ptr + 148)                  '  write pointer to beginning of character bitmaps
  repeat i from 148 to 148 + num * ls * h               '  write character bitmaps
    wr8(dest_ptr + i, byte[src_ptr + i])

PUB addFont2(dest_ptr,src_ptr,font_width,font_height,num) | ls, char_width, n, h, l, line_pattern, byte_pattern, byte_ctr
  ls := (font_width - 1) / 8 + 1                        
  wr32(dest_ptr + 128,1)                                ' write bitmap format 1 (1 bit == 1 pixel)
  wr32(dest_ptr + 132,ls)                               ' write line stride
  wr32(dest_ptr + 136,font_width)                       ' write font width
  wr32(dest_ptr + 140,font_height)                      ' write font height
  wr32(dest_ptr + 144,dest_ptr + 148)                   ' write pointer to beginning of character bitmaps
  repeat n from 0 to num - 1
    char_width := 0
    repeat h from 0 to font_height - 1
      line_pattern := 0
      byte_ctr := n * font_height * ls + h * ls
      repeat l from 0 to ls - 1
        byte_pattern := byte[src_ptr + byte_ctr + l]
        wr8(dest_ptr + 148 + byte_ctr + l, byte_pattern) ' write pixel pattern
        line_pattern := line_pattern << 8 | byte_pattern
      line_pattern ><= 16
      >| line_pattern
      char_width #>= line_pattern                       
    wr8(dest_ptr + n,char_width + 1)                    ' write character width

PUB setMultiTouch
  wr8(_REG_CTOUCH_EXTENDED,0)

PUB getCoords(touch)
  case touch
    0: return rd32(_REG_CTOUCH_TOUCH_XY)
    1: return rd32(_REG_CTOUCH_TOUCH1_XY)
    2: return rd32(_REG_CTOUCH_TOUCH2_XY)
    3: return rd32(_REG_CTOUCH_TOUCH3_XY)
    4: return rd16(_REG_CTOUCH_TOUCH4_X) << 16 | rd16(_REG_CTOUCH_TOUCH4_Y)

PUB getTag(touch)
  case touch
    0: return rd8(_REG_CTOUCH_TAG)
    1: return rd8(_REG_CTOUCH_TAG1)
    2: return rd8(_REG_CTOUCH_TAG2)
    3: return rd8(_REG_CTOUCH_TAG3)
    4: return rd8(_REG_CTOUCH_TAG4)

PUB getTagCoords(touch)
  case touch       
    0: return rd32(_REG_CTOUCH_TAG_XY) 
    1: return rd32(_REG_CTOUCH_TAG1_XY)
    2: return rd32(_REG_CTOUCH_TAG2_XY)
    3: return rd32(_REG_CTOUCH_TAG3_XY)
    4: return rd32(_REG_CTOUCH_TAG4_XY)  
  
CON '' Input widgets
PUB button(x,y,w,h,f,options,stringPtr,t) | i           '' x & y coords, width, height, font, options, stringPtr, tag
  cmd(_TAG | t)
  cmd(_CMD_BUTTON)
  cmd(y << 16 | x)
  cmd(h << 16 | w)
  cmd(options << 16 | f)
  repeat i from 0 to strsize(stringPtr) step 4
    cmd(byte[stringPtr + i + 3] << 24 | byte[stringPtr + i + 2] << 16 | byte[stringPtr + i + 1] << 8 | byte[stringPtr + i])

PUB dial(x,y,r,options,val,t)                           '' x & y coords, radius, options, value ($0000-down, $4000-left, $8000-up, $C000-right), touch-tag
  cmd(_TAG | t)
  cmd(_CMD_DIAL)
  cmd(y << 16 | x)
  cmd(options << 16 | r)
  cmd(val)
  track(x,y,1,1,t)

PUB keys(x,y,w,h,f,options,stringPtr) | i               '' x & y coords, width, height, options, stringPtr
  cmd(_CMD_KEYS)                                        '  if an ASCII code is specified in options, that key is drawn "pressed"
  cmd(y << 16 | x)                                      '  Tag value is automatically assigned to ASCII value of each key
  cmd(h << 16 | w)
  cmd(options << 16 | f)
  repeat i from 0 to strsize(stringPtr) step 4
    cmd(byte[stringPtr + i + 3] << 24 | byte[stringPtr + i + 2] << 16 | byte[stringPtr + i + 1] << 8 | byte[stringPtr + i])

PUB slider(x,y,w,h,options,val,range,t)                 '' x & y coords, width, height, options, value, max_value, tag
  cmd(_TAG | t)
  cmd(_CMD_SLIDER)
  cmd(y << 16 | x)
  cmd(h << 16 | w)
  cmd(val << 16 | options)
  cmd(range)
  track(x,y,w,h,t)

PUB toggle(x,y,w,f,options,state,stringPtr,t) | i       '' x & y coords, width, font, options, state, stringPtr ($FF separates the two labels), tag
  cmd(_TAG | t)
  cmd(_CMD_TOGGLE)                                      '  cmd_toggle(60, 20, 33, 27, 0, 0,string("off",$FF,"on")) 
  cmd(y << 16 | x)                                      '  state = 0 (off) to 65535 (on)                           
  cmd(f << 16 | w)                                                                                                 
  cmd(state << 16 | options)
  repeat i from 0 to strsize(stringPtr) step 4
    cmd(byte[stringPtr + i + 3] << 24 | byte[stringPtr + i + 2] << 16 | byte[stringPtr + i + 1] << 8 | byte[stringPtr + i])
  track(x,y,w,1,t)

PUB tag(t)                                              '' Assign a tag to a widget or a primitive shape
  cmd(_TAG | t)

CON '' Output widgets
PUB clock(x,y,r,options,h,m,s,ms)                       '' x & y coords, radius, options, hours, minutes, seconds, milliseconds
  cmd(_CMD_CLOCK)               
  cmd(y << 16 | x)       
  cmd(options << 16 | r) 
  cmd(m << 16 | h)              
  cmd(ms << 16 | s)
  
PUB gauge(x,y,r,options,major,minor,val,range)          '' x & y coords, radius, options, major ticks, minor ticks, value, max_value
  cmd(_CMD_GAUGE)               
  cmd(y << 16 | x)       
  cmd(options << 16 | r) 
  cmd(minor << 16 | major)      
  cmd(range << 16 | val)

PUB text(x,y,f,options,stringPtr) | i                   '' x & y coords, font, options, stringPtr
  cmd(_CMD_TEXT)
  cmd(y << 16 | x)
  cmd(options << 16 | f)
  repeat i from 0 to strsize(stringPtr) step 4
    cmd(byte[stringPtr + i + 3] << 24 | byte[stringPtr + i + 2] << 16 | byte[stringPtr + i + 1] << 8 | byte[stringPtr + i])

PUB progress(x,y,w,h,options,val,range)                 '' x & y coords, width, height, options, value, max_value
  cmd(_CMD_PROGRESS)
  cmd(y << 16 | x)
  cmd(h << 16 | w)
  cmd(val << 16 | options)
  cmd(range)
  
PUB scrollbar(x,y,w,h,options,val,s,range)              '' x & y coords, width, height, options, value, size, max_value      
  cmd(_CMD_SCROLLBAR)
  cmd(y << 16 | x)
  cmd(h << 16 | w)
  cmd(val << 16 | options)
  cmd(range << 16 | s)

PUB number(x,y,f,options,num)                           '' x & y coords, font, options, number          
  cmd(_CMD_NUMBER)
  cmd(y << 16 | x)
  cmd(options << 16 | f)
  cmd(num)

PUB Font(f)                                             '' Set the font used by the textAlt and textStr methods
  font_type := f

PUB textAlt(x,y,char)                                   '' Print a single character
  if x < 480 and y < 272
    cmd(_VERTEX2II | (x & $1FF) << 21 | (y & $1FF) << 12 | font_type << 7 | char)

PUB TextStr(x,y,stringPtr) | x_home, char, c, f         '' Print a string of characters, also handles carriage return, and color and font changes
{{
  Works fine for ROM fonts, where the metrics blocks are located in known locations.
  Custom RAM fonts pose a problem in that the metrics block may be located anywhere in RAM_G, and the FT813 does not provide a way to look it up
  based on a font ID. A single custom font character may be added to the end of a string. Successive characters will be spaced unpredictably.
}}
  cmd(_BEGIN | _BITMAPS)                                 ' $0D - carriage return
  x_home := x                                            ' $80 - change color, following three bytes are red, green, and blue values  
  repeat until byte[stringPtr] == 0                      ' $81 - change font, following byte is font type                             
    char := byte[stringPtr]                          
    if char == $0D                                                              ' Carriage return
      x := x_home                                                               '  Reset x position to beginning
      y += rd8(_ROM_FONT_PTR + (148 * (font_type - 16)) + 140)                  '  Increment y position by font height read from metrics block
    elseif char == $80                                                          ' Change color
      c := byte[++stringPtr] << 16 | byte[++stringPtr] << 8 | byte[++stringPtr] '  use three bytes following $80 as red, green, and blue values
      color(c)    
    elseif char == $81                                                          ' Change font type
      font_type := byte[++stringPtr]                                            '  use byte following $81 as font type
    else
      TextAlt(x,y,char)                                                         ' Print a character from the string
      x += rd8(_ROM_FONT_PTR + (148 * (font_type - 16) + char))                 '  increment x position by character width read from metrics block
    stringPtr++
  cmd(_END)

CON '' Color methods
PUB set_clearColor(rrggbb)                              '' Set background color of display
  clear_color := rrggbb

PUB color(rrggbb)                                       '' Set text color and fill color of graphics primitives (points, lines, rectangles)
  cmd(_COLOR_RGB | rrggbb)

PUB fgColor(rrggbb)                                     '' Set foreground color of buttons, keys, scrollbars, sliders, dials, toggles, and calibrate
  cmd(_CMD_FGCOLOR)
  cmd(rrggbb)

PUB bgColor(rrggbb)                                     '' Set background color of gauge, progress bar, scrollbar, slider, toggle, and calibrate
  cmd(_CMD_BGCOLOR)
  cmd(rrggbb)

PUB gradColor(rrggbb)                                   '' Set gradient color
  cmd(_CMD_GRADCOLOR)
  cmd(rrggbb)

PUB gradient(x,y,rgb0,x1,y1,rgb1)                       '' x & y coord start, color start, x & y coord end, color end
  cmd(_CMD_GRADIENT)
  cmd(y << 16 | x)
  cmd(rgb0)
  cmd(y1 << 16 | x1)
  cmd(rgb1)

PUB alpha(amount)                                       '' set alpha channel ($00 = fully transparent / $FF = fully opaque)
  cmd(_COLOR_A | amount & $FF)

CON '' ToDo
PUB interrupt
PUB append
PUB regread
PUB memwrite
PUB inflate
PUB loadimage
PUB mediafifo
PUB playvideo
PUB videostart
PUB videoframe
PUB memcrc
PUB memzero
PUB memset
PUB memcopy
PUB setBase(base)
PUB loadIdentity
PUB setMatrix
PUB getMatrix
PUB getPtr
PUB getProps
PUB scale
PUB rotate
PUB translate
PUB calibrate
PUB setRotate
PUB spinner
PUB screensaver
PUB sketch
PUB _stop
PUB setFont
PUB setFont2(f,ptr,firstchar)                           '' new font ID, pointer to metrics block, value of 1st character in new font
  cmd(_CMD_SETFONT2)
  cmd(f)
  cmd(ptr)
  cmd(firstchar)  

PUB setScratch
PUB romFont
PUB snapshot
PUB snapshot2
PUB setBitmap
PUB logo                                                '' display the FTDI animated logo
  cmd_ptr := 0
  cmd(_CMD_LOGO)                                      
  wr16(_REG_CMD_WRITE,cmd_ptr)
  repeat until rd16(_REG_CMD_READ) == 0 and rd16(_REG_CMD_WRITE) == 0

CON ''primitives commands
PUB rect(x,y,w,h,line_weight)                           '' Draw rectangle, x & y specify top-left corner
  cmd(_BEGIN | _RECTS)
  Width(line_weight)
  Point(x,y)
  Point(x + w,y + h)

PUB circle(x,y,rad)
  cmd(_BEGIN | _POINTS)
  size(rad)
  point(x,y)

PUB line(x1,y1,x2,y2,line_weight)                       '' Draw line between two points, use 'lines' method for multi-segmented line
  cmd(_BEGIN | _LINES)
  Width(line_weight)
  Point(x1,y1)
  Point(x2,y2)

PUB lines(x,y,line_weight)                              '' Plot the 1st point of a multi-segmented line, use point method for successive points
  cmd(_BEGIN | _LINE_STRIP)
' Width(line_weight)                                    '  The display counts 16 lsb per pixel - width method uses 1-pixel resolution
  cmd(_LINE_WIDTH | line_weight)                        '  Altered this method for sub-pixel resolution
  Point(x,y)

PUB Point(x,y)                                          '' Plot a point
  cmd(_VERTEX2F | (x * 16) << 15 | (y * 16))         

PUB Size(s)                                             '' Change point size - only applies to points
  cmd(_POINT_SIZE | (s * 16))

PUB Width(w)                                            '' Change line size - applies to line, lines, and rectangles
  cmd(_LINE_WIDTH | (w * 16))

PRI cmd(parameter)                                      '' add a command to the command list
  wr32(_RAM_CMD + cmd_ptr,parameter)
  cmd_ptr += 4
  cmd_ptr &= $0FFF

PRI dl(parameter)                                       '' add an instruction to the display list
  wr32(_RAM_DL + dl_ptr,parameter)
  dl_ptr += 4

PRI InitDisplay | i, t                                  '' initialize the display
  HostCommand(_RST_PULSE,0)
  HostCommand(_CLKEXT,0)
  rd8(_ACTIVE)
  repeat until (rd8(_REG_ID) & $FF) == $7C
  
'{
' Configure display registers for WQVGA (480x272) resolution
  wr16(_REG_HSIZE,480)          
  wr16(_REG_HCYCLE,548)         
  wr16(_REG_HOFFSET,43)         
  wr16(_REG_HSYNC0,0)           
  wr16(_REG_HSYNC1,41)          
  wr16(_REG_VSIZE,272)          
  wr16(_REG_VCYCLE,292)         
  wr16(_REG_VOFFSET,12)         
  wr16(_REG_VSYNC0,0)           
  wr16(_REG_VSYNC1,10)          
  wr8(_REG_SWIZZLE,0)           
  wr8(_REG_PCLK_POL,1)          
  wr8(_REG_CSPREAD,1)
  wr8(_REG_DITHER,1)
'}
{
' Configure display registers for WVGA (800x480) resolution
  wr16(_REG_HSIZE,800)          
  wr16(_REG_HCYCLE,928)         
  wr16(_REG_HOFFSET,88)         
  wr16(_REG_HSYNC0,0)           
  wr16(_REG_HSYNC1,48)          
  wr16(_REG_VSIZE,480)          
  wr16(_REG_VCYCLE,525)         
  wr16(_REG_VOFFSET,32)         
  wr16(_REG_VSYNC0,0)           
  wr16(_REG_VSYNC1,3)           
  wr8(_REG_SWIZZLE,0)           
  wr8(_REG_PCLK_POL,1)          
  wr8(_REG_CSPREAD,1)           
  wr8(_REG_DITHER,1)
'}
' Write first display list
  wr32(_RAM_DL + 0,_CLEAR_COLOR_RGB | clear_color)
  wr32(_RAM_DL + 4,_CLEAR | %111)                    
  wr32(_RAM_DL + 8,_DISPLAY)                         
  wr8(_REG_DLSWAP,_DLSWAP_FRAME)                        ' display list swap
  wr8(_REG_GPIO_DIR,($80 | rd8(_REG_GPIO_DIR)))
  wr8(_REG_GPIO,($80 | rd8(_REG_GPIO)))                 ' enable display bit
  wr8(_REG_PCLK,5)                                      ' after this display is visible on the LCD     WQVGA(480x272)
' wr8(_REG_PCLK,2)                                      ' after this display is visible on the LCD     WVGA(800x480)

PRI HostCommand(_Command,Command_Par)
  spi_address := ((_Command << 24) | Command_Par << 16)
  repeat until spi_address == 0

PRI Wr8(Address,Data)
  _Write(Address,Data,1)

PRI Wr16(Address,Data)
  _Write(Address,Data,2)

PRI Wr32(Address,Data)
  _Write(Address,Data,4)

PRI _Write(Address,Data,Num)
  spi_data := Data
  spi_address := ((Address << 8) | $80000000) | Num                             ' prepend address with write bit
  repeat until spi_address == 0

PRI Rd8(Address)
  return _Read(Address,1)

PRI Rd16(Address)
  return _Read(Address,2) <- 8
  
PRI Rd32(Address)
  return _Read(Address,4) -> 8

PRI _Read(Address,Num)
  spi_address := ((Address << 8) | Num)
  repeat until spi_address == 0
  return spi_data

DAT                     org                                   '' PASM SPI driver
entry
                        or        outa,cs_mask
                        or        dira,cs_mask
                        or        dira,mosi_mask
                        or        dira,sck_mask
                        movi      ctra,#%00100_000                              ' using ctra to send data
                        movs      ctra,mosi
                        movi      ctrb,#%00100_000                              ' using ctrb for clock
                        movs      ctrb,sck
Reset
                        mov       spi_long,#0
                        wrlong    spi_long,address_ptr
Wait_for_address
                        rdlong    spi_long,address_ptr        wz
          if_z          jmp       #check_touch                                  ' check touchscreen while waiting
                        mov       data_counter,spi_long
                        and       data_counter,#7                               ' data_counter ranges from 0 to 4
                        test      spi_long,write_bits         wz
          if_nz         jmp       #Write
                        test      spi_long,command_bits       wz
          if_nz         jmp       #Command
'......................................................................................
Read
                        andn      outa,cs_mask
                        andn      spi_long,#$FF                                 ' Clear byte[0] - contained rx byte counter
                        call      #out_8                                        ' Send 24-bit address followed by $00
                        call      #out_8
                        call      #out_8
                        call      #out_8
                        mov       spi_long,#0
:loop
                        ror       spi_long,#16                                  ' Receive $123456 as $56, $34, $12
                        call      #in_8                                         ' Requires a final rotate - currently handled in spin 
                        djnz      data_counter,#:loop                           '  rd8 is okay                                        
                        or        outa,cs_mask                                  '  rd16 needs ror 8                                   
                        wrlong    spi_long,data_ptr                             '  rd32 needs rol 8                                   
                        jmp       #Reset
'......................................................................................
Command                                                                         ' Command sends a 6-bit address prepended with %01
                        andn      outa,cs_mask                                  '  one data byte, followed by a $00 byte
                        call      #out_8
                        call      #out_8
                        call      #out_8
                        or        outa,cs_mask
                        jmp       #Reset
'......................................................................................
Write                                                                           ' Write sends a 22-bit address prepended with %10
                        andn      outa,cs_mask                                  '  and up to 4 data bytes
                        call      #out_8
                        call      #out_8
                        call      #out_8
                        rdlong    t1,data_ptr                                   ' data needs to be sent little-endian
:loop
                        ror       t1,#8                                         ' Send $123456 as $56, $34, $12
                        mov       spi_long,t1
                        call      #out_8
                        djnz      data_counter,#:loop
                        or        outa,cs_mask
                        jmp       #Reset
'......................................................................................
Check_touch
                        andn      outa,cs_mask
                        mov       spi_long,REG_CTOUCH_TAG                       ' Send REG_CTOUCH_TAG, followed by $00
                        call      #out_8
                        call      #out_8
                        call      #out_8
                        call      #out_8
                        call      #in_8                                         ' Receive TAG value 
                        or        outa,cs_mask
                        wrbyte    spi_long,tag_ptr
                        jmp       #Wait_for_address
'--------------------------------------------------------------------------------------
out_8
                        mov       phsa,spi_long
                        mov       phsb,phs_out
                        movi      frqb,#%010000000                            
                        shl       phsa,#1
                        shl       phsa,#1
                        shl       phsa,#1
                        shl       phsa,#1
                        shl       phsa,#1
                        shl       phsa,#1
                        shl       phsa,#1
                        mov       frqb,#0
                        shl       spi_long,#8
out_8_ret               ret
'--------------------------------------------------------------------------------------
in_8
                        mov       phsa,phs_in                                   ' Sample MISO on downclock 
                        movi      frqb,#%001_000000
                        test      miso_mask,ina               wc                ' MSB of result is ready when CS pulled low
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc               
                        rcl       spi_long,#1                 
                        test      miso_mask,ina               wc
                        mov       frqb,#0
                        rcl       spi_long,#1
in_8_ret                ret
'======================================================================================
phs_out                 long      $4000_0000
phs_in                  long      $8000_0000

REG_CTOUCH_TAG          long      _REG_CTOUCH_TAG << 8
write_bits              long      %10 << 30
command_bits            long      %01 << 30
'read_bits              long      %00 << 30
address_ptr             long      0-0
data_ptr                long      0-0
tag_ptr                 long      0-0
cs_mask                 long      0-0
miso_mask               long      0-0
mosi_mask               long      0-0
sck_mask                long      0-0
mosi                    long      0-0
sck                     long      0-0
spi_long                res       1
data_counter            res       1
bit_counter             res       1
t1                      res       1

                        fit       496

CON ''Graphics primitives macros  - Used with BEGIN
  _BITMAPS              = 1     
  _POINTS               = 2     
  _LINES                = 3     
  _LINE_STRIP           = 4     
  _EDGE_STRIP_R         = 5     
  _EDGE_STRIP_L         = 6     
  _EDGE_STRIP_A         = 7     
  _EDGE_STRIP_B         = 8     
  _RECTS                = 9     

CON ''Host commands definitions
  _ACTIVE               = $00                           ' Place FT801 in active state                                  
  _STANDBY              = $41                           ' Place FT801 in Standby (clk running)                         
  _SLEEP                = $42                           ' Place FT801 in Sleep (clk off)                               
  _PWRDOWN              = $50                           ' Place FT801 in Power Down (core off)                         
  _CLKEXT               = $44                           ' Select external clock source                                 
  _CLKINT               = $48                           ' Select internal clock source                                 
  _CLK48M               = $62                           ' Select 48MHz PLL output                                      
  _CLK36M               = $61                           ' Select 36MHz PLL output                                      
  _RST_PULSE            = $68                           ' Reset core - all registers default and processors reset      

CON ''Graphics display list swap definitions
  _DLSWAP_DONE          = 0     
  _DLSWAP_LINE          = 1     
  _DLSWAP_FRAME         = 2

CON ''Memory definitions 
  _RAM_G                = $000000                       ' General purpose graphics RAM
  _ROM_CHIPID           = $0C0000                       ' should return $00011308
  _ROM_FONT             = $1E0000                       ' Font table and bitmap
  _ROM_FONT_PTR         = $201EE0                       ' This is the value read from ROM_FONTROOT
  _ROM_FONTROOT         = $2FFFFC                       ' Font table pointer address
  _RAM_DL               = $300000                       ' Display List RAM
  _RAM_REG              = $302000                       ' Registers
  _RAM_CMD              = $308000                       ' Command buffer (4K)

CON ''Coprocessor related commands
  _CMD_APPEND           = $FFFFFF1E 
  _CMD_BGCOLOR          = $FFFFFF09
  _CMD_BUTTON           = $FFFFFF0D 
  _CMD_CALIBRATE        = $FFFFFF15
  _CMD_CLOCK            = $FFFFFF14 
  _CMD_COLDSTART        = $FFFFFF32
  _CMD_DIAL             = $FFFFFF2D
  _CMD_DLSTART          = $FFFFFF00
  _CMD_DLSWAP           = $FFFFFF01
  _CMD_FGCOLOR          = $FFFFFF0A
  _CMD_GAUGE            = $FFFFFF13
  _CMD_GETMATRIX        = $FFFFFF33
  _CMD_GETPROPS         = $FFFFFF25
  _CMD_GETPTR           = $FFFFFF23
  _CMD_GRADCOLOR        = $FFFFFF34
  _CMD_GRADIENT         = $FFFFFF0B
  _CMD_INFLATE          = $FFFFFF22 
  _CMD_INTERRUPT        = $FFFFFF02 
  _CMD_KEYS             = $FFFFFF0E
  _CMD_LOADIDENTITY     = $FFFFFF26
  _CMD_LOGO             = $FFFFFF31
  _CMD_MEMWRITE         = $FFFFFF1A 
  _CMD_NUMBER           = $FFFFFF2E
  _CMD_PROGRESS         = $FFFFFF0F
  _CMD_REGREAD          = $FFFFFF19 
  _CMD_ROMFONT          = $FFFFFF3F
  _CMD_ROTATE           = $FFFFFF29
  _CMD_SCALE            = $FFFFFF28
  _CMD_SCREENSAVER      = $FFFFFF2F
  _CMD_SCROLLBAR        = $FFFFFF11
  _CMD_SETBASE          = $FFFFFF38
  _CMD_SETBITMAP        = $FFFFFF43
  _CMD_SETFONT          = $FFFFFF2B
  _CMD_SETFONT2         = $FFFFFF3B
  _CMD_SETMATRIX        = $FFFFFF2A
  _CMD_SETROTATE        = $FFFFFF36
  _CMD_SETSCRATCH       = $FFFFFF3C
  _CMD_SKETCH           = $FFFFFF30
  _CMD_SLIDER           = $FFFFFF10
  _CMD_SPINNER          = $FFFFFF16
  _CMD_STOP             = $FFFFFF17
  _CMD_SNAPSHOT         = $FFFFFF1F
  _CMD_SNAPSHOT2        = $FFFFFF37
  _CMD_TEXT             = $FFFFFF0C
  _CMD_TOGGLE           = $FFFFFF12
  _CMD_TRACK            = $FFFFFF2C
  _CMD_TRANSLATE        = $FFFFFF27
  
CON ''Widget options
  _OPT_3D               = 0                             ' 3D effect
  _OPT_RGB565           = 0                             ' Decode the source image to RGB565 format
  _OPT_MONO             = 1                             ' Decode the source JPEG image to L8 format, i.e., monochrome
  _OPT_NODL             = 2                             ' No display list commands generated
  _OPT_FLAT             = 256                           ' No 3D effect
  _OPT_SIGNED           = 256                           ' The number is treated as a 32 bit signed integer
  _OPT_CENTERX          = 512                           ' Horizontally-centred style
  _OPT_CENTERY          = 1024                          ' Vertically centred style
  _OPT_CENTER           = 1536                          ' horizontally and vertically centred style
  _OPT_RIGHTX           = 2048                          ' Right justified style
  _OPT_NOBACK           = 4096                          ' No background drawn
  _OPT_NOTICKS          = 8192                          ' No Ticks
  _OPT_NOHM             = 16384                         ' No hour and minute hands
  _OPT_NOPOINTER        = 16384                         ' No pointer
  _OPT_NOSECS           = 32768                         ' No second hands
  _OPT_NOHANDS          = 49152                         ' No hands
  _OPT_NOTEAR           = 4                             ' Synchronize video updates to the display blanking interval, avoiding horizontal "tearing" artefacts
  _OPT_FULLSCREEN       = 8                             ' zoom the video so that it fills as much of the screen as possible
  _OPT_MEDIAFIFO        = 16                            ' source video data from the defined media FIFO
  _OPT_SOUND            = 32                            ' Decode the audio data

CON ''Register definitions
' NAME                    ADDRESS    BITS     DESCRIPTION                                                                                                                                                                                  
  _REG_ID               = $302000   ' 8       Identification register, always reads as 7Ch                                                                                                                                                 
  _REG_FRAMES           = $302004   ' 32      Frame counter, since reset                                                                                                                                                                   
  _REG_CLOCK            = $302008   ' 32      Clock cycles, since reset                                                                                                                                                                    
  _REG_FREQUENCY        = $30200C   ' 28      Main clock frequency (Hz)                                                                                                                                                                    
  _REG_RENDERMODE       = $302010   ' 1       Rendering mode: 0 = normal, 1 = single-line                                                                                                                                                  
  _REG_SNAPY            = $302014   ' 11      Scanline select for RENDERMODE 1                                                                                                                                                             
  _REG_SNAPSHOT         = $302018   ' 1       Trigger for RENDERMODE 1                                                                                                                                                                     
  _REG_SNAPFORMAT       = $30201C   ' 6       Pixel format for scanline readout                                                                                                                                                            
  _REG_CPURESET         = $302020   ' 3       Graphics, audio and touch engines reset control. Bit2: audio, bit1: touch, bit0: graphics                                                                                                    
  _REG_TAP_CRC          = $302024   ' 32      Live video tap crc. Frame CRC is                                                                                                                                                             
  _REG_TAP_MASK         = $302028   ' 32      Live video tap mask                                                                                                                                                                          
  _REG_HCYCLE           = $30202C   ' 12      Horizontal total cycle count                                                                                                                                                                 
  _REG_HOFFSET          = $302030   ' 12      Horizontal display start offset                                                                                                                                                              
  _REG_HSIZE            = $302034   ' 12      Horizontal display pixel count                                                                                                                                                               
  _REG_HSYNC0           = $302038   ' 12      Horizontal sync fall offset                                                                                                                                                                  
  _REG_HSYNC1           = $30203C   ' 12      Horizontal sync rise offset                                                                                                                                                                  
  _REG_VCYCLE           = $302040   ' 12      Vertical total cycle count                                                                                                                                                                   
  _REG_VOFFSET          = $302044   ' 12      Vertical display start offset                                                                                                                                                                
  _REG_VSIZE            = $302048   ' 12      Vertical display line count                                                                                                                                                                  
  _REG_VSYNC0           = $30204C   ' 10      Vertical sync fall offset                                                                                                                                                                    
  _REG_VSYNC1           = $302050   ' 10      Vertical sync rise offset                                                                                                                                                                    
  _REG_DLSWAP           = $302054   ' 2       Display list swap control                                                                                                                                                                    
  _REG_ROTATE           = $302058   ' 3       Screen rotation control. Allow normal/mirrored/inverted for landscape or portrait orientation.                                                                                               
  _REG_OUTBITS          = $30205C   ' 9       Output bit resolution, 3 bits each for R/G/B. Default is 6/6/6 bits for FT810/FT811, and 8/8/8 bits for FT812/FT813 (0b’000 means 8 bits)                                                    
  _REG_DITHER           = $302060   ' 1       Output dither enable                                                                                                                                                                         
  _REG_SWIZZLE          = $302064   ' 4       Output RGB signal swizzle                                                                                                                                                                    
  _REG_CSPREAD          = $302068   ' 1       Output clock spreading enable                                                                                                                                                                
  _REG_PCLK_POL         = $30206C   ' 1       PCLK polarity:  0 = output on PCLK rising edge,  1 = output on PCLK falling edge                                                                                                             
  _REG_PCLK             = $302070   ' 8       PCLK frequency divider, 0 = disable                                                                                                                                                          
  _REG_TAG_X            = $302074   ' 11      Tag query X coordinate                                                                                                                                                                       
  _REG_TAG_Y            = $302078   ' 11      Tag query Y coordinate                                                                                                                                                                       
  _REG_TAG              = $30207C   ' 8       Tag query result                                                                                                                                                                             
  _REG_VOL_PB           = $302080   ' 8       Volume for playback                                                                                                                                                                          
  _REG_VOL_SOUND        = $302084   ' 8       Volume for synthesizer sound                                                                                                                                                                 
  _REG_SOUND            = $302088   ' 16      Sound effect select                                                                                                                                                                          
  _REG_PLAY             = $30208C   ' 1       Start effect playback                                                                                                                                                                        
  _REG_GPIO_DIR         = $302090   ' 8       Legacy GPIO pin direction,  0 = input , 1 = output                                                                                                                                           
  _REG_GPIO             = $302094   ' 8       Legacy GPIO read/write                                                                                                                                                                       
  _REG_GPIOX_DIR        = $302098   ' 16      Extended GPIO pin direction,  0 = input , 1 = output                                                                                                                                         
  _REG_GPIOX            = $30209C   ' 16      Extended GPIO read/write                                                                                                                                                                     
' _Reserved             = $3020A0   ' -       Reserved                                                                                                                                                                                     
  _REG_INT_FLAGS        = $3020A8   ' 8       Interrupt flags, clear by read                                                                                                                                                               
  _REG_INT_EN           = $3020Ac   ' 1       Global interrupt enable, 1=enable                                                                                                                                                            
  _REG_INT_MASK         = $3020B0   ' 8       Individual interrupt enable, 1=enable                                                                                                                                                        
  _REG_PLAYBACK_START   = $3020B4   ' 20      Audio playback RAM start address                                                                                                                                                             
  _REG_PLAYBACK_LENGTH  = $3020B8   ' 20      Audio playback sample length (bytes)                                                                                                                                                         
  _REG_PLAYBACK_READPTR = $3020BC   ' 20      Audio playback current read pointer                                                                                                                                                          
  _REG_PLAYBACK_FREQ    = $3020C0   ' 16      Audio playback sampling frequency (Hz)                                                                                                                                                       
  _REG_PLAYBACK_FORMAT  = $3020C4   ' 2       Audio playback format                                                                                                                                                                        
  _REG_PLAYBACK_LOOP    = $3020C8   ' 1       Audio playback loop enable                                                                                                                                                                   
  _REG_PLAYBACK_PLAY    = $3020CC   ' 1       Start audio playback                                                                                                                                                                         
  _REG_PWM_HZ           = $3020D0   ' 14      BACKLIGHT PWM output frequency (Hz)                                                                                                                                                          
  _REG_PWM_DUTY         = $3020D4   ' 8       BACKLIGHT PWM output duty cycle 0=0%, 128=100%                                                                                                                                               
  _REG_MACRO_0          = $3020D8   ' 32      Display list macro command 0                                                                                                                                                                 
  _REG_MACRO_1          = $3020DC   ' 32      Display list macro command 1                                                                                                                                                                 
' _Reserved             = $3020E0   ' -       Reserved                                                                                                                                                                                     
  _REG_CMD_READ         = $3020F8   ' 12      Command buffer read pointer                                                                                                                                                                  
  _REG_CMD_WRITE        = $3020FC   ' 12      Command buffer write pointer                                                                                                                                                                 
  _REG_CMD_DL           = $302100   ' 13      Command display list offset                                                                                                                                                                  
                                                                                                                                                                                                                                           
' CTE registers                                                                                                                                                                                                                            
  _REG_CTOUCH_MODE      = $302104   ' 2       Touch-screen sampling mode (%00 = off | %11 = on)                                                                                                                                            
  _REG_CTOUCH_EXTENDED  = $302108   ' 1       Select ADC working mode (%0 = extended mode (multi-touch) | %1 = FT800 compatibility mode (single touch))                                                                                    
  _REG_CTOUCH_TOUCH_XY  = $302124   ' 32      Coordinates of 1st touch point ($xxxx_yyyy) in extended and compatibility modes                                                                                                              
  _REG_CTOUCH_TOUCH1_XY = $30211C   ' 32      Coordinates of 2nd touch point ($xxxx_yyyy) in extended mode                                                                                                                    
  _REG_CTOUCH_TOUCH2_XY = $30218C   ' 32      Coordinates of 3rd touch point ($xxxx_yyyy) in extended mode                                                                                             
  _REG_CTOUCH_TOUCH3_XY = $302190   ' 32      Coordinates of 4th touch point ($xxxx_yyyy) in extended mode 
  _REG_CTOUCH_TOUCH4_X  = $30216C   ' 16      X coordinate of 5th touch point ($xxxx) in extended mode                                                                                                                                     
  _REG_CTOUCH_TOUCH4_Y  = $302120   ' 16      Y coordinate of 5th touch point ($yyyy) in extended mode 
  _REG_CTOUCH_RAW_XY    = $30211C   ' 32      Raw coordinates before going through the transform matrix ($xxxx_yyyy) in compatibility mode
                                                                         
  _REG_CTOUCH_TAG       = $30212C   ' 8       Touch screen Tag result of 1st touch point in extended and compatibility modes                                                                                                               
  _REG_CTOUCH_TAG1      = $302134   ' 8       Touch screen tag result of 2nd touch point in extended mode                                                                                                                                  
  _REG_CTOUCH_TAG2      = $30213C   ' 8       Touch-screen tag result of 3rd touch point in extended mode                                                                                                                                  
  _REG_CTOUCH_TAG3      = $302144   ' 8       Touch-screen tag result of 4th touch point in extended mode                                                                                                                                  
  _REG_CTOUCH_TAG4      = $30214C   ' 8       Touch-screen tag result of 5th touch point in extended mode                                                                                                                                  
  
  _REG_CTOUCH_TAG_XY    = $302128   ' 32      coordinates used to look up the tag result of 1st touch point ($xxxx_yyyy) in REG_CTOUCH_TAG
  _REG_CTOUCH_TAG1_XY   = $302130   ' 32      coordinates used to look up the tag result of 2nd touch point ($xxxx_yyyy) in REG_CTOUCH_TAG1                                                                                                
  _REG_CTOUCH_TAG2_XY   = $302138   ' 32      coordinates used to look up the tag result of 3rd touch point ($xxxx_yyyy) in REG_CTOUCH_TAG2                                                                                                
  _REG_CTOUCH_TAG3_XY   = $302140   ' 32      coordinates used to look up the tag result of 4th touch point ($xxxx_yyyy) in REG_CTOUCH_TAG3                                                                                                
  _REG_CTOUCH_TAG4_XY   = $302148   ' 32      coordinates used to look up the tag result of 5th touch point ($xxxx_yyyy) in REG_CTOUCH_TAG4                                                                                                
                                                                                                                                                                                                                                           
  _REG_TOUCH_TRANSFORM_A = $302150  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_TRANSFORM_B = $302154  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_TRANSFORM_C = $302158  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_TRANSFORM_D = $30215C  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_TRANSFORM_E = $302160  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_TRANSFORM_F = $302164  ' 32      Touch-screen transform coefficient (s15.16)                                                                                                                                                  
  _REG_TOUCH_CONFIG     = $302168   ' 16      Touch configuration.  RTP/CTP select  RTP: short-circuit, sample clocks  CTP: I2C address, CTPM type, low-power mode                                                                         
' _Reserved             = $302170   ' -       Reserved                                                                                                                                                                                     
  _REG_BIST_EN          = $302174   ' 1       BIST memory mapping enable                                                                                                                                                                   
' _Reserved             = $302178   ' -       Reserved                                                                                                                                                                                     
' _Reserved             = $30217C   ' -       Reserved                                                                                                                                                                                     
  _REG_TRIM             = $302180   ' 8       Internal relaxation clock trimming                                                                                                                                                           
  _REG_ANA_COMP         = $302184   ' 8       Analogue control register                                                                                                                                                                    
  _REG_SPI_WIDTH        = $302188   ' 3       QSPI bus width setting  Bit [2]: extra dummy cycle on read  Bit [1:0]: bus width (0=1-bit, 1=2-bit, 2=4-bit)                                                                                 
' _Reserved             = $302194   ' -       Reserved                                                                                                                                                                                     
  _REG_DATESTAMP        = $302564   ' 128     Stamp date code                                                                                                                                                                              
  _REG_CMDB_SPACE       = $302574   ' 12      Command DL (bulk) space available                                                                                                                                                            
  _REG_CMDB_WRITE       = $302578   ' 32      Command DL (bulk) write                                                                                                                                                                      

CON ''Special Registers
  _REG_TRACKER          = $309000
  _REG_TRACKER_1        = $309004
  _REG_TRACKER_2        = $309008
  _REG_TRACKER_3        = $30900C
  _REG_TRACKER_4        = $309010
  _REG_MEDIAFIFO_READ   = $309014
  _REG_MEDIAFIFO_WRITE  = $309018

CON ''FT813 graphics engine specific macros useful for static display list generation 
  _ALPHA_FUNC           = $09 << 24    ' $09 << 24 | func << 8 | ref                                                                                                                                                                                          
  _BEGIN                = $1F << 24    ' $1F << 24 | primitive graphics value                                                                                                                                                                                      
  _BITMAP_HANDLE        = $05 << 24    ' $05 << 24 | (handle & 31)                                                                                                                                                                                         
  _BITMAP_LAYOUT        = $07 << 24    ' $07 << 24 | (format & 31) << 19 | (linestride & 1023) << 9) | (height & 511)                                                                                                                                      
  _BITMAP_LAYOUT_H      = $28 << 24    ' $28 << 24 | (linestride & 3) << 2 | (height & 3)
  _BITMAP_SIZE          = $08 << 24    ' $08 << 24 | (filter & 1) << 20 | (wrapx & 1) << 19 | (wrapy & 1) << 18 | (width & 511) << 9 | (height & 511)
  _BITMAP_SIZE_H        = $29 << 24    ' $29 << 24 | (width & 3) << 2 | (height & 3) 
  _BITMAP_SOURCE        = $01 << 24    ' $01 << 24 | (addr & $1F_FF_FF)
  _BITMAP_TRANSFORM_A   = $15 << 24    ' $15 << 24 | (a & 131071)                                                                                                                                                                                     
  _BITMAP_TRANSFORM_B   = $16 << 24    ' $16 << 24 | (b & 131071)                                                                                                                                                                                     
  _BITMAP_TRANSFORM_C   = $17 << 24    ' $17 << 24 | (c & 16777215)                                                                                                                                                                                   
  _BITMAP_TRANSFORM_D   = $18 << 24    ' $18 << 24 | (d & 131071)
  _BITMAP_TRANSFORM_E   = $19 << 24    ' $19 << 24 | (e & 131071)                                                                                                                                                                                     
  _BITMAP_TRANSFORM_F   = $1A << 24    ' $1A << 24 | (f & 16777215)
  _BLEND_FUNC           = $0B << 24    ' $0B << 24 | (src & 7) << 3 | (dst & 7)                                                                                                                                                                               
  _CALL                 = $1D << 24    ' $1D << 24 | (dest & 65535)                                                                                                                                                                                
  _CELL                 = $06 << 24    ' $06 << 24 | (cell & 127)
  _CLEAR                = $26 << 24    ' $26 << 24 | (color & 1) << 2 | (stencil & 1) << 1 | (tag & 1)                                                                                                                                                              
  _CLEAR_COLOR_A        = $0F << 24    ' $0F << 24 | (alpha & 255)                                                                                                                                                                                         
  _CLEAR_COLOR_RGB      = $02 << 24    ' $02 << 24 | (red & 255) << 16 | (green & 255) << 8 | (blue & 255)
  _CLEAR_STENCIL        = $11 << 24    ' $11 << 24 | (s & 255)                                                                                                                                                                                             
  _CLEAR_TAG            = $12 << 24    ' $12 << 24 | (t & 255) - returns this value when screen is touched, but not on a tag                                                                                                                                   
  _COLOR_A              = $10 << 24    ' $10 << 24 | (alpha & 255)                                                                                                                                                                                               
  _COLOR_MASK           = $20 << 24    ' $20 << 24 | (r & 1) << 3) | (g & 1) <<2 ) | (b & 1) << 1) | (a & 1)                                                                                                                                                  
  _COLOR_RGB            = $04 << 24    ' $04 << 24 | (red & 255) << 16 | (green & 255) << 8 | (blue & 255)
  _DISPLAY              = $00 << 24    ' $00 << 24
  _END                  = $21 << 24    ' $21 << 24                                                                                                                                                                                                                    
  _JUMP                 = $1E << 24    ' $1E << 24 | (dest & 65535)
  _LINE_WIDTH           = $0E << 24    ' $0E << 24 | (width & 4095)                                                                                                                                                                                           
  _MACRO                = $25 << 24    ' $25 << 24 | (m & 1)
  _NOP                  = $2D << 24    ' $2D << 24
  _PALETTE_SOURCE       = $2A << 24    ' $2A << 24 | (r & 1) << 22 | (addr & $1F_FF_FF)                                                                
  _POINT_SIZE           = $0D << 24    ' $0D << 24 | (size & 8191)                                                                                                                                                                                            
  _RESTORE_CONTEXT      = $23 << 24    ' $23 << 24                                                                                                                                                                                                        
  _RETURN               = $24 << 24    ' $24 << 24
  _SAVE_CONTEXT         = $22 << 24    ' $22 << 24                                                                                                                                                                                                           
  _SCISSOR_SIZE         = $1C << 24    ' $1C << 24 | (width & 4095) << 12) | (height & 4095)
  _SCISSOR_XY           = $1B << 24    ' $1B << 24 | (x & 2047) << 11) |(y & 2047)                                                                                                                                                               
  _STENCIL_FUNC         = $0A << 24    ' $0A << 24 | (func & 15) << 16)| (ref & 255) << 8 | (mask & 255)                                                                                                                           
  _STENCIL_MASK         = $13 << 24    ' $13 << 24 | (mask & 255)                                                                                                                                                                          
  _STENCIL_OP           = $0C << 24    ' $0C << 24 | (sfail & 7) << 3 | (spass & 7)                                                                                                                                                   
  _TAG                  = $03 << 24    ' $03 << 24 | (s & 255)                                                                                                                                                                                          
  _TAG_MASK             = $14 << 24    ' $14 << 24 | (mask & 1)                                                                                                                                                                                
  _VERTEX2F             = $01 << 30    ' $01 << 30 | (x & 32767) << 15 | (y & 32767)                                                                                                                                                             
  _VERTEX2II            = $02 << 30    ' $02 << 30 | (x & 511) << 21 | (y & 511) << 12 | (handle & 31) << 7 | (cell & 127) << 0
  _VERTEX_FORMAT        = $27 << 24    ' $27 << 24 | (frac & 7)
  _VERTEX_TRANSLATE_X   = $2B << 24    ' $2B << 24 | (x & $1FFFF)
  _VERTEX_TRANSLATE_Y   = $2C << 24    ' $2C << 24 | (x & $1FFFF)
  
DAT                                                           '' License
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