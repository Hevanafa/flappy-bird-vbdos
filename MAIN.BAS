DECLARE SUB FillRect (x AS INTEGER, y AS INTEGER, w AS INTEGER, y AS INTEGER, col AS INTEGER)
DECLARE SUB DrawRegion2 (source() AS INTEGER, srcx AS INTEGER, srcy AS INTEGER, w AS INTEGER, h AS INTEGER, dx AS INTEGER, dy AS INTEGER)
DECLARE SUB ModeTest ()
DECLARE FUNCTION Rng (min AS INTEGER, max AS INTEGER) AS INTEGER
DECLARE SUB InitBuffer ()
DECLARE SUB Flush ()
DECLARE SUB DrawBMP2 (source() AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION FixPixel (px AS INTEGER) AS INTEGER
DECLARE FUNCTION IsMagenta (col AS INTEGER) AS INTEGER
DECLARE SUB pix (x AS INTEGER, y AS INTEGER, col AS INTEGER)
DECLARE SUB LoadBMP2 (target() AS INTEGER, filename AS STRING)
DECLARE SUB Jump ()

OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

COMMON SHARED sprite_ex() AS INTEGER

CONST True = -1
CONST False = 0
CONST KESC = 27
CONST KENTER = 13
CONST KSPACE = 32

LoadBMP2 sprite_ex(), "BIRD.BMP"
DIM spr_idx AS INTEGER
DIM spr_tl

DIM SHARED buffer() AS INTEGER
InitBuffer

CLS

' 320x200, 16 colours, video page 1
SCREEN 13

'ModeTest
'END


DIM gravity: gravity = .01
DIM bottom: bottom = 200 - 16

DIM player_x, player_y, vy
player_x = 25
player_y = 1
vy = 0

DIM a AS INTEGER

DIM dt, last_t
last_t = TIMER

DO
  
  DIM ink$: ink$ = INKEY$

  ' too expensive
  'FOR a = 3 TO UBOUND(buffer)
  '  buffer(a) = 0
  'NEXT

  ' Begin Update
  IF player_y < bottom THEN
    player_y = player_y + vy
    vy = vy + gravity
  END IF

  IF spr_tl > 0 THEN
    spr_tl = spr_tl - dt
  ELSE
    spr_tl = .5
    spr_idx = (spr_idx + 1) MOD 4
  END IF


  ' Begin Draw
  ' DrawBMP2 sprite_ex(), 0, INT(player_y)

  FillRect 0, INT(player_y) - 2, 18, 16, 0

  ' This doesn't replace the buffer pixels
  'DEF SEG = VARSEG(buffer(32002))
  'LINE (0, INT(player_y) - 3)-(18, INT(player_y) + 15), 0, BF
  'DEF SEG


  ' the width parameter is half the original image
  DrawRegion2 sprite_ex(), spr_idx * 9, 0, 9, 12, 0, INT(player_y)

  Flush

  COLOR 15
  LOCATE 1, 1
  PRINT player_y;

  LOCATE 2, 1
  PRINT vy;

  dt = TIMER - last_t
  last_t = TIMER

  IF ink$ <> "" THEN
    SELECT CASE ink$
    CASE CHR$(KSPACE)
      vy = -1
      ' Jump
    CASE CHR$(KESC)
      EXIT DO
    END SELECT
  END IF

LOOP

SUB DrawBMP2 (source() AS INTEGER, x%, y%)

DEFINT A-Z

DIM a%, b%
DIM pair%, left%, px%

FOR b% = 1 TO UBOUND(source, 1)
FOR a% = 1 TO UBOUND(source, 2)
  pair% = source(b%, a%)
  left% = x% + (a% - 1) * 2
  px% = FixPixel(pair% MOD 256)

  IF NOT IsMagenta(px%) THEN
    pix left%, y% + b% - 1, px%
  END IF

  px% = FixPixel(pair% \ 256)

  IF NOT IsMagenta(px%) THEN
    pix left% + 1, y% + b% - 1, px%
  END IF

NEXT a%, b%

DEFSNG A-Z

END SUB

SUB DrawRegion2 (source() AS INTEGER, srcx AS INTEGER, srcy AS INTEGER, w AS INTEGER, h AS INTEGER, dx AS INTEGER, dy AS INTEGER)

DEFINT A-Z

DIM a%, b%
DIM pair%, left%, px%

FOR b% = 1 TO h
FOR a% = 1 TO w
  pair% = source(srcy + b%, srcx + a%)
  left% = dx + (a% - 1) * 2
  px% = FixPixel(pair% MOD 256)

  IF NOT IsMagenta(px%) THEN
    pix left%, dy + b% - 1, px%
  END IF

  px% = FixPixel(pair% \ 256)

  IF NOT IsMagenta(px%) THEN
    pix left% + 1, dy + b% - 1, px%
  END IF

NEXT a%, b%

DEFSNG A-Z

END SUB

SUB FillRect (x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER, col AS INTEGER)

DIM a AS INTEGER, b AS INTEGER

FOR b = 1 TO h
FOR a = 1 TO w
  pix x + a - 1, y + b - 1, col
NEXT a, b

END SUB

FUNCTION FixPixel (px AS INTEGER) AS INTEGER

IF px < 0 THEN
  FixPixel = px + 256
ELSE
  FixPixel = px
END IF

END FUNCTION

SUB Flush ()
PUT (0, 0), buffer, PSET
END SUB

SUB InitBuffer ()

ERASE buffer
REDIM buffer(32002) AS INTEGER
buffer(1) = 320 * 8
buffer(2) = 200

END SUB

FUNCTION IsMagenta (col AS INTEGER) AS INTEGER
  IsMagenta = col = 13
END FUNCTION

SUB Jump ()
END SUB

SUB LoadBMP2 (target() AS INTEGER, filename AS STRING)

' target is BYREF by default
' Uses 1 cell for 2 pixels
' First index is 1

DEFINT A-Z

DIM w, h
OPEN filename FOR BINARY AS #1

GET #1, 19, w
GET #1, 23, h

REDIM target(h, w \ 2) AS INTEGER

DIM pad, palsize

pad = (4 - w MOD 4) MOD 4

GET #1, 51, palsize
DIM start AS LONG
start = 54 + palsize * 4

DIM a AS LONG, b AS LONG, byteidx AS LONG
DIM pair

FOR b = 0 TO h - 1
FOR a = 1 TO w STEP 2
  byteidx = start + (b * (w + pad)) + a
  GET #1, byteidx, pair

  target(h - b, a \ 2 + 1) = pair
  
NEXT a, b

CLOSE #1

DEFSNG A-Z

END SUB

SUB ModeTest ()

' Mode 13h test
DIM a AS INTEGER, b AS INTEGER

FOR b = 0 TO 15
  LOCATE 1, b + 2
  PRINT USING "#"; b MOD 10
  LOCATE b + 2, 1
  PRINT USING "#"; b MOD 10

  FOR a = 0 TO 15
    LINE ((a + 1) * 8, (b + 1) * 8)-((a + 2) * 8, (b + 2) * 8), b * 16 + a, BF
NEXT a, b

LOCATE 20, 1
PRINT "Mode 13h Test"

END SUB

SUB pix (x AS INTEGER, y AS INTEGER, col AS INTEGER)

DEF SEG = VARSEG(buffer(32002))

IF y < 0 OR y >= 200 OR x < 0 OR x >= 320 THEN EXIT SUB

POKE 320& * y + x + 4, col

DEF SEG

END SUB

FUNCTION Rng (min AS INTEGER, max AS INTEGER) AS INTEGER
Rng = min + INT(RND * (max - min))
END FUNCTION

