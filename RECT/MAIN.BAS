DECLARE FUNCTION Intersects (a AS ANY, B AS ANY) AS INTEGER
DECLARE SUB DrawRect (r AS ANY)

' 07-02-2024

OPTION EXPLICIT
OPTION BASE 1
DEFSNG A-Z

CONST true = -1
CONST false = 0

CONST KESC = 27
CONST KUP = &H48
CONST KDOWN = &H50
CONST KLEFT = &H4B
CONST KRIGHT = &H4D


TYPE rect
  x AS INTEGER
  y AS INTEGER
  w AS INTEGER
  h AS INTEGER
END TYPE

DIM a AS rect, B AS rect

a.x = 10
a.y = 10
a.w = 50
a.h = 30

B.x = 20
B.y = 20
B.w = 40
B.h = 40


SCREEN 7, , 0, 1

DIM k$

DIM SHARED active

DO
  CLS

  active = Intersects(a, B)

  DrawRect a
  DrawRect B

  PCOPY 0, 1

  k$ = INKEY$

  IF LEN(k$) = 2 THEN
    SELECT CASE ASC(RIGHT$(k$, 1))
      CASE KUP
        a.y = a.y - 3

      CASE KDOWN
        a.y = a.y + 3

      CASE KLEFT
        a.x = a.x - 3

      CASE KRIGHT
        a.x = a.x + 3
    END SELECT
  END IF

LOOP WHILE k$ <> CHR$(KESC)


SUB DrawRect (r AS rect)

DIM col%
IF active THEN
  col% = 15
ELSE
  col% = 7
END IF

LINE (r.x, r.y)-(r.x + r.w, r.y + r.h), col%, B

END SUB

FUNCTION Intersects (a AS rect, B AS rect) AS INTEGER
Intersects = (B.x < a.x + a.w) AND (a.x < (B.x + B.w)) AND (B.y < a.y + a.h) AND (a.y < B.y + B.h)
END FUNCTION

