[bits 16]
[org 0x3000]

init:
    cli
    call init_ivt
    call init_pit
    sti

    retf

init_ivt:
    xor ax, ax
    mov es, ax

    mov word [es:0x08*4], tick
    mov word [es:0x08*4+2], 0x0000

    ret

init_pit:
    mov al, 0x36
    out 0x43, al

    mov ax, 0xFFFF  ;divisor

    out 0x40, al    ;send divisor low byte
    mov al, ah
    out 0x40, al    ;send divisor hight byte

    ret

tick:
    pusha
    push ds
    push es

    inc word [ticks]

    cmp word [ticks], 18
    jb .done

    mov word [ticks], 0
    inc word [seconds]

    ;display seconds
    mov ax, 0xB800
    mov es, ax

    mov ax, [seconds]
    xor dx, dx
    mov bx, 10
    div bx

    ;convert remainder to ascii (can only be single digit)
    add dl, '0'

    mov di, 0
    mov ah, 0x0F
    mov al, dl
    mov [es:di], ax

    .done:
        mov al, 0x20
        out 0x20, al

        pop es
        pop ds
        popa

        iret

ticks dw 0
seconds dw 0

times 1024 - ($ - $$) db 0