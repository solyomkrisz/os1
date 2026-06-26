;rectangle.asm
draw_rectangle_o equ 0x2000+2+8 ;o stands for offset

;common.asm
get_cursor_vec_o   equ 0x4000+2+1*8
set_cursor_vec_o   equ 0x4000+2+2*8
get_cursor_flt_o   equ 0x4000+2+3*8
set_cursor_flt_o   equ 0x4000+2+4*8
putchar_o          equ 0x4000+2+5*8
print_stack_o      equ 0x4000+2+6*8
print_hex16_o      equ 0x4000+2+7*8

;keyboard.asm
kbd_process_o   equ 0x5000+2+1*8

;terminal.asm
terminal_init_o     equ 0x6000+2+0*8
terminal_open_o     equ 0x6000+2+1*8
tty_put_char_o      equ 0x6000+2+2*8
register_command_o  equ 0x6000+2+3*8