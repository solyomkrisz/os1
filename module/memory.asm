[bits 16]

%include "exports.inc"

LSEG equ 0x1000

module_header:
    dw 1

    export_0:
        dw init
        dw LSEG
        dw 0 ;fn name
        dw 0 ;flags

init:
    ;register commands
    mov ax, terminal_module_segment
    mov ds, ax

    push smem_cmd_name
    push LSEG
    push smem
    push LSEG
    push 0 ;flags
    push 0 ;help offset
    push 0 ;help segment
    call far [register_command_o]

    retf

;segment must be in ES
;offset must be in SI
print_smem_row_prefix:
    mov ax, es
    mov dh, 0x0F
    call far [print_hex16_o]
    
    mov ah, 0x0F
    mov al, ':'
    call far [putchar_o]

    mov ax, si
    mov dh, 0x0F
    call far [print_hex16_o]

    call far [print_tab_o]

    ret

smem:
    push ds
    push es

    ;ds 0x0000 for function pointer table lookups
    ;es 0x1000 for reading this module's memory
    mov ax, terminal_module_segment
    mov ds, ax
    mov ax, LSEG
    mov es, ax

    mov si, 0x0000
    
    call far [new_line_o]
    call print_smem_row_prefix ;do first row prefix printing separately

    mov cx, 54
    mov dx, 0

    .loop:
        push cx ;save loop count

        cmp dx, 8
        jl .skip_newline

        call far [new_line_o]
        call print_smem_row_prefix
        mov dx, 0

        .skip_newline:

        push dx

        mov al, [es:si] ;read word from memory
        mov dh, 0x0F
        call far [print_hex8_o]

        mov ah, 0x0F
        mov al, ' '
        call far [putchar_o]

        add si, 1

        pop dx
        pop cx
        inc dx

        loop .loop

    pop es
    pop ds
    retf

;command names
smem_cmd_name: db 'smem', 0

times 1024 - ($ - $$) db 0