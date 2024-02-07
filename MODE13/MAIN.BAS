OPTION EXPLICIT
OPTION BASE 1

' 06-02-2024

SCREEN 13

DIM a AS INTEGER, b AS INTEGER

FOR b = 0 TO 15
LOCATE b + 2, 1
PRINT USING "#"; b MOD 10
LOCATE 1, b + 2
PRINT USING "#"; b MOD 10

FOR a = 0 TO 15

  LINE ((a + 1) * 8, (b + 1) * 8)-((a + 2) * 8, (b + 2) * 8), b * 16 + a, BF
NEXT a, b

