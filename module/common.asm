[bits 16]
[org 0x4000]

%include "memory.inc"

init:
    ;register putchar
    mov bx, [0x7E00]
    mov ax, [0x7E02]
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

putchar:
    push bx
    push ds
    push es

    mov bl, al          ; save character before AX is changed

    mov ax, 0x0000
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
cursor dw 480   ;starts at 4th row

times 1024 - ($ - $$) db 0