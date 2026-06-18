[bits 16]
[org 0x4000]

%include "memory.inc"

init:
    ;register movecursor
    mov bx, [0x7E00]
    mov ax, [0x7E02]
    add bx, ax

    mov word [bx], movecursor
    mov word [bx+2], 0x0000

    add ax, API_TABLE_ENTRY_SIZE
    mov word [0x7E02], ax

    ;register putchar
    mov bx, [0x7E00]
    add bx, ax

    mov word [bx], putchar
    mov word [bx+2], 0x0000

    add ax, API_TABLE_ENTRY_SIZE
    mov word [0x7E02], ax

    ;register print_hex16
    mov bx, [0x7E00]
    add bx, ax

    mov word [bx], print_hex16
    mov word [bx+2], 0x0000

    add ax, API_TABLE_ENTRY_SIZE
    mov word [0x7E02], ax

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
movecursor:
    push bp
    mov bp, sp

    mov ax, 0x0000  ;segment which this module is loaded into
    mov ds, ax

    xor ax, ax

    ;y offset
    mov al, [bp+8] ;y
    mov bl, 160
    mul bl
    mov [cursor], ax

    ;x offset
    mov al, [bp+6] ;x
    mov bl, 2
    mul bl
    add [cursor], ax

    pop bp
    retf 4

putchar:
    push bx
    push ds
    push es

    mov bl, al          ; save character before AX is changed

    mov ax, 0x0000      ;segment which this module is loaded into
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

print_hex16:
    pusha

    push ax

    ;print '0x' which denotes a hex value
    mov al, '0'
    call 0x0000:putchar ;print '0'
    mov al, 'x'
    call 0x0000:putchar ;print 'x'

    pop ax

    mov bx, ax  ;copy value
    mov cx, 4   ;4 hex digits (since register is 16 bits)

    .next:
        mov ax, bx
        shr ax, 12  ;keep top bit group (4 bit)

        mov si, ax
        mov al, [hex_digits + si]
        call 0x0000:putchar

        shl bx, 4   ;move next group into place

        loop .next

    popa
    retf

hex_digits db "0123456789ABCDEF"
cursor dw 0

times 1024 - ($ - $$) db 0