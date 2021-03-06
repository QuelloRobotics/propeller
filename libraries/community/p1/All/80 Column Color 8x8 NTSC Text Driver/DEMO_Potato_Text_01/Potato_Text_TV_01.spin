{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             NTSC Scan Line Driver based off of Eric Ball NTSC / PAL templates                                │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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

This driver can do over 640 horizontal pixels, NTSC @ 80Mhz.  It operates off of a scan line HUB memory buffer.  The buffer is
read once per scanline.  If the buffer is not changed, all visible scan lines will be the same.  This driver does not write
to the buffer.

Two longs are used to communicate screen state with other text / graphics generator COGs.  These are vertical and horizontal
pixel sync markers.

When vertical blank begins, either a 1 or a 2 is written to indicate which frame the driver is rendering to the display.  If
a non-interlaced display is selected, only a 1 will be written.  (tv_vblank)

When active pixels begin drawing, a 1 is written (tv_actv).

The graphics / text COG can clear these addresses, then watch for this COG to set them, then act accordingly.

Non-Interlaced display (200 active scan lines) doesn't work as well as it should.  Do not use for over 320 pixel display.

done:  Read Parameters during VBLANK and do timing calculations necessary to change pixels per line at run time.
       Forget calcs.  Those are easy enough to leave in SPIN.
done:  Add mode parameters and logic for true monochrome display.
done:  Add mode parameters and logic for interlace display switch on or off.
done:  Fix color timing in non-interlace display mode.  (maybe, I kind of like it the way it is)

}}


PUB start(params) | i, j, k

'Fire off the video COG, with a pointer to it's HUB lineRAM buffer, and start up values.
  
  cognew(@cogstart,params)

DAT

                        ORG     0
cogstart
'-------------------------------------------------------------
'Get results of Coley hardware detect from calling program:
'These are parameters for the TV cog to use
'-------------------------------------------------------------
                        MOV     index, PAR             ' get parameter block address
                        RDLONG  ivcfg, index           ' fetch from HUB, and write to COG 
                        ADD     index, #4              ' point to next parameter long
                        RDLONG  ifrqa, index                
                        ADD     index, #4                                      
                        RDLONG  idira, index               
                        ADD     index, #4
                                                              
                        RDLONG  vsclbp, index
                        ADD     index, #4
                        RDLONG  vsclactv, index
                        mov     _vsclactv, index        'Get pointer for later
                        ADD     index, #4
                        RDLONG  vsclfp, index
                        ADD     index, #4
                        
                        RDLONG  numwtvd, index
                        mov     _numwtvd, index         'Get pointer for later
                        ADD     index, #4                                    
                        RDLONG  lnram, index
                        ADD     index, #4
                        MOV     clram, index            ' get HUB address of clram   (index 8 * 4)

'-------------------------------------------------------------
'These are addresses for the TV cog to write to
'So that the text and or sprite cog know when to act
'-------------------------------------------------------------
                        ADD     index, #4               'develop shared HUB memory address
                        MOV     tv_vblank, index        'store in COG as pointer
                        ADD     index, #4
                        MOV     tv_actv, index          '(index 10 * 4)

                        
'-------------------------------------------------------------
'Live signal options
'-------------------------------------------------------------
                        add     index, #20
                        mov     _two_colors, index
                        add     index, #4
                        mov     _no_burst, index
                        add     index, #4
                        mov     _no_interlace, index
                        


'-------------------------------------------------------------
' Init COG PLL and Video Generator Hardware
'-------------------------------------------------------------
                        MOV     VCFG, ivcfg             ' baseband composite mode w/ 2bpp color on appropriate pins 
                        MOV     CTRA, ictra             ' internal PLL mode, PLLA = 16*colorburst frequency
                        MOV     FRQA, ifrqa             ' 2*colorburst frequency 
                        MOV     DIRA, idira             ' enable output on appropriate pins

{
' Notes:
' MOVI VCFG, #0 will stop the VSCL counters
' Since VSCL is initialized to 0, it will take 4096 PLLA before it reloads
'   (This is also enough time for PLLA to stabilize.)
}


'-------------------------------------------------------------
' Start of video signal!  Vertical Blanking first, Frame 0
'-------------------------------------------------------------
mainloop                MOV     numline, #9             ' 9 lines of vsync
vsync0                  CMP     numline, #6     WZ      ' lines 4,5,6 serration pulses
              IF_NZ     CMP     numline, #5     WZ      ' lines 1,2,3 / 7,8,9 equalizing pulses
              IF_NZ     CMP     numline, #4     WZ
                        MOV     count, #2               ' 2 pulses per line
:half         IF_NZ     MOV     VSCL, vscleqal          ' equalizing pulse (short)
              IF_Z      MOV     VSCL, vsclselo          ' serration pulse (long)
                        WAITVID sync, #0                ' -40 IRE

'-------------------------------------------------------------
'Update core signal parameters from HUB
'-------------------------------------------------------------
                        wrlong  one, tv_vblank                       ' Vblank flag for graphics COG Frame 0
                        'rdlong  two_colors, _two_colors              ' Set two color mode for no color cells
                        rdlong  no_burst, _no_burst                  ' Set color burst state
                        rdlong  no_interlace, _no_interlace          ' Set interlace state
                        rdlong  vsclactv, _vsclactv                  ' Set vscl for characters per line
                        rdlong  numwtvd, _numwtvd                    ' Set number of waitvids for chars per line





                        
              IF_NZ     MOV     VSCL, vscleqhi          ' equalizing pulse (long)
              IF_Z      MOV     VSCL, vsclsync          ' serration pulse (short)
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    count, #:half
                        DJNZ    numline, #vsync0
'-------------------------------------------------------------                         
                        MOV     numline, #12            ' 12 blank lines
blank0                  MOV     VSCL, vsclsync
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclblnk
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    numline, #blank0
                        
{Notes:
' Officially there are 481 active lines (241+240), but on a normal TV
' number of these lines are lost to overscan.  200 per field is a more
' realistic amount padded to 241/240 at the top and bottom.
' For an interlaced picture, this is the first, third, fifth ... lines.
}

'-------------------------------------------------------------
' Begin active video, frame 0
' HBLANK, CBURST, Back Porch, set tv actv flag
'-------------------------------------------------------------
                        MOV     numline, #241           ' 241 lines of active video
active0                 MOV     VSCL, vsclsync          ' horizontal sync (0H)
                        wrlong  one, tv_actv            ' Scan line flag for graphics COGs, both frames.
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vscls2cb          ' 5.3us 0H to burst
                        WAITVID sync, blank
                        MOV     VSCL, vsclbrst          ' 9 cycles of colorburst

                        cmp     no_burst, #0    wz      ' Monochrome signal?
             if_NZ      WAITVID sync, blank             ' No?  Output color burst
             if_Z       WAITVID sync, burst             ' Yes?  No color burst
                        
                        MOV     VSCL, vsclbp            ' backporch 9.2us OH to active video
                        WAITVID sync, blank
                        rdlong  two_colors, _two_colors              ' Set two color mode for no color cells


'-------------------------------------------------------------
' Screen graphics happen here frame 0
' This is the only frame code running for non-interlaced display
' For interlaced display, this code draws even numbered scanlines
'-------------------------------------------------------------
                        MOV     count, numwtvd          ' number of WAITVIDs
                        MOV     index, lnram            ' point to HUB pixel RAM
                        rdlong  indexa, clram           ' fetch color ram address from hub
                        sub     indexa, #2            
  
                        MOV     VSCL, vsclactv          ' PLLA per pixel, 8 pixels per frame

                        tjnz    two_colors, #:loop_2color  'Follow two color loop
                        
:loop                   RDword  pixels, index           ' get pixel data
                        ADD     index, #2               ' point to future pixels
                        ADD     indexa, #2              ' point to future colors
                        RDword  colors, indexa          ' get colors
                        WAITVID colors, pixels         ' Draw pixels on screen!
                        DJNZ    count, #:loop
                        jmp     #fp0

'---------------------------------------------------------------
'Alternative two color loop, uses full screen color values
'read from HUB at VBLANK
'---------------------------------------------------------------

:loop_2color            RDword  pixels, index           ' get pixel data
                        ADD     index, #2               ' point to future pixels
                        'ADD     indexa, #4              ' point to future colors
                        'RDLONG  colors, indexa          ' get colors
                        WAITVID two_colors, pixels          ' Draw pixels on screen!
                        DJNZ    count, #:loop_2color




'-------------------------------------------------------------
' Enter Front Porch
'-------------------------------------------------------------
fp0                     MOV     VSCL, vsclfp            ' front porch 1.5us
                        WAITVID sync, blank
                        DJNZ    numline, #active0


 '-------------------------------------------------------------
' End of frame 0, enable jump here for non-interlaced video
                        TJZ     no_interlace, #half_scan
                        JMP     #mainloop
'-------------------------------------------------------------



'-------------------------------------------------------------
' Output half a scan line required for interlaced display
'-------------------------------------------------------------
half_scan               MOV     VSCL, vsclsync          ' half line
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclselo
                        WAITVID sync, blank
                        
'-------------------------------------------------------------
' Vertical Blanking, Frame 1
'-------------------------------------------------------------                         
                        MOV     numline, #9             ' 9 lines of vsync (again)
vsync1                  CMP     numline, #6     WZ      ' lines 4,5,6 serration pulses
              IF_NZ     CMP     numline, #5     WZ      ' lines 1,2,3 / 7,8,9 equalizing pulses
              IF_NZ     CMP     numline, #4     WZ
                        MOV     count, #2               ' 2 pulses per line
:half         IF_NZ     MOV     VSCL, vscleqal          ' equalizing pulse (short)
              IF_Z      MOV     VSCL, vsclselo          ' serration pulse (long)
                        WAITVID sync, #0                ' -40 IRE
                        wrlong  two, tv_vblank          ' Vblank flag for graphics COG Frame 1
              IF_NZ     MOV     VSCL, vscleqhi          ' equalizing pulse (long)
              IF_Z      MOV     VSCL, vsclsync          ' serration pulse (short)
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    count, #:half
                        DJNZ    numline, #vsync1
'-------------------------------------------------------------
                        MOV     VSCL, vsclhalf          ' half line
                        WAITVID sync, blank             ' 0 IRE
                        MOV     numline, #13            ' 13 blank lines for this frame
blank1                  MOV     VSCL, vsclsync
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vsclblnk
                        WAITVID sync, blank             ' 0 IRE
                        DJNZ    numline, #blank1

'-------------------------------------------------------------
' Begin active video, frame 1
' HBLANK, CBURST, Back Porch
'-------------------------------------------------------------                         
                        MOV     numline, #240           ' 240 lines of active video (again)
active1                 MOV     VSCL, vsclsync          ' horizontal sync (0H)
                        wrlong  one, tv_actv             'tell other image cogs pixels are being drawn 
                        WAITVID sync, #0                ' -40 IRE
                        MOV     VSCL, vscls2cb          ' 5.3us 0H to burst
                        WAITVID sync, blank
                        MOV     VSCL, vsclbrst          ' 9 cycles of colorburst
                        
                        cmp     no_burst, #0    wz      ' Monochrome signal?
             if_NZ      WAITVID sync, blank             ' No?  Output color burst
             if_Z       WAITVID sync, burst             ' Yes?  No color burst
                        
                        
                        MOV     VSCL, vsclbp            ' backporch 9.2us OH to active video
                        WAITVID sync, blank
                        rdlong  two_colors, _two_colors              ' Set two color mode for no color cells
                        
'-------------------------------------------------------------
' Set tv_actv flag 
' Screen graphics happen here, frame 1
'-------------------------------------------------------------
                        MOV     count, numwtvd                                  ' number of WAITVIDs
                        MOV     index, lnram                                    ' point to HUB pixel RAM
                        rdlong  indexa, clram                                   ' fetch color ram address from hub
                        sub     indexa, #2
                        MOV     VSCL, vsclactv                                  ' PLLA per pixel, 16 pixels per frame

                        tjnz    two_colors, #:loop_2color1                      'Follow two color loop

:loop1                  RDword  pixels, index                                   ' get pixel data
                        ADD     index, #2                                       ' point to future pixels

                        ADD     indexa, #2                                      ' point to future colors
                        RDword  colors, indexa                                  ' get colors
                        WAITVID colors, pixels                                  ' Draw pixels on screen!
                        DJNZ    count, #:loop1
                        jmp     #fp1

'---------------------------------------------------------------
'Alternative two color loop, uses full screen color values
'read from HUB at VBLANK
'---------------------------------------------------------------

:loop_2color1           RDword  pixels, index                                   ' get pixel data
                        ADD     index, #2                                       ' point to future pixels
                        'ADD     indexa, #4                                     ' point to future colors
                        'RDLONG  colors, indexa                                 ' get colors
                        WAITVID two_colors, pixels                              ' Draw pixels on screen!
                        DJNZ    count, #:loop_2color1




                        
'-------------------------------------------------------------
' Set 2bpp mode here for sync & Reset tv_actv flag
'-------------------------------------------------------------
fp1                     MOV     VSCL, vsclfp            ' front porch 1.5us
                        WAITVID sync, blank
                        DJNZ    numline, #active1

'-------------------------------------------------------------
' End of frame 1, loop back and do it all again
'-------------------------------------------------------------
                        JMP     #mainloop

'-------------------------------------------------------------
' Working Longs and constants
'-------------------------------------------------------------

A                       LONG    $0
numline                 LONG    $0
count                   LONG    $0
index                   LONG    $0
indexa                  LONG    $0
d1                      LONG    1<<9                    'destination = 1
colors                  LONG    $0                      'waitvid data
pixels                  LONG    $0                      'waitvid data
zero                    LONG    0
one                     LONG    1
two                     LONG    2


' Note: for NTSC the colors displayed depend on the phase wrt colorburst.
' Using a different color # for colorburst will cause the colors displayed
' to shift.  i.e. using color #0 for colorburst will cause color #0 to be
' yellow rather than blue.  Dynamic changes to the colorburst color # may
' require several frames for the TV to resynchronize.
sync                    LONG    $8A0200                                         ' %%0 = -40 IRE, %%1 = 0 IRE, %%2 = burst
blank                   LONG    %%1111_1111_1111_1111                           ' 16 pixels color 1
burst                   LONG    %%2222_2222_2222_2222                           ' 16 pixels color 1


vsclhalf                LONG    1<<12+1820                                      ' NTSC H/2
vsclsync                LONG    1<<12+269                                       ' NTSC sync = 4.7us
vsclblnk                LONG    1<<12+3371                                      ' NTSC H-sync
vsclselo                LONG    1<<12+1551                                      ' NTSC H/2-sync
vscleqal                LONG    1<<12+135                                       ' NTSC sync/2
vscleqhi                LONG    1<<12+1685                                      ' NTSC H/2-sync/2
vscls2cb                LONG    1<<12+304-269                                   ' NTSC sync to colorburst
vsclbrst                LONG    16<<12+16*9                                     ' NTSC 16 PLLA per cycle, 9 cycles of colorburst

'-------------------------------------------------------------
' These parameters over written by calling SPIN program
' Defaults here do nothing and are just left overs for clarity
'-------------------------------------------------------------
ivcfg                   LONG    %0_11_1_0_1_000_00000000000_001_0_01110000      ' demoboard 
ictra                   LONG    %0_00001_110_00000000_000000_000_000000         ' NTSC
ifrqa                   LONG    $16E8_BA2F                                      ' (7,159,090.9Hz/80MHz)<<32 NTSC demoboard & Hydra 
idira                   LONG    $0000_7000                                      ' demoboard
lnram                   LONG    $0                                              ' Address of HUB Pixel Ram
clram                   LONG    $0                                              ' Address of COLOR RAM pointer
                                                                                ' loaded just prior to drawing a scanline
vsclbp                  LONG    1<<12+312                                     ' NTSC back porch + overscan (213)
vsclactv                LONG    5<<12+80                                      ' NTSC 25 PLLA per pixel, 4 pixels per frame
_vsclactv               LONG    0                                             ' Pointer to this in HUB
vsclfp                  LONG    1<<12+320                                     ' NTSC overscan (214) + front porch
numwtvd                 LONG    32                                            ' Number of waitvids
_numwtvd                LONG    0                                               'Pointer to this in HUB
two_colors              LONG    $07060402                                    'Two color per screen flag and color value
_two_colors             LONG    0                                               'Pointer to this in HUB
no_burst                LONG    1                                               'Suppress color burst, if not zero
_no_burst               LONG    1                                               'Pointer....
no_interlace            LONG    1                                               'Suppress interlace, if not zero
_no_interlace           LONG    1                                               'Pointer....
                                             

'-------------------------------------------------------------
'COG Write to HUB addresses for inter-cog communication
'-------------------------------------------------------------
tv_vblank               LONG    0                                               'set to 1 during VBLANK
tv_actv                 LONG    0                                               'set to 1 while drawing active video



{ Change log
2009-04-29    first release to forums.parallax.com
2009-04-29    fix cut&paste error (JMP #vsync0 in vsync1)
2009-04-30    make line 285 blank instead of active, add more comments & change log
2009-05-04    use MOVD instead of MOV to initialize WAITVID pointer, fixed vsclbp calculation
2009-05-05    changed burst so colors match PAL
2009-05-14    fixed non-interlaced comment, added comments about horizontal resolution
2009-06-21    added Coley's autodetection code
2009-08-10    significant changes for text driver code (ddingus)
2009-09-12    moved autodetect and video parameters to parent spin-program
2009-09-12    changed from full color to 4 color for text resolution purposes
2009-09-19    cleaned up comments and code, for text display driver purposes
2009-09-22    added color burst, interlace and monochrome 80 character @ 80 Mhz options
2009-09-23    changed cog to get color ram address from hub pointer for double buffered color
}    