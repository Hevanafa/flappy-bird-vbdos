DECLARE SUB reverse (int_ary() AS INTEGER)
DECLARE SUB Unshift (int_ary() AS INTEGER, item AS INTEGER)
DECLARE SUB RenderScore ()
DECLARE SUB FillRect (x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER, col AS INTEGER)
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

COMMON SHARED spr_score() AS INTEGER
COMMON SHARED spr_bird() AS INTEGER

CONST true = -1
CONST false = 0
CONST KESC = 27
CONST KENTER = 13
CONST KSPACE = 32

RANDOMIZE TIMER

LoadBMP2 spr_bird(), "BIRD.BMP"
DIM spr_idx AS INTEGER
DIM spr_tl
LoadBMP2 spr_score(), "SCORE.BMP"

DIM SHARED buffer() AS INTEGER
InitBuffer

CLS

' 320x200, 16 colours, video page 1
SCREEN 13

'ModeTest
'END

DIM SHARED score AS INTEGER
' score = 0
score = 12345

DIM gravity: gravity = .005
DIM bottom: bottom = 200 - 16

DIM alive: alive = true
DIM player_x, player_y
player_x = 0
player_y = 100

DIM SHARED vx, vy
vx = .2
vy = 0

DIM a AS INTEGER

' x, y pairs
DIM SHARED pipes(12) AS INTEGER


' init pipes
FOR a = 1 TO UBOUND(pipes) STEP 2
  pipes(a) = 100 + a * 80
  pipes(a + 1) = Rng(25, 75)
NEXT

DIM started AS INTEGER
started = false

DIM dt, last_t
last_t = TIMER

LINE (0, 0)-(319, 199), 1, BF

DO
  
  DIM ink$: ink$ = INKEY$
  

  ' too expensive
  'FOR a = 3 TO UBOUND(buffer)
  '  buffer(a) = 0
  'NEXT

  ' Begin Update
  IF started THEN
    player_x = player_x + vx
  END IF

  IF started AND player_y < bottom THEN
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

  ' This doesn't replace the buffer pixels
  'DEF SEG = VARSEG(buffer(32002))
  'LINE (0, INT(player_y) - 3)-(18, INT(player_y) + 15), 0, BF
  'DEF SEG


  DIM left AS INTEGER
  FOR a = 1 TO UBOUND(pipes) STEP 2
    left = 100 + pipes(a) - player_x
    LINE (left, pipes(a + 1))-(left + 24, pipes(a + 1)), 15, B
  NEXT



  ' 1/3 of screen width
  FillRect 82, INT(player_y) - 2, 18, 16, 0

  ' the width parameter is half the original image
  
  DrawRegion2 spr_bird(), spr_idx * 9, 0, 9, 12, 82, INT(player_y)

  LINE (100, 70)-(100, 130), 15

  RenderScore

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
      IF NOT started THEN started = true

      
      Jump
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
vy = -.6
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

SUB RenderScore ()

DIM remval AS INTEGER
remval = score

DIM digits(1) AS INTEGER
DIM length: length = 1

DO
  
  ' Unshift digits(), remval MOD 10
  

  digits(UBOUND(digits)) = remval MOD 10

  IF remval > 9 THEN
    length = length + 1
    REDIM PRESERVE digits(length) AS INTEGER
  END IF

  remval = remval \ 10
LOOP WHILE remval > 0

reverse digits()

DIM left AS INTEGER
left = 160 - (12 * UBOUND(digits)) \ 2

DIM a%
FOR a% = 1 TO UBOUND(digits)
  DrawRegion2 spr_score(), digits(a%) * 6, 0, 6, 18, left + (a% - 1) * 12, 20
NEXT

END SUB

SUB reverse (int_ary() AS INTEGER)

DIM a AS INTEGER, temp AS INTEGER

FOR a = 1 TO UBOUND(int_ary) \ 2
  temp = int_ary(UBOUND(int_ary) - a + 1)
  int_ary(UBOUND(int_ary) - a + 1) = int_ary(a)
  int_ary(a) = temp
NEXT

END SUB

FUNCTION Rng (min AS INTEGER, max AS INTEGER) AS INTEGER
Rng = min + INT(RND * (max - min))
END FUNCTION

SUB Unshift (int_ary() AS INTEGER, item AS INTEGER)

' int_ary is BYREF by default

REDIM PRESERVE int_ary(UBOUND(int_ary) + 1) AS INTEGER

DIM a%
FOR a% = UBOUND(int_ary) - 1 TO 1 STEP -1
  int_ary(a% + 1) = int_ary(a%)
NEXT

int_ary(1) = item

END SUB

