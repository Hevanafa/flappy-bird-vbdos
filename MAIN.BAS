DECLARE SUB RenderPlayer ()
DECLARE SUB RenderPipes ()
DECLARE SUB RenderGround ()
DECLARE FUNCTION Intersects (a AS ANY, B AS ANY) AS INTEGER
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

COMMON SHARED spr_bird() AS INTEGER
COMMON SHARED spr_pipe() AS INTEGER
COMMON SHARED spr_ground() AS INTEGER
COMMON SHARED spr_score() AS INTEGER

TYPE rect
  x AS INTEGER
  y AS INTEGER
  w AS INTEGER
  h AS INTEGER
END TYPE

CONST true = -1
CONST false = 0
CONST KESC = 27
CONST KENTER = 13
CONST KSPACE = 32

RANDOMIZE TIMER

LoadBMP2 spr_bird(), "BIRD.BMP"
DIM SHARED spr_idx AS INTEGER
DIM spr_tl

LoadBMP2 spr_score(), "SCORE.BMP"
LoadBMP2 spr_pipe(), "PIPE.BMP"
LoadBMP2 spr_ground(), "GROUND.BMP"

DIM SHARED buffer() AS INTEGER
InitBuffer

CLS

' 320x200, 16 colours, video page 1
SCREEN 13

'ModeTest
'END

DIM SHARED score AS INTEGER
score = 0

CONST gravity = .01
DIM SHARED bottom: bottom = 200 - 16

DIM alive: alive = true
DIM SHARED player_x, player_y
player_x = 0
player_y = 100

DIM SHARED prect AS rect
prect.y = player_y
prect.w = 18
prect.h = 12

DIM SHARED vx, vy
vx = .4
vy = 0

' for iterators
DIM a AS INTEGER, B AS INTEGER
DIM left AS INTEGER, top AS INTEGER

' x, y pairs
DIM SHARED pipes(4) AS rect

FOR a = 1 TO UBOUND(pipes)
  pipes(a).x = -1000
NEXT

CONST pipe_interval = 120
DIM last_pipe_x AS INTEGER
last_pipe_x = 100


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
    IF alive THEN
      player_x = player_x + vx

      IF player_y < bottom THEN
        player_y = player_y + vy
        vy = vy + gravity
      ELSE
        alive = false
      END IF
    END IF

  END IF


  ' Update sprite
  IF alive THEN
    IF spr_tl > 0 THEN
      spr_tl = spr_tl - dt
    ELSE
      spr_tl = .5
      spr_idx = (spr_idx + 1) MOD 4
    END IF
  END IF


  FOR a = 1 TO UBOUND(pipes)
    IF pipes(a).x - player_x < -100 THEN
      IF pipes(a).x > 0 THEN
        score = score + 1
        SOUND 659, 1
        SOUND 1046, 1
      END IF

      ' respawn pipe
      pipes(a).x = last_pipe_x + pipe_interval
      pipes(a).y = Rng(30, 92)
      last_pipe_x = pipes(a).x

      EXIT FOR
    END IF
  NEXT



  ' Begin Draw
  FOR a = 1 TO UBOUND(pipes)
    left = 100 + pipes(a).x - player_x
    LINE (left, pipes(a).y)-(left + 24, pipes(a).y), 15, B
  NEXT

  RenderPlayer

  RenderPipes
  RenderGround

  RenderScore

  Flush


  LINE (100, 70)-(100, 130), 15

  ' player hitbox
  LINE (82, player_y)-(100, player_y + 12), 15, B

  COLOR 15
  LOCATE 1, 1
  PRINT player_x; player_y;

  ' LOCATE 2, 1
  ' PRINT vy;

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

DIM a%, B%
DIM pair%, left%, px%

FOR B% = 1 TO UBOUND(source, 1)
FOR a% = 1 TO UBOUND(source, 2)
  pair% = source(B%, a%)
  left% = x% + (a% - 1) * 2
  px% = FixPixel(pair% MOD 256)

  IF NOT IsMagenta(px%) THEN
    pix left%, y% + B% - 1, px%
  END IF

  px% = FixPixel(pair% \ 256)

  IF NOT IsMagenta(px%) THEN
    pix left% + 1, y% + B% - 1, px%
  END IF

NEXT a%, B%

DEFSNG A-Z

END SUB

SUB DrawRegion2 (source() AS INTEGER, srcx AS INTEGER, srcy AS INTEGER, w AS INTEGER, h AS INTEGER, dx AS INTEGER, dy AS INTEGER)

DEFINT A-Z

DIM a%, B%
DIM pair%, left%, px%

FOR B% = 1 TO h
FOR a% = 1 TO w
  pair% = source(srcy + B%, srcx + a%)
  left% = dx + (a% - 1) * 2
  px% = FixPixel(pair% MOD 256)

  IF NOT IsMagenta(px%) THEN
    pix left%, dy + B% - 1, px%
  END IF

  px% = FixPixel(pair% \ 256)

  IF NOT IsMagenta(px%) THEN
    pix left% + 1, dy + B% - 1, px%
  END IF

NEXT a%, B%

DEFSNG A-Z

END SUB

SUB FillRect (x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER, col AS INTEGER)

DIM a AS INTEGER, B AS INTEGER

FOR B = 1 TO h
FOR a = 1 TO w
  pix x + a - 1, y + B - 1, col
NEXT a, B

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

FUNCTION Intersects (a AS rect, B AS rect) AS INTEGER
Intersects = (B.x < a.x + a.w) AND (a.x < (B.x + B.w)) AND (B.y < a.y + a.h) AND (a.y < B.y + B.h)
END FUNCTION

FUNCTION IsMagenta (col AS INTEGER) AS INTEGER
  IsMagenta = col = 13
END FUNCTION

SUB Jump ()

IF player_y <= 0 THEN EXIT SUB

vy = -.8

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

DIM a AS LONG, B AS LONG, byteidx AS LONG
DIM pair

FOR B = 0 TO h - 1
FOR a = 1 TO w STEP 2
  byteidx = start + (B * (w + pad)) + a
  GET #1, byteidx, pair

  target(h - B, a \ 2 + 1) = pair
  
NEXT a, B

CLOSE #1

DEFSNG A-Z

END SUB

SUB ModeTest ()

' Mode 13h test
DIM a AS INTEGER, B AS INTEGER

FOR B = 0 TO 15
  LOCATE 1, B + 2
  PRINT USING "#"; B MOD 10
  LOCATE B + 2, 1
  PRINT USING "#"; B MOD 10

  FOR a = 0 TO 15
    LINE ((a + 1) * 8, (B + 1) * 8)-((a + 2) * 8, (B + 2) * 8), B * 16 + a, BF
NEXT a, B

LOCATE 20, 1
PRINT "Mode 13h Test"

END SUB

SUB pix (x AS INTEGER, y AS INTEGER, col AS INTEGER)

DEF SEG = VARSEG(buffer(32002))

IF y < 0 OR y >= 200 OR x < 0 OR x >= 320 THEN EXIT SUB

POKE 320& * y + x + 4, col

DEF SEG

END SUB

SUB RenderGround ()

DIM a AS INTEGER
FOR a = 0 TO 332 STEP 12
  DrawBMP2 spr_ground(), a - player_x MOD 12, INT(bottom)
NEXT

END SUB

SUB RenderPipes ()

DIM a AS INTEGER, B AS INTEGER
DIM top AS INTEGER, left AS INTEGER

FOR a = 1 TO UBOUND(pipes)
  top = pipes(a).y
  left = 100 + pipes(a).x - player_x

  IF left < 320 THEN
    ' top half
    FOR B = 0 TO top - 8 STEP 8
      DrawRegion2 spr_pipe(), 0, 8, 12, 8, left, B
    NEXT

    DrawRegion2 spr_pipe(), 0, 0, 12, 8, left, top - 8


    ' bottom half
    DrawRegion2 spr_pipe(), 0, 0, 12, 8, left, top + 70

    FOR B = top + 78 TO bottom STEP 8
      DrawRegion2 spr_pipe(), 0, 8, 12, 8, left, B
    NEXT
  END IF
NEXT

END SUB

SUB RenderPlayer ()

' 1/3 of screen width
FillRect 82, INT(player_y) - 2, 18, 16, 0

' the width parameter is half the original image
DrawRegion2 spr_bird(), spr_idx * 9, 0, 9, 12, 82, INT(player_y)

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
  DrawRegion2 spr_score(), digits(a%) * 6, 0, 6, 18, left + (a% - 1) * 12, 10
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

