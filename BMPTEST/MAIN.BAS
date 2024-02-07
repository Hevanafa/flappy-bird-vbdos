DECLARE SUB DrawBMP2 (source() AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION FixPixel (px AS INTEGER) AS INTEGER
DECLARE FUNCTION IsMagenta (col AS INTEGER) AS INTEGER
DECLARE SUB PIX (x AS INTEGER, y AS INTEGER, col AS INTEGER)
DECLARE SUB LoadBMP2 (target() AS INTEGER, filename AS STRING)

OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

COMMON SHARED sprite() AS INTEGER

CLS

LoadBMP2 sprite(), "PIPE.BMP"

' 320x200, 256 colours
SCREEN 13

LINE (0, 0)-(319, 199), 53, BF
DrawBMP2 sprite(), 0, 0

COLOR 15
LOCATE 22, 1
PRINT "W:" + STR$(UBOUND(sprite, 2) * 2)
LOCATE 23, 1
PRINT "H:" + STR$(UBOUND(sprite, 1))


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
    PIX left%, y% + b% - 1, px%
  END IF

  px% = FixPixel(pair% \ 256)

  IF NOT IsMagenta(px%) THEN
    PIX left% + 1, y% + b% - 1, px%
  END IF

NEXT a%, b%

DEFSNG A-Z

END SUB

FUNCTION FixPixel (px AS INTEGER) AS INTEGER

IF px < 0 THEN
  FixPixel = px + 256
ELSE
  FixPixel = px
END IF

END FUNCTION

FUNCTION IsMagenta (col AS INTEGER) AS INTEGER
  IsMagenta = col = 13
END FUNCTION

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

SUB PIX (x AS INTEGER, y AS INTEGER, col AS INTEGER)

PSET (x, y), col

END SUB

