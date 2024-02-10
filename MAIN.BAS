DECLARE SUB SaveBestScore ()
DECLARE SUB LoadBestScore ()
DECLARE FUNCTION f_exists (filename AS STRING) AS INTEGER
DECLARE SUB KillPlayer ()
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
' watermark
COMMON SHARED spr_wm() AS INTEGER

TYPE rect
  x AS INTEGER
  y AS INTEGER
  w AS INTEGER
  h AS INTEGER
END TYPE

TYPE pipe_pair
  x AS INTEGER
  y AS INTEGER

  top AS rect
  bottom AS rect
  passed AS INTEGER
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

LoadBMP2 spr_score(), "SCORESM2.BMP"
LoadBMP2 spr_pipe(), "PIPE.BMP"
LoadBMP2 spr_ground(), "GROUND.BMP"
LoadBMP2 spr_wm(), "WM.BMP"

DIM SHARED buffer() AS INTEGER
InitBuffer

DIM last_fps_t AS DOUBLE
last_fps_t = TIMER
DIM last_fps AS INTEGER, fps AS INTEGER


CLS

' 320x200, 16 colours, video page 1
SCREEN 13

'ModeTest
'END

DIM SHARED score AS INTEGER
DIM SHARED best_score AS INTEGER
DIM SHARED is_best_score AS INTEGER

LoadBestScore

CONST gravity = .2
DIM SHARED bottom: bottom = 200 - 16

DIM SHARED alive AS INTEGER
alive = true

DIM SHARED player_x, player_y
player_x = 0
player_y = 100

DIM SHARED prect AS rect
prect.x = 0
prect.y = player_y
prect.w = 18
prect.h = 12

DIM SHARED vx, vy
vx = 1
vy = 0

' for iterators
DIM a AS INTEGER, B AS INTEGER
DIM left AS INTEGER, top AS INTEGER

' x, y pairs
DIM SHARED pipe_pairs(4) AS pipe_pair

FOR a = 1 TO UBOUND(pipe_pairs)
  pipe_pairs(a).x = -1000

  pipe_pairs(a).top.x = pipe_pairs(a).x
  pipe_pairs(a).top.y = pipe_pairs(a).y
  pipe_pairs(a).top.w = 24
  pipe_pairs(a).top.h = 150

  pipe_pairs(a).bottom.x = pipe_pairs(a).x
  pipe_pairs(a).bottom.y = pipe_pairs(a).y
  pipe_pairs(a).bottom.w = 24
  pipe_pairs(a).bottom.h = 150
  pipe_pairs(a).passed = true
NEXT


CONST pipe_interval = 80
DIM last_pipe_x AS INTEGER
last_pipe_x = 100


DIM SHARED started AS INTEGER
started = false

' for benchmarking
DIM dt, last_t
last_t = TIMER

DIM SHARED pix_count AS INTEGER


' for the delay at the end of the (preventing 30+ FPS)
DIM suppress_fps AS INTEGER
suppress_fps = true
DIM start_t AS DOUBLE


' input key
DIM ink$

' Main game loop
DO
  ink$ = INKEY$

  ' Begin Update
  pix_count = 0

  IF started THEN
    IF alive THEN
      player_x = player_x + vx
      prect.x = INT(player_x)

      IF player_y < bottom - prect.h THEN
        player_y = player_y + vy
        prect.y = INT(player_y)
        vy = vy + gravity
      ELSE
        KillPlayer
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


  ' Update pipes
  FOR a = 1 TO UBOUND(pipe_pairs)
    IF NOT pipe_pairs(a).passed AND pipe_pairs(a).x - player_x < -25 THEN
      score = score + 1
      SOUND 659, 1
      SOUND 1046, 1

      pipe_pairs(a).passed = true
    END IF

    IF Intersects(prect, pipe_pairs(a).top) OR Intersects(prect, pipe_pairs(a).bottom) THEN
      KillPlayer
      
      EXIT FOR
    END IF


    IF pipe_pairs(a).x - player_x < -110 THEN
      ' respawn pipe
      pipe_pairs(a).x = last_pipe_x + pipe_interval
      pipe_pairs(a).y = Rng(30, 92)

      ' respawn top & bottom pipes
      pipe_pairs(a).top.x = pipe_pairs(a).x
      pipe_pairs(a).top.y = pipe_pairs(a).y - pipe_pairs(a).top.h

      pipe_pairs(a).bottom.x = pipe_pairs(a).x
      pipe_pairs(a).bottom.y = pipe_pairs(a).y + 65

      last_pipe_x = pipe_pairs(a).x
      pipe_pairs(a).passed = false

      EXIT FOR
    END IF
  NEXT
  


  ' Begin Draw
  RenderPlayer
  RenderPipes
  RenderGround

  IF NOT started THEN
    DrawBMP2 spr_wm(), 134, bottom - 10
  END IF

  RenderScore

  Flush


  COLOR 15
  'LOCATE 1, 1
  'PRINT player_x; player_y;
  'LOCATE 2, 1
  'PRINT prect.x; prect.y;
  'LOCATE 3, 1
  'PRINT "Alive? "; alive;

  LOCATE 22, 1
  PRINT "PIX:" + STR$(pix_count)
  LOCATE 23, 1
  PRINT "FPS:" + STR$(last_fps)


  dt = TIMER - last_t
  last_t = TIMER

  IF TIMER - last_fps_t >= 1 THEN
    last_fps_t = TIMER
    last_fps = fps
    fps = 0
  END IF

  fps = fps + 1

  IF ink$ <> "" THEN
    SELECT CASE ink$
    CASE CHR$(KSPACE)
      IF NOT started THEN started = true
      
      Jump
    CASE CHR$(KESC)
      EXIT DO
    END SELECT
  END IF

  IF suppress_fps THEN
    start_t = TIMER
    DO: LOOP UNTIL (TIMER - start_t) >= .02
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

FUNCTION f_exists (filename AS STRING) AS INTEGER

DIM f%
f% = FREEFILE
OPEN filename$ FOR APPEND AS #f%
IF LOF(f%) THEN
  f_exists = true
ELSE
  f_exists = false
END IF
CLOSE #f%

' delete empty file
KILL filename

END FUNCTION

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

vy = -3

END SUB

SUB KillPlayer ()

alive = false

IF best_score < score THEN
  best_score = score
  is_best_score = true
END IF

SaveBestScore

END SUB

SUB LoadBestScore ()

STATIC filename$: filename$ = "score.dat"

IF NOT f_exists(filename$) THEN EXIT SUB

OPEN filename$ FOR BINARY AS #1

GET #1, 1, best_score

CLOSE #1

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

pix_count = pix_count + 1
POKE 320& * y + x + 4, col

DEF SEG

END SUB

SUB RenderGround ()

DIM a AS INTEGER
' at first, it was 0 to 332
FOR a = 92 TO 242 STEP 12
  DrawBMP2 spr_ground(), a - player_x MOD 12, INT(bottom)
NEXT

END SUB

SUB RenderPipes ()

DIM a AS INTEGER, B AS INTEGER
DIM top AS INTEGER, left AS INTEGER

' was (left < 320)
' max draw width: 150
' 85 - 24 .. 235

FOR a = 1 TO UBOUND(pipe_pairs)
  left = 82 + pipe_pairs(a).x - player_x

  IF 61 < left AND left < 235 THEN
    top = pipe_pairs(a).y

    ' top half
    FOR B = 0 TO top - 8 STEP 8
      DrawRegion2 spr_pipe(), 0, 8, 12, 8, left, B
    NEXT

    DrawRegion2 spr_pipe(), 0, 0, 12, 8, left, top - 8


    ' bottom half
    DrawRegion2 spr_pipe(), 0, 0, 12, 8, left, pipe_pairs(a).bottom.y

    FOR B = pipe_pairs(a).bottom.y + 8 TO bottom STEP 8
      DrawRegion2 spr_pipe(), 0, 8, 12, 8, left, B
    NEXT

    ' Debug hitboxes
    LINE (left, pipe_pairs(a).top.y)-(left + pipe_pairs(a).top.w, pipe_pairs(a).top.y + pipe_pairs(a).top.h), 15, B
    LINE (left, pipe_pairs(a).bottom.y)-(left + pipe_pairs(a).bottom.w, pipe_pairs(a).bottom.y + pipe_pairs(a).bottom.h), 15, B
  END IF
NEXT

END SUB

SUB RenderPlayer ()

' 1/3 of screen width
FillRect 82, INT(player_y) - 2, 18, 16, 0

' the width parameter is half the original image
DrawRegion2 spr_bird(), spr_idx * 9, 0, 9, 12, 82, INT(player_y)

' player hitbox
LINE (prect.x - player_x + 82, player_y)-(prect.x - player_x + prect.w + 82, player_y + 12), 15, B

END SUB

SUB RenderScore ()

DIM remval AS INTEGER
remval = score

DIM digits(1) AS INTEGER
DIM length: length = 1

DO
  digits(UBOUND(digits)) = remval MOD 10

  IF remval > 9 THEN
    length = length + 1
    REDIM PRESERVE digits(length) AS INTEGER
  END IF

  remval = remval \ 10
LOOP WHILE remval > 0

reverse digits()

DIM left AS INTEGER
left = 160 - (6 * UBOUND(digits)) \ 2

DIM a%
FOR a% = 1 TO UBOUND(digits)
  DrawRegion2 spr_score(), digits(a%) * 3, 0, 3, 7, left + (a% - 1) * 6, 66
NEXT

END SUB

SUB ResetGame ()

score = 0
is_best_score = false

started = false
alive = true

' Todo: reset player position & the hitbox
' Todo: reset pipe x
' Todo: reset pipes: hitboxes

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

SUB SaveBestScore ()

OPEN "score.dat" FOR BINARY AS #1

PUT #1, 1, best_score

CLOSE #1

END SUB

SUB Unshift (int_ary() AS INTEGER, item AS INTEGER)

' int_ary is BYREF by default

REDIM PRESERVE int_ary(UBOUND(int_ary) + 1) AS INTEGER

DIM a%
FOR a% = UBOUND(int_ary) - 1 TO 1 STEP -1
  int_ary(a% + 1) = int_ary(a%)
NEXT

int_ary(1) = item

END SUB

