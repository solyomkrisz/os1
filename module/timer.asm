[bits 16]

LSEG equ 0x3000

module_header:
    dw 1 ;num of exports

    export_0:
        dw init
        dw LSEG
        dw 0 ;name of export
        dw 0 ;flags

init:
    cli
    call init_ivt
    call init_pit
    sti

    call print_ui

    retf

init_ivt:
    xor ax, ax
    mov es, ax

    mov word [es:0x08*4], tick
    mov word [es:0x08*4+2], cs

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

    mov ax, 0x3000  ;needed if we load at segment 0x3000
    mov ds, ax

    inc word [ticks]

    cmp word [ticks], 18
    jb .done

    sub word [ticks], 18 ;mov word [ticks], 0
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

    mov di, 16
    mov ah, 0x1F
    mov al, dl
    mov [es:di], ax

    .done:
        mov al, 0x20
        out 0x20, al

        pop es
        pop ds
        popa

        iret

print_ui:
    push ds

    mov ax, cs
    mov ds, ax
    mov si, msg

    mov ax, 0xB800
    mov es, ax
    xor di, di

    .next:
        lodsb

        cmp al, 0
        je .done
        
        mov ah, 0x17

        stosw

        jmp .next

    .done:
        pop ds
        ret

ticks dw 0
seconds dw 0
msg: db 'Timer: ', 0

times 1024 - ($ - $$) db 0