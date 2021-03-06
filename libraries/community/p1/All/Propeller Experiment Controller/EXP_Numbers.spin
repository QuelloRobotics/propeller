DAT
''****************************************
''*  Simple_Numbers                      *
''*  Authors: Chip Gracey, Jon Williams  *
''*  Copyright (c) 2006 Parallax, Inc.   *
''*  See end of file for terms of use.   *
''****************************************
''
'' Provides simple numeric conversion methods; all methods return a pointer to
'' a string.
''
'' Updated... 29 APR 2006

VAR
  long  simpleidx                                                               ' pointer into string
  byte  nstr[64]                                                                ' string for numeric data

PUB ToStr(value)
'' CV - Renamed "tostr" from "dec"
'' Returns pointer to signed-decimal string

  clrstr(@nstr, 64)                                                             ' clear output string
  return decstr(value)                                                          ' return pointer to numeric string

PRI clrstr(strAddr, size)

' Clears string at strAddr
' -- also resets global character pointer (idx)

  bytefill(strAddr, 0, size)                                                    ' clear string to zeros
  simpleidx~
                                                                                ' reset index
PRI decstr(value) | div, z_pad

' Converts value to signed-decimal string equivalent
' -- characters written to current position of idx
' -- returns pointer to nstr

  if (value < 0)                                                                ' negative value?
    -value                                                                      '   yes, make positive
    nstr[simpleidx++] := "-"                                                    '   and print sign indicator

  div := 1_000_000_000                                                          ' initialize divisor
  z_pad~                                                                        ' clear zero-pad flag

  repeat 10
    if (value => div)                                                           ' printable character?
      nstr[simpleidx++] := (value / div + "0")                                  '   yes, print ASCII digit
      value //= div                                                             '   update value
      z_pad~~                                                                   '   set zflag
    elseif z_pad or (div == 1)                                                  ' printing or last column?
      nstr[simpleidx++] := "0"
    div /= 10

  return @nstr

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
DAT
''*************************************
''* Numbers v1.1                      *
''* Author: Jeff Martin               *
''* Copyright (c) 2005 Parallax, Inc. *
''* See end of file for terms of use. *
''*************************************
''
''-----------------REVISION HISTORY-----------------
'' v1.1 - 5/5/2009 fixed formatting bug caused by specifying field width smaller than location of first grouping character.

CON

DEC      =  %000_000_000_0_0_000000_01010                                       'Decimal, variable widths

VAR
  {{ VAR for Numbers Object }}
  long  BCX0, BCX1, BCX2, BCX3                                                  'BCX Workspace
  byte  Symbols[7]                                                              'Special symbols (7 characters)
  byte  StrBuf[49]                                                              'Internal String Buffer

PUB ToDec(StrAddr): Num | Idx, N, Val, Char, Base, GChar, IChar, Field
''CV - Renamed "todec" from "fromstr"
''CV - Removed Format parameter, replaced all instances with DEC
''Convert z-string (at StrAddr) to long Num using Format.
''PARAMETERS: StrAddr = Address of string buffer containing the numeric string to convert.
''            Format  = Indicates input format: base, width, etc. See "FORMAT SYNTAX" for more information.  Note: three Format elements are ignored by
''                      FromStr(): Zero/Space Padding, Hide/Show Plus Sign, and Digit Group Size.  All other elements are actively used during translation.
''RETURNS:    Long containing 32-bit signed result.
  Base := DEC & $1F #> 2 <# 16                                                  'Get base
  if GChar := DEC >> 13 & 7                                                     'Get grouping character
    GChar := Symbols[--GChar #> 0]
  if IChar := DEC >> 19 & 7                                                     'Get indicator character
    IChar := Symbols[--IChar #> 0]
  Field := DEC >> 5 & $3F - 1                                                   'Get field size, if any (subtract out sign char)
  longfill(@Idx, 0, 3)                                                          'Clear Idx, N and Val
  repeat while Char := byte[StrAddr][Idx]                                       'While not null
    if (not IChar or (IChar and Val)) and InBaseRange(Char, Base) > 0           'Found first valid digit? (with prefix indicator if required)?
      quit                                                                      '  exit to process digits
    else                                                                        'else
      if not Val := IChar and (Char == IChar)                                   '  look for indicator character (if required)
        N := Char == "-"                                                        'Update N flag if not indicator
    Idx++
  Field += Val                                                                  'Subract indicator character from remaining field size
  repeat while (Field--) and (Char := byte[StrAddr][Idx++]) and ((Val := InBaseRange(Char, Base)) > 0 or (GChar and (Char == GChar)))
    if Val                                                                      'While not null and valid digit or grouping char
      Num := Num * Base + --Val                                                 'Accumulate if valid digit
  if N
    -Num                                                                        'Negate if necessary

PRI InBaseRange(Char, Base): Value
'Compare Char against valid characters for Base (1..16) (adjusting for lower-case automatically).
'Returns 0 if Char outside valid Base chars or, if valid, returns corresponding Value+1.
   Value := ( Value -= (Char - $2F) * (Char => "0" and Char =< "9") + ((Char &= $DF) - $36) * (Char => "A" and Char =< "F") ) * -(Value < ++Base)

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
