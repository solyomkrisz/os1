[bits 16]
[org 0x5000]

init:
    call get_config

    retf

get_config:
    ;move cursor to 5th row
    push 5
    push 0
    call far [0x7E08]

    ;print 'PS/2 0x0064: '
    push 'P'
    push 'S'
    push '/'
    push '2'
    push ' '
    push '0'
    push 'x'
    push '6'
    push '4'
    push ':'
    push ' '
    push 11
    call far [0x7E10]
    add sp, 24

    ;print value of 0x64 reg
    xor ax, ax
    in al, 0x64
    call far [0x7E14]

    ret

times 1024 - ($ - $$) db 0