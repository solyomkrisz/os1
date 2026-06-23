[bits 16]
[org 0x1000]

%include "common.inc"
%include "memory.inc"
%include "disk.inc"

;disable vga text mode cursor
;it is controller through the CRT controller ports 0x3D4 and 0x3D5
;notice that the ports are more than 8 bits, so the syntax we used for
;the in/out instructions until now, won't work (this for example won't
;work: out 0x3D4, al) because the assembler will truncate it to 8 bits
;we must use dx for ports above 0xFF
mov dx, 0x3D4
mov al, 0x0A
out dx, al

mov dx, 0x3D5
in al, dx
or al, 00100000b
out dx, al

;stack setup
cli
mov ax, 0x9000
mov ss, ax
mov sp, 0xFFFE
sti

;init api table
mov word [0x7E00], 0x0000    ;next_segment
mov word [0x7E02], 0x7E04    ;next_offset

;LBA 1 - boot, LBA 2-3 - kernel, next free is LBA 4, so we load this one to 4 and 5
read_disk 0x0000, 0x2000, 2, 4, hang       ;is a module so where we load it must be its init fn
call 0x0000:0x2000

;module test
call_draw_rectangle 5, 10, 10, 15, 0x21 ;green rect
call_draw_rectangle 2, 4, 5, 20, 0x36 ;cyan rect
call_draw_rectangle 30, 10, 5, 30, 0x11 ;blue rect

;previous module is at LBA 4, 5, next free is 6 so we load this to 6 and 7
read_disk 0x3000, 0x0000, 2, 6, hang
call 0x3000:0x0000

;previous module takes up 6 and 7, we load this one to 8 and 9
read_disk 0x0000, 0x4000, 2, 8, hang
call 0x0000:0x4000

;previous module takes up 8-9 we load this one to 10-11-12-13
read_disk 0x0000, 0x5000, 4, 10, hang
call 0x0000:0x5000

;--- common.asm module test ---
;move cursor to 3th row
push 3
push 0
call far [0x7E08]

;print '0x7E04'
mov ax, 0x7E04
call far [0x7E1C]
;print ':' and ' '
mov al, ':'
call far [0x7E14]
mov al, ' '
call far [0x7E14]
;print_hex16 test - print whats at 7E10
mov ax, [0x7E04]
call far [0x7E1C]

;move cursor to 4th row
push 4
push 0
call far [0x7E08]

;print '0x7E08'
mov ax, 0x7E08
call far [0x7E1C]
;print ':' and ' '
mov al, ':'
call far [0x7E14]
mov al, ' '
call far [0x7E14]
;print_hex16 test - print whats at 7E08
mov ax, [0x7E08]
call far [0x7E1C]

;move cursor to second row where 'Type here: ' is
;which is set up in keyboard.asm's init function
mov ax, 0x0000 ;where api table is (segment)
mov ds, ax

push 1
push 11
call far [0x7E08]

main:
    ;process things
    call far [0x7E20] ;kbd_process function

    hlt
    jmp main

hang:
    hlt
    jmp hang

times 1024 - ($ - $$) db 0