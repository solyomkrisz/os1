[bits 16]
[org 0x6000]

%include "memory.inc"
%include "common.inc"

LSEG equ 0x0000

module_header:
    dw 2 ;export count - this will be at [module_base]

    export_0:
        dw init
        dw LSEG
        dw init_name
        dw 0

    export_1: ;each entry is 8 bytes
        dw tty_put_char      ;offset - this will be at [module_base + 2 + (1*8)]
        dw LSEG              ;segment
        dw tty_put_char_name ;pointer to name
        dw 0                 ;flags

init:
    retf

input_buffer_marker: db 0xFF, 0x66, 0xFF ;next byte after 'FF 66 FF' in memory is the first byte of the input buffer
input_buffer: times 256 db 0

input_length_marker: db 0xFF, 0x77, 0xFF
input_length dw 0

;expects char in al
tty_put_char:
    push ds

    mov bx, LSEG
    mov ds, bx

    cmp al, 13 ;carriage return (enter)
    je .enter

    cmp al, 8 ;backspace
    je .backspace

    ;avoid buffer overflow
    mov bx, [input_length] ;bx is later used as index into input_buffer
    cmp bx, 255
    jae .full

    ;process char
    mov byte [input_buffer+bx], al ;put char into buffer
    inc word [input_length] ;increase length

    call far [0x7E14] ;call put_char

    jmp .done

    .enter:
        call shell_execute
        jmp .done

    .backspace:
        ;prevent underflow
        cmp word [input_length], 0
        je .done

        ;decrease length and clear last char
        dec word [input_length]

        mov bx, [input_length]
        mov byte [input_buffer+bx], 0

        ;remove last char from screen
        ;first - get current cursor position (its after the last non backspace char)
        call far [0x7E0C] ;common.asm/get_cursor()
        ;flat cursor position is in ax
        sub ax, 2 ;move it back to pos of last written char
        ;code below actually moves it there
        call far [0x7E10] ;common.asm/set_cursor()
        push ax ;save this cursor position

        mov ax, 0x0020 ;put black color and space char into ax
        call far [0x7E14] ;call put_char - put this space onto screen which in turn erases the last char

        pop ax ;restore the saved cursor position
        ;below we set the cursor back there because when we
        ;erased the last char by filling its place with a space
        ;we called the put_char function that automatically
        ;advances the cursor
        call far [0x7E10] ;common.asm/set_cursor()


        jmp .done

    .full:
        ;handle full case
    
    .done:
        pop ds
        retf

shell_execute:
    call_draw_rectangle 2, 4, 5, 20, 0x36 ;cyan rect

    ret

init_name: db 'terminal_module_init', 0
tty_put_char_name: db 'tty_put_char', 0

prompt db '> ', 0

times 1024 - ($ - $$) db 0