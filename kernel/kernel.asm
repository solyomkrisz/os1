[bits 16]
[org 0x1000]

%include "common.inc"
%include "memory.inc"
%include "disk.inc"

;stack setup
cli
mov ax, 0x9000
mov ss, ax
mov sp, 0xFFFE
sti

;init api table
mov word [0x7E00], 0x0000    ;next_segment
mov word [0x7E02], 0x7E04    ;next_offset

;LBA 1 - boot, LBA 2-3 - kernel, next free is LBA 4
read_disk 0x0000, 0x2000, 2, 4, hang       ;is a module so where we load it must be its init fn
call 0x0000:0x2000

;previous module is at LBA 4, 5
read_disk 0x3000, 0x0000, 2, 6, hang
call 0x3000:0x0000

;previous module is at LBA 5, 6
read_disk 0x0000, 0x4000, 2, 8, hang
call 0x0000:0x4000

;module test
call_draw_rectangle 5, 10, 10, 15, 0x21 ;green rect
call_draw_rectangle 2, 4, 5, 20, 0x36 ;cyan rect
call_draw_rectangle 30, 10, 5, 30, 0x11 ;blue rect

;common.asm module test
mov al, 'A'
call far [0x7E08]
mov al, 'X'
call far [0x7E08]
mov al, ':'
call far [0x7E08]
mov al, ' '
call far [0x7E08]

;print_hex16 test
mov ax, [0x7E0C]
call far [0x7E0C]

hang:
    hlt
    jmp hang

times 1024 - ($ - $$) db 0