'' 8255 Programmable Peripheral Interface Driver *Demo* - version 1.0
''
'' Written 2006 by Dennis Ferron
'' For questions or comments email me at:  System.Windows.CodeSlinger@gmail.com
''
'' This program tests the ppi8255 object.
''
'' --------------------------------------------------------------------------------
''
''  Example Circuit without address decoding: 
''
'' ┌───────────┐
'' │ Propeller │     Data bus        ┌──────┐    ┌──────┐    ┌──────┐
'' │  BusD0..D7│────────────────────│      │───│      │───│      │
'' │           │    Control bus      │ 8255 │    │ 8255 │    │ 8255 │
'' │ BusRd, Wr,│────────────────────│      │───│      │───│      │
'' │ BusA0, A1,│                     └──────┘    └──────┘    └──────┘
'' │     Reset │                         CS         CS         CS
'' │           │          CsAddr = %110 │           │           │
'' │ BusCsLsb  │────────────────────────┘    = %101 │           │
'' │   ...     │────────────────────────────────────┘    = %011 │
'' │ BusCsMsb  │────────────────────────────────────────────────┘
'' └───────────┘
''
'' (Note that the parallel lines indicate shared data and control buses;
''    it does NOT mean that the 8255's are daisy chained on the previous chip's ports.)
''
''  For my test setup, I used these pin configurations:
''
''      BusD0 = pin 0           BusA0 = pin 16
''      BusD7 = pin 7           BusA1 = pin 17
''      BusRd = pin 18          BusCsLsb = pin 21
''      BusWr = pin 19          BusCsMsb = pin 23
''      BusReset = pin 20       
''
'' ---------------------------------------------------------------------------------------

CON
  _clkmode = XTAL1 + pll16x
  _xinfreq = 5_000_000

  ' 8255 I/O bus
  BusA0 = 16
  BusA1 = 17
  BusRd = 18
  BusWr = 19
  BusReset = 20

  BusCsLsb = 21
  BusCsMsb = 23

  BusD0 = 0
  BusD1 = 1
  BusD2 = 2
  BusD3 = 3
  BusD4 = 4
  BusD5 = 5
  BusD6 = 6
  BusD7 = 7

  ' These are the addresses of the 8255 ports
  PortA = 0
  PortB = 1
  PortC = 2
  Control = 3

  ' The 8255 direction register operates the opposite
  ' of the Propeller's direction register -
  ' for the 8255 control word, a low makes
  ' and output and a high makes an input.
  BusOutput = 0
  BusInput = 1

  ' These are the addresses of the 8255's in my suitcase computer.  
  BusCsDma0 = %110
  BusCsDma1 = %101
  BusCsIde = %011

OBJ
   serial : "FullDuplexSerial"
   ppi8255 : "ppi8255"

PUB start 

  Init  
  TestWrites
  TestBitSet
  TestReads

PRI Init

  ppi8255.SetPins(BusA0, BusA1, BusRd, BusWr, BusReset, BusD0, BusD7, BusCsLsb, BusCsMsb)
  ppi8255.Reset
  SetModes
  serial.start(31, 30, 0, 9600)

PRI SetModes

  SetMode(BusCsDma0)
  SetMode(BusCsDma1)
  SetMode(BusCsIde)

PRI SetMode(BusCsAddr)

  ppi8255.SetMode(BusCsAddr, PortA, 0)
  ppi8255.SetMode(BusCsAddr, PortB, 0)
  ppi8255.SetMode(BusCsAddr, PortC, 0)

PRI SetDirections(Direction)

  SetDirection(BusCsDma0, Direction)
  SetDirection(BusCsDma1, Direction)
  SetDirection(BusCsIde, Direction)

PRI SetDirection(BusCsAddr, Direction)

  ppi8255.SetDir(BusCsAddr, PortA, Direction)
  ppi8255.SetDir(BusCsAddr, PortB, Direction)
  ppi8255.SetDir(BusCsAddr, PortC, Direction) ' Port C lower direction
  ppi8255.SetDir(BusCsAddr, PortC+1, Direction) ' Port C upper direction

PRI TestReads | Data
  SetDirections(BusInput)
  Data := 0
  repeat
    TestReadBus
    waitcnt(40_000_000 + cnt)

PRI TestReadReg(CsPin, Address)
                   
  serial.str(string("Chip: "))
  serial.dec(CsPin)
  serial.str(string("  Address: "))
  serial.dec(Address)
  serial.str(string("  "))
  serial.bin(ppi8255.Read(CsPin, Address), 8)
  serial.tx(13)

PRI TestReadChip(CsPin)

  TestReadReg(CsPin, PortA)  
  TestReadReg(CsPin, PortB)
  TestReadReg(CsPin, PortC)
  TestReadReg(CsPin, Control)
  serial.tx(13)

PRI TestReadBus

  TestReadChip(BusCsDma0)
  TestReadChip(BusCsDma1)
  TestReadChip(BusCsIde)
  serial.tx(13)

PRI TestWrites | i

  SetDirections(BusOutput)

    repeat i from 0 to 255
      TestWriteBus(i)
      serial.dec(i)
      serial.tx(13)
      waitcnt(2_000_000 + cnt)

PRI TestWriteBus(i)

  TestWriteChip(BusCsDma0, i)
  TestWriteChip(BusCsDma1, i)
  TestWriteChip(BusCsIde, i)

PRI TestWriteChip(BusCsAddr, i)

  ppi8255.Write(BusCsAddr, PortA, i)
  ppi8255.Write(BusCsAddr, PortB, i)
  ppi8255.Write(BusCsAddr, PortC, i)

PRI TestBitSet | i, j

  SetDirections(BusOutput)

    repeat i from 0 to 50
      repeat j from 0 to 7
        TestBitSetBus(j, i & 1)
        serial.dec(i)
        serial.tx(" ")
        serial.dec(j)
        serial.tx(13)
        waitcnt(2_000_000 + cnt)

PRI TestBitSetBus(bit, value)

  ppi8255.SetBitC(BusCsDma0, bit, value)
  ppi8255.SetBitC(BusCsDma1, bit, value)
  ppi8255.SetBitC(BusCsIde,  bit, value)
    