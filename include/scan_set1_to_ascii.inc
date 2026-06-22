scan_set1_to_ascii:
    db 0          ;00
    db 27         ;01 ESC
    db '1'        ;02
    db '2'        ;03
    db '3'        ;04
    db '4'        ;05
    db '5'        ;06
    db '6'        ;07
    db '7'        ;08
    db '8'        ;09
    db '9'        ;0A
    db '0'        ;0B
    db '-'        ;0C
    db '='        ;0D
    db 8          ;0E Backspace
    db 9          ;0F Tab

    db 'q'        ;10
    db 'w'        ;11
    db 'e'        ;12
    db 'r'        ;13
    db 't'        ;14
    db 'y'        ;15
    db 'u'        ;16
    db 'i'        ;17
    db 'o'        ;18
    db 'p'        ;19
    db '['        ;1A
    db ']'        ;1B
    db 13         ;1C Enter
    db 0          ;1D Ctrl

    db 'a'        ;1E
    db 's'        ;1F
    db 'd'        ;20
    db 'f'        ;21
    db 'g'        ;22
    db 'h'        ;23
    db 'j'        ;24
    db 'k'        ;25
    db 'l'        ;26
    db ';'        ;27
    db 39         ;28 '
    db '`'        ;29
    db 0          ;2A Left Shift
    db '\'        ;2B
    
    db 'z'        ;2C
    db 'x'        ;2D
    db 'c'        ;2E
    db 'v'        ;2F
    db 'b'        ;30
    db 'n'        ;31
    db 'm'        ;32
    db ','        ;33
    db '.'        ;34
    db '/'        ;35
    db 0          ;36 Right Shift
    db '*'        ;37 Keypad *
    db 0          ;38 Alt
    db ' '        ;39 Space

    ;last defined entry is at index 39, next one would be 3A hence the 0x3A
    times 128 - 0x3A db 0 ;pad remaining entries to reach 128 bytes