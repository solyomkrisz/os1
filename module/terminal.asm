[bits 16]
[org 0x6000]

%include "memory.inc"
%include "common.inc"
%include "exports.inc"

LSEG equ 0x0000

module_header:
    dw 2 ;export count - this will be at [module_base]

    export_0:
        dw init
        dw LSEG
        dw init_name
        dw 0

    export_1:
        dw open
        dw LSEG
        dw 0
        dw 0

    export_2: ;each entry is 8 bytes
        dw tty_put_char      ;offset - this will be at [module_base + 2 + (1*8)]
        dw LSEG              ;segment
        dw tty_put_char_name ;pointer to name
        dw 0                 ;flags

    export_3:
        dw register_command
        dw LSEG
        dw 0
        dw 0

;to init command table (where the old api table was)
init:
    ;register the first command
    push cls_cmd_name ;cmd name offset
    push LSEG ;cmd name segment
    push cls ;cmd handler offset
    push LSEG ;cmd handler segment
    push 0 ;flags
    push 0 ;help str offset
    push 0 ;help str segment
    call LSEG:register_command

    retf

input_buffer_marker: db 0xFF, 0x66, 0xFF ;next byte after 'FF 66 FF' in memory is the first byte of the input buffer
input_buffer: times 256 db 0 ;last byte is the null terminator

input_length_marker: db 0xFF, 0x77, 0xFF
input_length dw 0

;points to the next available entry in the table
cmd_table_start_offset: dw 0x7E00
cmd_table_start_segment: dw 0x0000
cmd_table_next_offset: dw 0x7E00
cmd_table_next_segment: dw 0x0000
cmd_table_cmd_count: dw 0

;name offset            18
;name segment           16
;handler offset         14
;handler segment        12
;flags                  10
;help string offset     8
;help string segment    6
;CS       <- SP + 4
;IP       <- SP + 2 
;saved bp <- SP
register_command:
    push bp
    mov bp, sp
    push ds
    push es

    mov ax, LSEG
    mov ds, ax

    mov ax, [cmd_table_next_segment]
    mov es, ax
    mov bx, [cmd_table_next_offset]

    ;save command name (first 4 bytes)
    mov ax, [bp+18] ;name offset
    mov [es:bx], ax
    mov ax, [bp+16] ;name segment
    mov [es:bx+2], ax

    ;save handler (second 4 bytes)
    mov ax, [bp+14] ;handler offset
    mov [es:bx+4], ax
    mov ax, [bp+12] ;handler segment
    mov [es:bx+6], ax

    ;save flags (2 bytes)
    mov ax, [bp+10] ;flags
    mov [es:bx+8], ax

    ;save help string (4 bytes)
    mov ax, [bp+8] ;help string offset
    mov [es:bx+10], ax
    mov ax, [bp+6] ;help string segment
    mov [es:bx+12], ax

    ;add padding (2 bytes)
    mov word [es:bx+14], 0

    ;
    ;increase cmd_table_next_offset
    ;
    add word [cmd_table_next_offset], 16

    ;
    ;increase command count
    ;
    inc word [cmd_table_cmd_count]

    pop es
    pop ds
    pop bp

    retf 14

find_and_run_cmd:
    mov cx, [cmd_table_cmd_count]

    ;ds:si - input_buffer
    ;es:di - command name from table

    ;setting up ds
    mov ax, LSEG
    mov ds, ax

    ;setting up es:di
    mov ax, [cmd_table_start_segment]
    mov es, ax
    mov bx, [cmd_table_start_offset] ;es:bx = current table entry

    .loop:
        ;setting up si - reset for each comparison
        mov si, input_buffer

        mov di, [es:bx] ;load name offset from entry
        mov ax, [es:bx+2] ;load name segment from entry
        push es ;save table segment - es:bx must be preserved
        mov es, ax ;now es:di - actual name string

        .compare:
            mov al, [ds:si]
            mov ah, [es:di]

            cmp al, ah
            jne .no_match

            cmp al, 0
            je .match

            inc si
            inc di
            jmp .compare

        .no_match:
            pop es ;restore es to table segment
            add bx, 16 ;advance to next entry
            loop .loop

    .not_found:
        call new_line

        ;print 'Unknown command.'
        mov ax, common_module_segment
        mov ds, ax

        mov ax, LSEG
        mov bx, cmd_not_found
        mov cl, 0x0F
        call far [print_str_o]

        retf

    .match:
        pop es ;restore es to table segment
        ;handler offset at [es:bx+4], segment at [es:bx+6]

        ;when match we push onto the stack the CS and IP
        ;which is popped of by retf
        ;CS:IP points to the handler so this trick
        ;calls the handler
        ;the handler must have a retf which will pop off
        ;2 bytes - this must be from where we called
        ;the find_command function, so we must call
        ;the find_command function like call SEG:OFF (far call)
        mov ax, [es:bx+6]
        push ax
        mov ax, [es:bx+4]
        push ax
        retf

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

    mov ah, 0x07
    call far [putchar_o] ;call put_char

    jmp .done

    .enter:
        mov bx, [input_length]
        mov byte [input_buffer+bx], 0 ;null terminate
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
        call far [get_cursor_flt_o]
        ;flat cursor position is in ax
        sub ax, 2 ;move it back to pos of last written char
        ;code below actually moves it there
        call far [set_cursor_flt_o]
        push ax ;save this cursor position

        mov ax, 0x0020 ;put black color and space char into ax
        call far [putchar_o] ;call put_char - put this space onto screen which in turn erases the last char

        pop ax ;restore the saved cursor position
        ;below we set the cursor back there because when we
        ;erased the last char by filling its place with a space
        ;we called the put_char function that automatically
        ;advances the cursor
        call far [set_cursor_flt_o]

        jmp .done

    .full:
        ;handle full case
    
    .done:
        pop ds
        retf

print_prompt:
    push ds
    push es

    mov ax, 0xB800
    mov es, ax

    call far [get_cursor_vec_o] ;ah = x, al = y
    ;we care about y

    ;setup for stosw
    xor ah, ah
    mov bx, 160
    mul bx
    ;ax now has the offset to the start of the newly created row (given we call this fn after calling new_line)
    mov di, ax

    mov ax, 0xB800
    mov es, ax

    ;setup for lodsb
    mov ax, LSEG
    mov ds, ax
    mov si, prompt

    .next:
        lodsb

        cmp al, 0
        je .done

        mov ah, 0x07 ;color (char in al)

        stosw

        jmp .next

    .done:
        pop es
        pop ds

        ret

new_line:
    call far [get_cursor_vec_o] ;ah = x, al = y

    mov ah, 2 ;back to beginning of line
    inc al

    call far [set_cursor_vec_o] ;already exects data in ax

    ret

open:
    ;move cursor to 1st row
    mov ax, 0x0001
    call far [set_cursor_vec_o]

    call new_line
    call print_prompt

    retf

print_inp_buf:
    ;lodsb setup
    mov ax, LSEG
    mov ds, ax ;also needed for mem access
    mov si, input_buffer

    mov cx, [input_length]

    .next:
        lodsb
        
        cmp cx, 0
        jle .done

        dec cx

        mov ah, 0x0F
        call far [putchar_o]

        jmp .next

    .done:
        ret

shell_execute:
    call LSEG:find_and_run_cmd
    call new_line
    call print_prompt

    mov word [input_length], 0

    ret

;handlers for commands registered by this module
cls:
    mov ax, 0xB800
    mov es, ax
    mov di, 160 ;start from the beginning of the 2nd row
    ;leave first row as it is since for now its a header like stuff

    mov cx, 1920 ;24 rows out of 25
    mov ax, 0x0020

    .clear_screen:
        mov [es:di], ax
        add di, 2

        loop .clear_screen

    ;move cursor to 1st row
    mov ax, 0x0001
    call far [set_cursor_vec_o]

    ;call new_line and print_prompt is done by
    ;the shell_execute function after the handler
    ;has run

    retf

init_name: db 'terminal_module_init', 0
tty_put_char_name: db 'tty_put_char', 0

prompt db '> ', 0
cmd_not_found db 'Unknown command.', 0

;data for commands registered by this module
cls_cmd_name: db 'cls', 0

times 1024 - ($ - $$) db 0