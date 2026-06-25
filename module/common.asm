[bits 16]
[org 0x4000]

LSEG equ 0x0000
%include "memory.inc"

module_header:
    dw 7

    export_0:
        dw init
        dw LSEG
        dw 0 ;name
        dw 0 ;flags

    export_1:
        dw move_cursor
        dw LSEG
        dw 0
        dw 0

    export_2:
        dw get_cursor
        dw LSEG
        dw 0
        dw 0

    export_3:
        dw set_cursor
        dw LSEG
        dw 0
        dw 0

    export_4:
        dw putchar
        dw LSEG
        dw 0
        dw 0

    export_5:
        dw print_stack
        dw LSEG
        dw 0
        dw 0

    export_6:
        dw print_hex16
        dw LSEG
        dw 0
        dw 0

init:
    retf

;stack:
;y  <- SP + 8
;x  <- SP + 6
;CS <- SP + 4
;IP <- SP + 2
;BP <- SP
;accessing memory through bp, does use a segment implicitly via ss
;max y: 25
;max x: 80
move_cursor:
    push bp
    mov bp, sp

    mov ax, LSEG ;segment which this module is loaded into
    mov ds, ax

    xor ax, ax

    ;y offset
    mov al, [bp+8] ;y from stack
    mov byte [cursor_y], al ;save y from stack into mem
    mov bl, 160
    mul bl
    mov [cursor], ax

    ;x offset
    mov al, [bp+6] ;x from stack
    mov byte [cursor_x], al ;save x from stack into mem
    mov bl, 2
    mul bl
    add [cursor], ax

    pop bp
    retf 4

;returns cursor x in ah, cursor y in al
get_cursor:
    mov ax, LSEG
    mov ds, ax

    mov ax, [cursor]

    retf

;excepts position in ax
set_cursor:
    push ax

    mov ax, LSEG
    mov ds, ax

    pop ax

    mov [cursor], ax

    retf

putchar:
    push bx
    push ds
    push es

    mov bl, al          ; save character before AX is changed

    mov ax, LSEG ;segment which this module is loaded into
    mov ds, ax

    mov ax, 0xB800
    mov es, ax

    mov di, [cursor]

    mov ah, 0x07
    mov al, bl          ; restore character

    mov [es:di], ax

    add word [cursor], 2

    pop es
    pop ds
    pop bx

    retf

;USAGE:
;push 'H'
;push 'e'
;push 'l'
;push 'l'
;push 'o'
;push 5 ;num of chars
;call print_stack
;add sp, 12 ;stack cleanup

;stack:
;'H'
;'e'
;'l'
;'l'
;'o' <- SP + 8
;5  <- SP + 6
;CS <- SP + 4
;IP <- SP + 2
;pushed bp

;CALLER MUST CLEAN UP THE STACK!!!
;add sp, (num of chars + 1) * 2 -> +1 is for the string length 
print_stack:
    push bp
    mov bp, sp

    mov cx, [bp+6]

    mov si, bp

    add si, 8 ;move past pushed bp, IP, CS and length
    ;at this point si points to the last char of the string

    ;add twice because each char is length 2
    add si, cx
    add si, cx

    sub si, 2 ;now si points to the first char of the string

    .loop:
        mov al, [ss:si]
        call LSEG:putchar
    
        sub si, 2

        dec cx
        jnz .loop

    .done:
        pop bp
        retf

print_hex16:
    pusha

    push ax

    ;print '0x' which denotes a hex value
    mov al, '0'
    call LSEG:putchar ;print '0'
    mov al, 'x'
    call LSEG:putchar ;print 'x'

    pop ax

    mov bx, ax  ;copy value
    mov cx, 4   ;4 hex digits (since register is 16 bits)

    .next:
        mov ax, bx
        shr ax, 12  ;keep top bit group (4 bit)

        mov si, ax
        mov al, [hex_digits + si]
        call LSEG:putchar

        shl bx, 4   ;move next group into place

        loop .next

    popa
    retf

hex_digits db "0123456789ABCDEF"
cursor dw 0
cursor_x db 0
cursor_y db 0

times 1024 - ($ - $$) db 0