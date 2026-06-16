[bits 16]
[org 0x2000]

%include "memory.inc"

init:
    mov bx, [0x7E00]
    mov ax, [0x7E02]

    add bx, ax

    mov word [bx], draw_rectangle
    mov word [bx+2], 0x0000

    add ax, API_TABLE_ENTRY_SIZE
    mov word [0x7E02], ax

    retf

draw_rectangle:
    ;setup for writing into vga mem
    mov ax, 0xB800
    mov es, ax
    xor di, di

    push bp
    mov bp, sp

    ;mov cx, [bp+8]  ;without far call
    mov cx, [bp+10]  ;get rows

    .row:
        ;mov ax, [bp+8]  ;without far call
        mov ax, [bp+10] ;get rows
        sub ax, cx

        mov bx, 160     ;bytes per row
        mul bx          ;ax*bx

        mov di, ax      ;offset from 0xB800 (offset based on which row we are drawing from the ones the user requested)

        ;vertical offset
        ;mov ax, [bp+10] ;without far call
        mov ax, [bp+12] ;num of rows we want to skip
        mov bx, 160     ;bytes per row
        mul bx          ;ax now has bytes to skip
        add di, ax

        ;horizontal offset
        ;mov ax, [bp+12] ;without far call
        mov ax, [bp+14] ;num of cols to skip
        mov bx, 2       ;each col corresponds to 2 bytes
        mul bx          ;ax now has the number of bytes to skip
        add di, ax

        ;mov dx, [bp+6]  ;without far call
        mov dx, [bp+8]  ;get cols

        ;we finished using ax so we can configure the colors and letters
        ;mov ax, [bp+4]  ;without far call
        mov ax, [bp+6]  ;get color
        mov ah, al      ;move color to ah
        mov al, 0x20    ;put space into al
        
        .col:
            stosw
            dec dx
            jnz .col

        dec cx
        jz .done

        jmp .row

    .done:
        pop bp
        ;ret 10 ;near return only pops IP, leaving the far call's CS stranded on the stack
        retf 10

times 1024 - ($ - $$) db 0