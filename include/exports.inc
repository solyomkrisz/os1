;rectangle.asm
draw_rectangle_o equ 0x2000+2+8 ;o stands for offset

;common.asm
move_cursor_o   equ 0x4000+2+1*8
get_cursor_o    equ 0x4000+2+2*8
set_cursor_o    equ 0x4000+2+3*8
putchar_o       equ 0x4000+2+4*8
print_stack_o   equ 0x4000+2+5*8
print_hex16_o   equ 0x4000+2+6*8

;keyboard.asm
kbd_process_o   equ 0x5000+2+1*8

;terminal.asm
tty_put_char_o  equ 0x6000+2+1*8