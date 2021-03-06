{{
*****************************************
*  A collection of sorting algorithms.  *
*    For Strings                        *
*  Version 1.02                         * 
*  Author: Brandon Nimon                *
*  Created: 7 February, 2011            *
*  Copyright (c) 2011 Parallax, Inc.    *
*  See end of file for terms of use.    *
***************************************** 

This started out when I needed to sort some strings. I started with the bubble sort
(suggested by some people on the forum), but quickly found much faster algorithms.
I kept working my way up to faster and faster methods. Now I have an assortment of
algorithms to suit every need.

Though only the top three (insertion, shell, and quick) should even be considered
for use, the other two are included for educational purposes. For decimal sorting
shell and quick should be the only two sorting algorithms used, as insertion sort
quickly becomes slow as the array size increases. For string sorting, this appears
not to be the case. The speed of the algorithms are largely based on the frequency
the string comparison method is called (due to it's slowness).

Each of the methods are called the same way (except quick sort) with the address of
the array, followed by the length of the array. Some methods also have ascending and
descending order option.
Quick sort is called with the address of the array, 0 (the first index of the array),
and the length of the array minus one (the last index of the array).

The structure of the array to sort is somewhat unique, but simple, and likely the
most effecient for sorting. The array to be sorted contains the addresses of each of
the strings. This way, as the array is rearranged, only the addresses are being moved
not the string itself. There is also no need to copy the strings at any point, and
the strings can be as long as needed.

In this example, the array is a word array, since addresses can only be 15 bits in
length. But if the array you are using needs to be a long, select the SPIN area of
this code, and do a "find" -> "replace all" from "WORD" to "LONG" on this file and
it will work with longs. Note that there is both a WORD and LONG version of the PASM
code.

All of the methods are "assumed to succeed", so no return value is given. The only
exception being the PASM Shell Sort, which returns 0 if no cog was available, or -1
on completion.

UPDATES:
  v1.01 (15 February, 2011):
    Added order option to quick and shell sorting. Now all methods have the option.
    Optimizations implemented in all sorting algorithms (big one in quick sort).
    Demo strings are now randomly arranged before sorting for less bias times.
  v1.02 (25 July, 2011):
    Added PASM version of Shell Sort which is up to 60 times faster than the SPIN
      variety, though it does temperarily need an extra cog to function.
}}
CON

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000                                          ' use 5MHz crystal

   #1, HOME, GOTOXY, #8, BKSP, TAB, LF, CLREOL, CLRDN, CR       ' PST formmatting control
  #14, GOTOX, GOTOY, CLS

  #0,ASC,DESC
  array_length = 140            ' adjust the number of elements in the array (sort function perform differently with more or less elements)
  loops = 10                    ' more will give a better sample set

OBJ
  '' NEITHER OBJ NEEDED FOR SORTING ALGORITHMS, ONLY NEEDED FOR THE DEMO
  DEBUG  : "FullDuplexSerial"   ' Debug
  RND    : "RealRandom"         ' get random number for shuffle 

VAR
  '' NEITHER VAR NEEDED FOR SORTING ALGORITHMS, ONLY NEEDED FOR THE DEMO
  WORD straddrs[array_length]   ' if LONGs are used (instead of WORDs), you can do a "replace all" in this file from WORD -> LONG
  LONG randAddr

PUB demo | i, start, avg
'' NOT NEEDED FOR SORTING ALGORITHMS, THERE ARE OTHER METHODS AT THE BOTTOM THAT ARE NOT NEEDED FOR THE ALGORITHMS

  DEBUG.start(31, 30, 0, 57600)
  waitcnt(clkfreq + cnt)  
  DEBUG.tx($D)

  RND.start
  randAddr := RND.random_ptr

  DEBUG.str(string(CLS, "String Sort Test", CR))
  DEBUG.str(string("Be patient while the algorithms run...", CR, CR))

  
  {fillarray(@straddrs, array_length)
  DEBUG.str(string("Example of the Source Order:", CR))
  repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)

  DEBUG.tx(CR)}

  
' ===={ Shell Sort }====
  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    shellsort(@straddrs, array_length, ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of Shell Sort (in cycles):      "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}

  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    pasmshellsort(@straddrs, array_length, ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of PASM Shell Sort (in cycles): "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}

' ===={ Quick Sort }====
  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    quicksort(@straddrs, 0, constant(array_length - 1), ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of Quick Sort (in cycles):      "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}
        

' ===={ Insertion Sort }====
  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    insertionsort(@straddrs, array_length, ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of Insertion Sort (in cycles):  "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}

   
' ===={ Cocktail Sort }====
  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    cocktailsort(@straddrs, array_length, ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of Cocktail Sort (in cycles):   "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}


' ===={ Bubble Sort }====
  avg := 0
  REPEAT loops
    fillarray(@straddrs, array_length)
     
    start := cnt
    bubblesort(@straddrs, array_length, ASC) 
    avg += cnt - start - 368
  DEBUG.str(string("Average Speed of Bubble Sort (in cycles):     "))
  DEBUG.dec(avg / loops)
  DEBUG.tx(CR)

  {repeat i from 0 to array_length - 1
    DEBUG.str(straddrs[i])
    DEBUG.tx(CR)}

  DEBUG.str(string(CR, "Done.", CR))

  repeat
    waitcnt(0)

PUB quicksort(arrayAddr, left, right, asc_desc) | pivot, leftIdx, rightIdx, tmp
'' Sorts array of addresses to strings based on string value
'' suposedly quicker with large arrays to sort, though at 90 entries, it is still slower than shell sort
'' left is the low index of the array to sort (normally 0) and right is the high index to sort (usually size-of-array minus 1)
'' It also uses a lot more stack space (due to the recursive nature of this method)
'' this optimized version sees if 15 elements or less are being sorted, if so, it uses insertion sort instead of continuing the recursion.
''   This means it's faster, and uses less stack space.
   
  IF ((tmp := right - left) > 0)                                                ' make sure there are things to sort
    IF (++tmp =< 15)
      insertionsort(@word[arrayAddr][left], tmp, asc_desc)                      ' speed things up when array is short (especially after recursion)
    ELSE
    
      leftIdx := left                                                           ' keep for recurse
      rightIdx := right                                                         ' keep for recurse
       
      pivot := (left + right) >> 1                                              ' choose pivot point in middle of array
      REPEAT WHILE (leftIdx =< pivot AND rightIdx => pivot)                     ' continue while not at pivot point 
        REPEAT WHILE (leftIdx =< pivot) 
          tmp := strcmp(word[arrayAddr][leftIdx], word[arrayAddr][pivot])       ' compare strings
          IF ((asc_desc == ASC AND tmp < 0) OR (asc_desc == DESC AND tmp > 0))  ' ascending/descending
            leftIdx++
          ELSE
            QUIT
        REPEAT WHILE (rightIdx => pivot) 
          tmp := strcmp(word[arrayAddr][rightIdx], word[arrayAddr][pivot])      ' compare strings
          IF ((asc_desc == ASC AND tmp > 0) OR (asc_desc == DESC AND tmp < 0))  ' ascending/descending
            rightIdx--
          ELSE
            QUIT
        tmp := word[arrayAddr][leftIdx]                                         ' swap the two values
        word[arrayAddr][leftIdx++] := word[arrayAddr][rightIdx]                 ' swap the two values
        word[arrayAddr][rightIdx--] := tmp                                      ' swap the two values
                                                                               
        IF (leftIdx - 1 == pivot)
          pivot := ++rightIdx
        ELSEIF (rightIdx + 1 == pivot)
          pivot := --leftIdx
      quicksort(arrayAddr, left, pivot - 1, asc_desc)                           ' recurse (left)
      quicksort(arrayAddr, pivot + 1, right, asc_desc)                          ' recurse (right)

PUB insertionsort (arrayAddr, arraylength, asc_desc) | j, i, val, scmp
'' Sorts array of addresses to strings based on string value
'' on average, faster than shell sort with smaller arrays

  arraylength--                                                                 ' reduce this so it doesn't re-evaluate each loop
  REPEAT i FROM 1 TO arraylength
    val := word[arrayAddr][i]                                                   ' store value for later 
    j := i - 1
    
    REPEAT 
      scmp := strcmp(word[arrayAddr][j], val)                                   ' compare strings
      IF ((asc_desc == ASC AND scmp > 0) OR (asc_desc == DESC AND scmp < 0))    ' ascending/descending
        word[arrayAddr][j + 1] :=  word[arrayAddr][j]                           ' insert value

        IF (--j < 0)
          QUIT  
      ELSE
        QUIT

    word[arrayAddr][j + 1] := val                                               ' place value (from earlier)
 
PUB pasmshellsort (arrayAddr, arraylength, asc_desc) : worddone
'' up to 60 times faster than SPIN version of Shell Sort
'' temperarily starts a cog to sort the array (cog shuts down when task is complete)

  wordparAddr := arrayAddr
  wordparlen := arraylength
  wordascdesc := asc_desc 
  worddone := 0

  IF (cognew(@shellsrt_word, @worddone) => 0)
    REPEAT UNTIL (worddone)

PUB shellsort (arrayAddr, arraylength, asc_desc) | inc, val, i, j, scmp
'' Sorts array of addresses to strings based on string value
'' faster than the cocktail and bubble sort, and faster than insertion sort (for arrays larger than 13 elements)

  inc := arraylength-- >> 1                                                     ' get middle point (reduce arraylength so it's not re-evaluated each loop)
  REPEAT WHILE (inc > 0)                                                        ' while still things to sort
    REPEAT i FROM inc TO arraylength
      val := word[arrayAddr][i]                                                 ' store value for later
      j := i
      REPEAT WHILE (j => inc)     
        scmp := strcmp(word[arrayAddr][j - inc], val)                           ' compare strings
        IF ((asc_desc == ASC AND scmp > 0) OR (asc_desc == DESC AND scmp < 0))  ' ascend/descend
          word[arrayAddr][j] := word[arrayAddr][j - inc]                        ' insert value
          j -= inc                                                              ' increment
        ELSE
          QUIT 
      word[arrayAddr][j] := val                                                 ' place value (from earlier) 
    inc >>= 1                                                                   ' divide by 2. optimal would be 2.2 (due to geometric stuff)

PUB cocktailsort (arrayAddr, arraylength, asc_desc) | i, begin, swapped, tmp, scmp
'' Sorts array of addresses to strings based on string value
'' approaching twice as fast as bubble sort

  begin := -1
  arraylength -= 2                                                              ' end of array minus 1 
  REPEAT
    swapped := false                                                            ' assume no changes
    
    begin++
    REPEAT i FROM begin TO arraylength                                          ' loop through array
      scmp := strcmp(word[arrayAddr][i], word[arrayAddr][i + 1])                ' compare strings
      IF (asc_desc == ASC AND scmp > 0) OR (asc_desc == DESC AND scmp < 0)      ' ascend/descend
        tmp := word[arrayAddr][i]                                               ' swap values
        word[arrayAddr][i] := word[arrayAddr][i + 1]                            ' swap values
        word[arrayAddr][i + 1] := tmp                                           ' swap values
        swapped := true
    
    IF NOT(swapped)
      QUIT
    
    swapped := false                                                            ' assume no changes
    
    arraylength--
    REPEAT i FROM arraylength TO begin                                          ' loop through array
      scmp := strcmp(word[arrayAddr][i], word[arrayAddr][i + 1])                ' compare strings
      IF (asc_desc == ASC AND scmp > 0) OR (asc_desc == DESC AND scmp < 0)      ' ascend/descend
        tmp := word[arrayAddr][i]                                               ' swap values
        word[arrayAddr][i] := word[arrayAddr][i + 1]                            ' swap values
        word[arrayAddr][i + 1] := tmp                                           ' swap values
        swapped := true

  WHILE swapped

PUB bubblesort (arrayAddr, arraylength, asc_desc) | swapped, i, tmp, scmp
'' thanks Jon "JonnyMac" McPhalen (aka Jon Williams) (jon@jonmcphalen.com) for the majority of this code
'' slowest, but simplest sorting system
  
  arraylength -= 2                                                              ' reduce this so it doesn't re-evaluate each loop
  REPEAT
    swapped := false                                                            ' assume no changes
    REPEAT i FROM 0 TO arraylength                                              ' loop through array
      scmp := strcmp(word[arrayAddr][i], word[arrayAddr][i + 1])                ' compare strings
      IF ((asc_desc == ASC AND scmp > 0) OR (asc_desc == DESC AND scmp < 0))    ' ascend/descend
        tmp := word[arrayAddr][i]                                               ' swap values
        word[arrayAddr][i] := word[arrayAddr][i + 1]                            ' swap values
        word[arrayAddr][i + 1] := tmp                                           ' swap values
        swapped := true 

  WHILE swapped

PRI strcmp (s1, s2)
'' thanks Jon "JonnyMac" McPhalen (aka Jon Williams) (jon@jonmcphalen.com) for the majority of this code
'' altered so results are not case sensitive, and slightly faster (when considering the case insensitivity)
'' may have unexpected results if string1/2 are identical up to where string1 has a space and string2 ends (0 byte) 

'' Returns 0 if strings equal, positive if s1 > s2, negative if s1 < s2

  REPEAT WHILE ((byte[s1] & constant(!$20)) == (byte[s2] & constant(!$20)))     ' if equal (not perfect case insensitivity, but fast -- we mostly work with just a-z/0-9)
    IF (byte[s1] == 0 AND byte[s2] == 0)                                        '  if at end
      RETURN 0                                                                  '    done
    ELSE
      s1++                                                                      ' advance pointers
      s2++

  RETURN (byte[s1] & constant(!$20)) - (byte[s2] & constant(!$20))              ' (not perfect case insensitivity, but fast -- we mostly work with just a-z/0-9)


'===============================================================================
'=========================[ END OF SORTING ALGORITHMS ]=========================
'===============================================================================
PUB fillarray(dest, arraylength) | i
'' fill the array with the address of each string.
'' NOT NEEDED FOR SORTING ALGORITHMS, ONLY NEEDED FOR THE DEMO
'' if LONGs are used (instead of WORDs), you can do a "replace all" in this file from WORD to LONG

  wordfill(dest, 0, arraylength)                                                ' clear array

  i := 0
  word[dest][i++ <# (arraylength - 1)] := @str1
  word[dest][i++ <# (arraylength - 1)] := @str2
  word[dest][i++ <# (arraylength - 1)] := @str3
  word[dest][i++ <# (arraylength - 1)] := @str4
  word[dest][i++ <# (arraylength - 1)] := @str5
  word[dest][i++ <# (arraylength - 1)] := @str6
  word[dest][i++ <# (arraylength - 1)] := @str7
  word[dest][i++ <# (arraylength - 1)] := @str8
  word[dest][i++ <# (arraylength - 1)] := @str9
  word[dest][i++ <# (arraylength - 1)] := @str10
  word[dest][i++ <# (arraylength - 1)] := @str11
  word[dest][i++ <# (arraylength - 1)] := @str12
  word[dest][i++ <# (arraylength - 1)] := @str13
  word[dest][i++ <# (arraylength - 1)] := @str14
  word[dest][i++ <# (arraylength - 1)] := @str15
  word[dest][i++ <# (arraylength - 1)] := @str16
  word[dest][i++ <# (arraylength - 1)] := @str17
  word[dest][i++ <# (arraylength - 1)] := @str18
  word[dest][i++ <# (arraylength - 1)] := @str19
  word[dest][i++ <# (arraylength - 1)] := @str20
  word[dest][i++ <# (arraylength - 1)] := @str21
  word[dest][i++ <# (arraylength - 1)] := @str22
  word[dest][i++ <# (arraylength - 1)] := @str23
  word[dest][i++ <# (arraylength - 1)] := @str24
  word[dest][i++ <# (arraylength - 1)] := @str25
  word[dest][i++ <# (arraylength - 1)] := @str26
  word[dest][i++ <# (arraylength - 1)] := @str27
  word[dest][i++ <# (arraylength - 1)] := @str28
  word[dest][i++ <# (arraylength - 1)] := @str29
  word[dest][i++ <# (arraylength - 1)] := @str30
  word[dest][i++ <# (arraylength - 1)] := @str31
  word[dest][i++ <# (arraylength - 1)] := @str32
  word[dest][i++ <# (arraylength - 1)] := @str33
  word[dest][i++ <# (arraylength - 1)] := @str34
  word[dest][i++ <# (arraylength - 1)] := @str35
  word[dest][i++ <# (arraylength - 1)] := @str36
  word[dest][i++ <# (arraylength - 1)] := @str37
  word[dest][i++ <# (arraylength - 1)] := @str38
  word[dest][i++ <# (arraylength - 1)] := @str39
  word[dest][i++ <# (arraylength - 1)] := @str40
  word[dest][i++ <# (arraylength - 1)] := @str41
  word[dest][i++ <# (arraylength - 1)] := @str42
  word[dest][i++ <# (arraylength - 1)] := @str43
  word[dest][i++ <# (arraylength - 1)] := @str44
  word[dest][i++ <# (arraylength - 1)] := @str45
  word[dest][i++ <# (arraylength - 1)] := @str46
  word[dest][i++ <# (arraylength - 1)] := @str47
  word[dest][i++ <# (arraylength - 1)] := @str48
  word[dest][i++ <# (arraylength - 1)] := @str49
  word[dest][i++ <# (arraylength - 1)] := @str50
  word[dest][i++ <# (arraylength - 1)] := @str51
  word[dest][i++ <# (arraylength - 1)] := @str52
  word[dest][i++ <# (arraylength - 1)] := @str53
  word[dest][i++ <# (arraylength - 1)] := @str54
  word[dest][i++ <# (arraylength - 1)] := @str55
  word[dest][i++ <# (arraylength - 1)] := @str56
  word[dest][i++ <# (arraylength - 1)] := @str57
  word[dest][i++ <# (arraylength - 1)] := @str58
  word[dest][i++ <# (arraylength - 1)] := @str59
  word[dest][i++ <# (arraylength - 1)] := @str60
  word[dest][i++ <# (arraylength - 1)] := @str61
  word[dest][i++ <# (arraylength - 1)] := @str62
  word[dest][i++ <# (arraylength - 1)] := @str63
  word[dest][i++ <# (arraylength - 1)] := @str64
  word[dest][i++ <# (arraylength - 1)] := @str65
  word[dest][i++ <# (arraylength - 1)] := @str66
  word[dest][i++ <# (arraylength - 1)] := @str67
  word[dest][i++ <# (arraylength - 1)] := @str68
  word[dest][i++ <# (arraylength - 1)] := @str69
  word[dest][i++ <# (arraylength - 1)] := @str70
  word[dest][i++ <# (arraylength - 1)] := @str71
  word[dest][i++ <# (arraylength - 1)] := @str72
  word[dest][i++ <# (arraylength - 1)] := @str73
  word[dest][i++ <# (arraylength - 1)] := @str74
  word[dest][i++ <# (arraylength - 1)] := @str75
  word[dest][i++ <# (arraylength - 1)] := @str76
  word[dest][i++ <# (arraylength - 1)] := @str77
  word[dest][i++ <# (arraylength - 1)] := @str78
  word[dest][i++ <# (arraylength - 1)] := @str79
  word[dest][i++ <# (arraylength - 1)] := @str80
  word[dest][i++ <# (arraylength - 1)] := @str81
  word[dest][i++ <# (arraylength - 1)] := @str82
  word[dest][i++ <# (arraylength - 1)] := @str83
  word[dest][i++ <# (arraylength - 1)] := @str84
  word[dest][i++ <# (arraylength - 1)] := @str85
  word[dest][i++ <# (arraylength - 1)] := @str86
  word[dest][i++ <# (arraylength - 1)] := @str87
  word[dest][i++ <# (arraylength - 1)] := @str88
  word[dest][i++ <# (arraylength - 1)] := @str89
  word[dest][i++ <# (arraylength - 1)] := @str90
  word[dest][i++ <# (arraylength - 1)] := @str91
  word[dest][i++ <# (arraylength - 1)] := @str92
  word[dest][i++ <# (arraylength - 1)] := @str93
  word[dest][i++ <# (arraylength - 1)] := @str94
  word[dest][i++ <# (arraylength - 1)] := @str95
  word[dest][i++ <# (arraylength - 1)] := @str96
  word[dest][i++ <# (arraylength - 1)] := @str97
  word[dest][i++ <# (arraylength - 1)] := @str98
  word[dest][i++ <# (arraylength - 1)] := @str99
  word[dest][i++ <# (arraylength - 1)] := @str100
  word[dest][i++ <# (arraylength - 1)] := @str101
  word[dest][i++ <# (arraylength - 1)] := @str102
  word[dest][i++ <# (arraylength - 1)] := @str103
  word[dest][i++ <# (arraylength - 1)] := @str104
  word[dest][i++ <# (arraylength - 1)] := @str105
  word[dest][i++ <# (arraylength - 1)] := @str106
  word[dest][i++ <# (arraylength - 1)] := @str107
  word[dest][i++ <# (arraylength - 1)] := @str108
  word[dest][i++ <# (arraylength - 1)] := @str109
  word[dest][i++ <# (arraylength - 1)] := @str110
  word[dest][i++ <# (arraylength - 1)] := @str111
  word[dest][i++ <# (arraylength - 1)] := @str112
  word[dest][i++ <# (arraylength - 1)] := @str113
  word[dest][i++ <# (arraylength - 1)] := @str114
  word[dest][i++ <# (arraylength - 1)] := @str115
  word[dest][i++ <# (arraylength - 1)] := @str116
  word[dest][i++ <# (arraylength - 1)] := @str117
  word[dest][i++ <# (arraylength - 1)] := @str118
  word[dest][i++ <# (arraylength - 1)] := @str119
  word[dest][i++ <# (arraylength - 1)] := @str120
  word[dest][i++ <# (arraylength - 1)] := @str121
  word[dest][i++ <# (arraylength - 1)] := @str122
  word[dest][i++ <# (arraylength - 1)] := @str123
  word[dest][i++ <# (arraylength - 1)] := @str124
  word[dest][i++ <# (arraylength - 1)] := @str125
  word[dest][i++ <# (arraylength - 1)] := @str126
  word[dest][i++ <# (arraylength - 1)] := @str127
  word[dest][i++ <# (arraylength - 1)] := @str128
  word[dest][i++ <# (arraylength - 1)] := @str129
  word[dest][i++ <# (arraylength - 1)] := @str130
  word[dest][i++ <# (arraylength - 1)] := @str131
  word[dest][i++ <# (arraylength - 1)] := @str132
  word[dest][i++ <# (arraylength - 1)] := @str133
  word[dest][i++ <# (arraylength - 1)] := @str134
  word[dest][i++ <# (arraylength - 1)] := @str135
  word[dest][i++ <# (arraylength - 1)] := @str136
  word[dest][i++ <# (arraylength - 1)] := @str137
  word[dest][i++ <# (arraylength - 1)] := @str138
  word[dest][i++ <# (arraylength - 1)] := @str139
  word[dest][i++ <# (arraylength - 1)] := @str140
                                   
  shuffle(dest, arraylength)

PUB shuffle (arrayAddr, arraylength) | i, rd, tmp
'' shuffle the array
'' NOT NEEDED FOR SORTING ALGORITHMS, ONLY NEEDED FOR THE DEMO                                                      
'' sorting algorithms can be greatly affected by the existing order of the array, so putting the array in random
''   order, then testing multiple times will give the most accurate results.

  REPEAT i FROM 0 TO arraylength - 1
    rd := ||long[randAddr] // arraylength                                       ' get random value less than arraylength
    tmp := word[arrayAddr][i]                                                   ' swap the two values
    word[arrayAddr][i] := word[arrayAddr][rd]                                   ' swap the two values
    word[arrayAddr][rd] := tmp                                                  ' swap the two values

DAT
'' NOT NEEDED FOR SORTING ALGORITHMS, ONLY NEEDED FOR THE DEMO
'                       Some excerpts from Lorem ipsum (purposely some repeated strings)
str1          byte      "Lorem ipsum dolor", 0
str2          byte      "At sollicitudin et accumsan", 0
str3          byte      "commodo adipiscing sem", 0
str4          byte      "Id dui in malesuada Sed Nam", 0
str5          byte      "ac Nam eros nunc", 0
str6          byte      "congue congue a sed quis", 0
str7          byte      "porta risus suscipit elit", 0
str8          byte      "Et eleifend", 0
str9          byte      "Aliquam odio turpis congue at vel", 0
str10         byte      "pharetra Aenean nonummy at. Urna", 0
str11         byte      "sollicitudin Praesent sodales adipiscing", 0
str12         byte      "semper Curabitur et", 0
str13         byte      "Donec pretium at", 0
str14         byte      "semper orci pulvinar et", 0
str15         byte      "ut Aliquam quis Integer", 0
str16         byte      "volutpat tellus Curabitur Curabitur quis", 0
str17         byte      "Elit commodo adipiscing sem", 0
str18         byte      "nibh. Semper neque et", 0
str19         byte      "nulla vitae. Nam pretium tellus", 0
str20         byte      "id et nec eu. Malesuada ut", 0
str21         byte      "faucibus tortor tincidunt", 0
str22         byte      "Curabitur et", 0
str23         byte      "pretium at", 0
str24         byte      "orci pulvinar et", 0
str25         byte      "Aliquam quis Integer", 0
str26         byte      "tellus Curabitur Curabitur quis", 0
str27         byte      "commodo adipiscing sem", 0
str28         byte      "Semper neque et", 0
str29         byte      "vitae. Nam pretium tellus", 0
str30         byte      "et nec eu. Malesuada ut", 0
str31         byte      "tortor tincidunt", 0
str32         byte      "it Sed et mauris pellentesque semper enim", 0
str33         byte      "sollicitudin Praesent sodales adipiscing", 0
str34         byte      "lorem ut aliquet ut sed felis", 0
str35         byte      "risus condimentum eu", 0
str36         byte      "Curabitur vitae.", 0
str37         byte      "ridiculus In ante malesuada.", 0
str38         byte      "tincidunt faucibus Pellentesque", 0
str39         byte      "consequat sem eleifend", 0
str40         byte      "ax nec nec convallis. Vitae nec", 0
str41         byte      "eget in Lorem Ut. Orci condimentum", 0
str42         byte      "fringilla non auctor", 0
str43         byte      "neque Integer Nunc.", 0
str44         byte      "vel laoreet id auctor", 0
str45         byte      "venenatis laoreet quis congue", 0
str46         byte      "libero quis. Malesuada", 0
str47         byte      "urna pretium adipiscing nec", 0
str48         byte      "sollicitudin euismod consequat", 0
str49         byte      "turpis dui ipsum.", 0
str50         byte      "Pharetra montes ante", 0
str51         byte      "vivamus id pretium nunc", 0
str52         byte      "molestie nunc tellus consequat", 0
str53         byte      "platea id", 0
str54         byte      "tortor volutpat nibh convallis", 0
str55         byte      "hendrerit ornare", 0
str56         byte      "Nam auctor justo nibh", 0
str57         byte      "tincidunt nascetur", 0
str58         byte      "faucibus faucibus mauris justo", 0
str59         byte      "vitae ac Duis at suscipit", 0
str60         byte      "Sed. Morbi", 0
str61         byte      "ullamcorper massa aliquam rhoncus", 0
str62         byte      "nascetur ut eget", 0
str63         byte      "Fusce id quis. Curabitur", 0
str64         byte      "nisl tellus augue pede neque", 0
str65         byte      "Vestibulum lorem accumsan", 0
str66         byte      "adipiscing", 0
str67         byte      "Ut congue faucibus", 0
str68         byte      "Sed ante mauris Phasellus", 0
str69         byte      "porta non ipsum In", 0
str70         byte      "sed justo eu Nulla", 0
str71         byte      "Eleifend cursus semper", 0
str72         byte      "amet Phasellus Phasellus", 0
str73         byte      "laoreet dui Pellentesque.", 0
str74         byte      "Aenean urna justo felis sollicitudin", 0
str75         byte      "ipsum sed et consequat", 0
str76         byte      "amet ut. Ante Nam", 0
str77         byte      "ligula lobortis dis pretium", 0
str78         byte      "Proin Sed Aliquam Donec ac.", 0
str79         byte      "Dapibus laoreet", 0
str80         byte      "pellentesque", 0
str81         byte      "dolor Integer et eu elit", 0
str82         byte      "pretium Ut. Orci", 0
str83         byte      "sed Phasellus faucibus", 0
str84         byte      "fames nibh Aenean", 0
str85         byte      "iaculis neque cursus elit.", 0
str86         byte      "sed magna ipsum hac", 0
str87         byte      "leo metus", 0
str88         byte      "orci dictumst fames est", 0
str89         byte      "morbi Nam Vestibulum", 0
str90         byte      "justo semper commodo. Pede", 0
str91         byte      "ullamcorper malesuada turpis vitae Integer", 0
str92         byte      "Integer amet vel. Netus feugiat", 0
str93         byte      "condimentum auctor Nunc", 0
str94         byte      "est Maecenas condimentum", 0
str95         byte      "quis Curabitur a lorem eget", 0
str96         byte      "pretium tincidunt est", 0
str97         byte      "rhoncus fermentum nascetur", 0
str98         byte      "ante Ut orci vel Quisque justo", 0
str99         byte      "est Maecenas condimentum auctor Nunc nulla wisi sit. Habitasse", 0
str100        byte      "ornare enim. Sed eget ipsum euismod", 0
str101        byte      "Phasellus augue leo In molestie tempus", 0
str102        byte      "ante lacus tincidunt euismod", 0
str103        byte      "Curabitur malesuada orci", 0
str104        byte      "Quis Phasellus cursus natoque", 0
str105        byte      "est ligula quis ut justo interdum", 0
str106        byte      "ipsum Phasellus vel arcu turpis", 0
str107        byte      "Habitasse Vestibulum metus mi", 0
str108        byte      "Sed eget ipsum euismod enim pretium", 0
str109        byte      "tortor. Mauris lorem Nam nunc", 0
str110        byte      "Nonummy feugiat nec urna natoque", 0
str111        byte      "est Maecenas condimentum auctor Nunc nulla", 0
str112        byte      "Habitasse Vestibulum metus mi metus tincidunt ipsum Phasellus", 0
str113        byte      "amet vel. Netus feugiat ut in", 0
str114        byte      "Suspendisse. Leo vel Aenean et Vivamus", 0
str115        byte      "Nonummy", 0
str116        byte      "dui nunc at at sapien. Enim auctor", 0
str117        byte      "nunc felis sollicitudin sapien cursus", 0
str118        byte      "dignissim Mauris tincidunt nascetur Quisque", 0
str119        byte      "adipiscing tincidunt ligula. Lacus", 0
str120        byte      "sollicitudin sapien cursus. Congue", 0
str121        byte      "Vivamus in felis Proin neque pretium", 0
str122        byte      "molestie Nam molestie facilisis Ut.", 0
str123        byte      "vel lacus at dui nec nonummy orci", 0
str124        byte      "Nonummy feugiat nec urna natoque", 0
str125        byte      "et Vestibulum quam vel.", 0
str126        byte      "Maecenas neque quis nisl lacus Ut", 0
str127        byte      "Dui augue ac rutrum in In congue.", 0
str128        byte      "dictumst Quisque tempus", 0
str129        byte      "Adipiscing enim feugiat pede", 0
str130        byte      "Sem vel id ac aliquam metus elit sagittis ipsum pretium turpis.", 0
str131        byte      "amet ornare quis eget a vel. Curabitur", 0
str132        byte      "Dictumst semper orci", 0
str133        byte      "at et Vestibulum quam vel.", 0
str134        byte      "Laoreet Duis nunc hendrerit ut penatibus", 0
str135        byte      "In augue adipiscing Nullam rhoncus", 0
str136        byte      "dapibus sed libero natoque odio", 0
str137        byte      "urna massa volutpat tempus", 0
str138        byte      "malesuada turpis vitae Integer amet vel. Netus feugiat ut in dictumst", 0
str139        byte      "Vestibulum ante Ut orci vel Quisque justo Aenean nunc", 0
str140        byte      "adipiscing Nullam rhoncus", 0


DAT

                        ORG
shellsrt_word
                        MOV     wparAddr2, wordparAddr

                        MOV     wpinc, wordparlen                               ' inc := arraylength
                        SHR     wpinc, #1                                       ' arraylength >> 1 

wbigloop                TJZ     wpinc, #wend                                    ' REPEAT WHILE (inc > 0)
                        MOV     widx, wpinc                                     ' REPEAT i FROM inc
wfrompinc               CMP     widx, wordparlen WZ, WC                         ' TO arraylength
              IF_AE     JMP     #wlfrompinc
                                    
                        MOV     wordparAddr, wparAddr2                          ' arrayAddr
                        MOV     waddrAdd, widx                                  ' i
                        SHL     waddrAdd, #1                                    ' [i]
                        ADD     wordparAddr, waddrAdd                           ' long[arrayAddr][i]
                        RDWORD  wpval, wordparAddr                              ' val := long[arrayAddr][i]

                        MOV     wjdx, widx                                      ' j := i

winnerloop              CMP     wjdx, wpinc     WZ, WC                          ' REPEAT WHILE (j => inc
              IF_B      JMP     #wlinnerloop

                        MOV     waddr, wparAddr2                                ' arrayAddr
                        MOV     waddrAdd, wjdx                                  ' j
                        SUB     waddrAdd, wpinc                                 ' j - inc                 
                        SHL     waddrAdd, #1                                    ' [j - inc]
                        ADD     waddr, waddrAdd                                 ' long[arrayAddr][j - inc]
                        RDWORD  wp, waddr                                       ' long[arrayAddr][j - inc]

                        MOV     wp1, wp
                        MOV     wp2, wpval
                        CALL    #wstringcmp
                        
                        CMPS    wcbyt1, #0      WZ, WC
              IF_Z      JMP     #wlinnerloop          
                        CMP     wordascdesc, #0 WZ                          
             IF_Z_AND_C JMP     #wlinnerloop                                    ' long[arrayAddr][j - inc] > val
              IF_A      JMP     #wlinnerloop                                    ' long[arrayAddr][j - inc] < val   (IF_A == IF_NZ_AND_NC)

                        MOV     wordparAddr, wparAddr2                          ' arrayAddr
                        MOV     waddrAdd, wjdx                                  ' j
                        SHL     waddrAdd, #1                                    ' [j]
                        ADD     wordparAddr, waddrAdd                           ' long[arrayAddr][j]
                        WRWORD  wp, wordparAddr                                 ' long[arrayAddr][j] := long[arrayAddr][j - inc]
                        SUBS    wjdx, wpinc                                     ' j -= inc
                        JMP     #winnerloop

wlinnerloop             MOV     wordparAddr, wparAddr2                          ' arrayAddr
                        MOV     waddrAdd, wjdx                                  ' j
                        SHL     waddrAdd, #1                                    ' [j]
                        ADD     wordparAddr, waddrAdd                           ' long[arrayAddr][j]
                        WRWORD  wpval, wordparAddr                              ' long[arrayAddr][j] := val
                        ADD     widx, #1                                        ' STEP 1
                        JMP     #wfrompinc

wlfrompinc              SHR     wpinc, #1                                       ' inc >>= 1
                        JMP     #wbigloop

wend                    WRWORD  wnegone, PAR       
                        COGID   wp                                              ' get cog id
                        COGSTOP wp                                              ' kill this cog


wstringcmp
                        RDBYTE  wbyt1, wp1                                      ' byte[s1]
                        MOV     wcbyt1, wbyt1                                   
                        ANDN    wcbyt1, wcasebit                                ' byte[s1] & constant(!$20)
                        RDBYTE  wbyt2, wp2                                      ' byte[s2]
                        MOV     wcbyt2, wbyt2 
                        ANDN    wcbyt2, wcasebit                                ' byte[s2] & constant(!$20)
                        CMP     wcbyt1, wcbyt2    WZ, WC                        ' REPEAT WHILE (byte[s1] == byte[s2])
              IF_NE     JMP     #wscomp
                        CMP     wbyt1, #0        WZ, WC                         ' IF (byte[s1] == 0
              IF_E      CMP     wbyt2, #0        WZ, WC                         ' AND byte[s2] == 0)
              IF_E      MOV     wcbyt1, #0                                      ' RETURN 0
              IF_E      JMP     #wstringcmp_ret                                 ' done.
                        ADD     wp1, #1                                         ' s1++
                        ADD     wp2, #1                                         ' s2++
                        JMP     #wstringcmp                                     

wscomp                  SUBS    wcbyt1, wcbyt2                                  ' RETURN (byte[s1] - byte[s2])

wstringcmp_ret          RET


wcasebit                LONG    $20             ' %0010_0000
wnegone                 LONG    -1              ' $FFFF_FFFF

wordparAddr             LONG    0
wordparlen              LONG    0
wordascdesc             LONG    0

wparAddr2               RES
waddrAdd                RES
waddr                   RES
wpinc                   RES
widx                    RES
wjdx                    RES
wpval                   RES

wp                      RES 
wp1                     RES 
wp2                     RES 
wbyt1                   RES 
wbyt2                   RES 
wcbyt1                  RES 
wcbyt2                  RES 

                        FIT

'=====================[ ABOVE IS FOR WORD ADDRESSES ]===========================
'===============================================================================
'=====================[ BELOW IS FOR LONG ADDRESSES ]===========================
DAT
                        ORG
shellsrt_long
                        MOV     parAddr2, longparAddr

                        MOV     pinc, longparlen                                ' inc := arraylength
                        SHR     pinc, #1                                        ' arraylength >> 1 

bigloop                 TJZ     pinc, #end                                      ' REPEAT WHILE (inc > 0)
                        MOV     idx, pinc                                       ' REPEAT i FROM inc
frompinc                CMP     idx, longparlen WZ, WC                          ' TO arraylength
              IF_AE     JMP     #lfrompinc
                                    
                        MOV     longparAddr, parAddr2                           ' arrayAddr
                        MOV     addrAdd, idx                                    ' i
                        SHL     addrAdd, #2                                     ' [i]
                        ADD     longparAddr, addrAdd                            ' long[arrayAddr][i]
                        RDLONG  pval, longparAddr                               ' val := long[arrayAddr][i]

                        MOV     jdx, idx                                        ' j := i

innerloop               CMP     jdx, pinc       WZ, WC                          ' REPEAT WHILE (j => inc
              IF_B      JMP     #linnerloop

                        MOV     addr, parAddr2                                  ' arrayAddr
                        MOV     addrAdd, jdx                                    ' j
                        SUB     addrAdd, pinc                                   ' j - inc                 
                        SHL     addrAdd, #2                                     ' [j - inc]
                        ADD     addr, addrAdd                                   ' long[arrayAddr][j - inc]
                        RDLONG  p, addr                                         ' long[arrayAddr][j - inc]

                        MOV     p1, p
                        MOV     p2, pval
                        CALL    #stringcmp
                        
                        CMPS    cbyt1, #0       WZ, WC
              IF_Z      JMP     #linnerloop          
                        CMP     longascdesc, #0 WZ                          
             IF_Z_AND_C JMP     #linnerloop                                     ' long[arrayAddr][j - inc] > val
              IF_A      JMP     #linnerloop                                     ' long[arrayAddr][j - inc] < val   (IF_A == IF_NZ_AND_NC)

                        MOV     longparAddr, parAddr2                           ' arrayAddr
                        MOV     addrAdd, jdx                                    ' j
                        SHL     addrAdd, #2                                     ' [j]
                        ADD     longparAddr, addrAdd                            ' long[arrayAddr][j]
                        WRLONG  p, longparAddr                                  ' long[arrayAddr][j] := long[arrayAddr][j - inc]
                        SUBS    jdx, pinc                                       ' j -= inc
                        JMP     #innerloop

linnerloop              MOV     longparAddr, parAddr2                           ' arrayAddr
                        MOV     addrAdd, jdx                                    ' j
                        SHL     addrAdd, #2                                     ' [j]
                        ADD     longparAddr, addrAdd                            ' long[arrayAddr][j]
                        WRLONG  pval, longparAddr                               ' long[arrayAddr][j] := val
                        ADD     idx, #1                                         ' STEP 1
                        JMP     #frompinc

lfrompinc               SHR     pinc, #1                                        ' inc >>= 1
                        JMP     #bigloop

end                     WRLONG  negone, PAR
                        COGID   p                                               ' get cog id
                        COGSTOP p                                               ' kill this cog


stringcmp
                        RDBYTE  byt1, p1                                        ' byte[s1]
                        MOV     cbyt1, byt1
                        ANDN    cbyt1, casebit                                  ' byte[s1] & constant(!$20)
                        RDBYTE  byt2, p2                                        ' byte[s2]
                        MOV     cbyt2, byt2 
                        ANDN    cbyt2, casebit                                  ' byte[s2] & constant(!$20)
                        CMP     cbyt1, cbyt2    WZ, WC                          ' REPEAT WHILE (byte[s1] == byte[s2])
              IF_NE     JMP     #scomp
                        CMP     byt1, #0        WZ, WC                          ' IF (byte[s1] == 0
              IF_E      CMP     byt2, #0        WZ, WC                          ' AND byte[s2] == 0)
              IF_E      MOV     cbyt1, #0                                       ' RETURN 0
              IF_E      JMP     #stringcmp_ret                                  ' done.
                        ADD     p1, #1                                          ' s1++
                        ADD     p2, #1                                          ' s2++
                        JMP     #stringcmp

scomp                   SUBS    cbyt1, cbyt2                                    ' RETURN (byte[s1] - byte[s2])

stringcmp_ret           RET


casebit                 LONG    $20             ' %0010_0000
negone                  LONG    -1              ' $FFFF_FFFF

longparAddr             LONG    0
longparlen              LONG    0
longascdesc             LONG    0

parAddr2                RES
addrAdd                 RES
addr                    RES
pinc                    RES
idx                     RES
jdx                     RES
pval                    RES

p                       RES 
p1                      RES 
p2                      RES 
byt1                    RES 
byt2                    RES 
cbyt1                   RES 
cbyt2                   RES 

                        FIT


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