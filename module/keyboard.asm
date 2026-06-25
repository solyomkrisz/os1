[bits 16]
[org 0x5000]

%include "memory.inc"

LSEG equ 0x0000

module_header:
    dw 2

    export_0:
        dw init
        dw LSEG
        dw 0
        dw 0 ;flags
    
    export_1:
        dw kbd_process
        dw LSEG
        dw kbd_process_name
        dw 0 ;flags

init:
    call mask_irq1

    call install_irq1_isr

    push 5
    push 0
    call far [0x4000+2+8] ;common.asm/move_cursor()

    ;print 'PS/2 SELF-TEST: '
    push 'P'
    push 'S'
    push '/'
    push '2'
    push ' '
    push 'S'
    push 'E'
    push 'L'
    push 'F'
    push '-'
    push 'T'
    push 'E'
    push 'S'
    push 'T'
    push ':'
    push ' '
    push 16
    call far [0x4000+2+5*8] ;common.asm/print_stack()
    add sp, 34

    call run_ps2_self_test ;leaves response code in ax
    call far [0x4000+2+6*8] ;print value of ax

    call disable_ps2_ports

    ;returns in ax, so we must keep it
    call init_keyboard
    call print_init_keyb_result

    call unmask_irq1

    ;move cursor
    push 0
    push 58
    call far [0x4000+2+8] ;common.asm/move_cursor()

    ;print 'LAST SCAN CODE: '
    push 'L'
    push 'A'
    push 'S'
    push 'T'
    push ' '
    push 'S'
    push 'C'
    push 'A'
    push 'N'
    push ' '
    push 'C'
    push 'O'
    push 'D'
    push 'E'
    push ':'
    push ' '
    push 16
    call far [0x4000+2+5*8] ;common.asm/print_stack()
    add sp, 34

    retf

;mask IRQ1 so BIOS INT 09h doesn't consume keyboard scan codes (etc)
;later we will install our own custom ISR so the mask can be removed then
;for now we will poll directly the keyboard controller
mask_irq1:
    in al, 0x21 ;read current PIC mask
    or al, 00000010b ;set bit 1 (IRQ1)
    out 0x21, al ;write the updated mask back

    ret

unmask_irq1:
    in al, 0x21
    and al, 11111101b
    out 0x21, al

    ret

;destroys ax, cx
;ax = 1 means success, ax = 0 means failure
wait_inp_buf_empty:
    mov cx, 0xFFFF

    .loop:
        in al, 0x64 ;read status register
        test al, 00000010b ;if 1st bit is 1 input buffer is not empty
        jz .success

        loop .loop

    ;timeout
    .failure:
        mov ax, 0
        ret

    .success:
        mov ax, 1
        ret

;destroys ax, cx
;ax = 1 means success, ax = 0 means failure
wait_outp_buf_full:
    mov cx, 0xFFFF

    .loop:
        in al, 0x64 ;read status register
        test al, 00000001b ;if bit 0 is 1, then output buffer is full
        jnz .success

        loop .loop

    ;timeout
    .failure:
        mov ax, 0
        ret

    .success:
        mov ax, 1
        ret

;ax = 1 means success, ax = 0 means failure
flush_outp_buf:
    mov cx, 10000

    .flush:
        in al, 0x64
        test al, 1 ;outp buffer full?
        jz .success

        in al, 0x60 ;read and discard outp buffer byte
        
        loop .flush

    .failure:
        mov ax, 0
        ret

    .success:
        mov ax, 1
        ret

run_ps2_self_test:
    ;wait for input buffer to be empty
    ;the input buffer is used to send commands to the controller
    ;empty means all previous commands have been processed
    call wait_inp_buf_empty
    cmp ax, 1
    jne .failure

    ;send command
    mov al, 0xAA ;controller self-test command
    out 0x64, al

    ;wait for output buffer to be full
    ;thats because the self-test result is put there by the controller
    call wait_outp_buf_full
    cmp ax, 1
    jne .failure

    ;read result
    in al, 0x60

    xor ah, ah ;clear upper byte

    ;check result
    cmp al, 0x55 ;0x55 is success
    je .success

    .failure:
        ;al contains failure code
        ;call far [0x4000+2+6*8] ;print value of ax

        ;jmp .done

    .success:
        ;print the result code
        ;call far [0x4000+2+6*8] ;print value of ax

    .done:
        ret

disable_ps2_ports:
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    mov al, 0xAD ;command for disabling first ps2 port
    out 0x64, al

    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    mov al, 0xA7 ;command for disabling second ps2 port
    out 0x64, al

    mov ax, 1
    ret

    .error:
        mov ax, 0
        ret

;ax = 1 means success, ax = 0 means error
enable_ps2_irq1:
    call wait_inp_buf_empty ;wait for previous command to be completed
    cmp ax, 1
    jne .error

    call flush_outp_buf
    cmp ax, 1
    jne .error

    mov al, 0x20 ;command for requesting config byte
    out 0x64, al ;send this command

    call wait_outp_buf_full ;wait for the controller to place this byte into outp buffer
    cmp ax, 1
    jne .error

    xor ax, ax ;clear ax, including ah and al

    in al, 0x60 ;read config byte
    or al, 00000001b ;set first byte (this will enable interrupts for the first port)

    push ax ;save modified config byte

    ;wait for inp buf to be empty before next command
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    mov al, 0x60 ;write config byte command
    out 0x64, al ;send command

    ;wait for command to be consumed
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    pop ax ;restore config byte

    out 0x60, al ;send config byte to data register

    mov ax, 1 ;if we get here everything was successful
    ret

    .error:
        ;handle error
        mov ax, 0
        ret

install_irq1_isr:
    xor ax, ax
    mov es, ax

    mov word [es:0x09*4], irq1_isr
    mov word [es:0x09*4+2], LSEG

    ret

irq1_isr:
    pusha
    push ds
    push es

    mov ax, LSEG
    mov ds, ax

    ;we get the current cursor position, then set it to where we want to print
    ;the scan code and later we set it back to the original one
    ;so the actual letters go to the right place
    call far [0x4000+2+2*8] ;common.asm/get_cursor()
    ;flat cursor position is in ax
    push ax ;save old cursor position - later we pop it into bx, as ax will have the code

    ;move cursor so we print code after 'LAST SCAN CODE: ' text
    push 0
    push 74
    call far [0x4000+2+8] ;common.asm/move_cursor()

    xor ax, ax

    in al, 0x60 ;read keyboard data

    call far [0x4000+2+6*8] ;print scancode (value of ax)

    call kbd_enqueue

    ;move cursor back as explained above
    pop ax ;restore cursor position
    call far [0x4000+2+3*8] ;common.asm/set_cursor()

    mov al, 0x20
    out 0x20, al ;send EOI

    pop es
    pop ds
    popa

    iret

;returns ax
;ax = 1 means success, ax = 0 means failure
init_keyboard:
    ;enable first PS/2 device (keyboard) as it might have been disabled
    ;again, we are sending a command so must make sure previous one has finished
    ;its processing
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    ;command below doesn't respond anything, so don't need to check outp buffer
    mov al, 0xAE ;command for enabling first PS/2 port
    out 0x64, al

    ;reset keyboard
    ;keyboard device command - responds through outp buffer
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    mov al, 0xFF
    out 0x60, al ;send reset command

    ;wait for first byte of response
    call wait_outp_buf_full
    cmp ax, 1
    jne .error

    in al, 0x60 ;read first byte of response
    cmp al, 0xFA ;first byte should be 0xFA -> ACK (command accepted)
    jne .error

    ;wait for second byte of response
    call wait_outp_buf_full
    cmp ax, 1
    jne .error

    in al, 0x60 ;read second byte of response
    cmp al, 0xAA ;second byte should be 0xAA -> keyboard self-test passed
    jne .error

    ;enable keyboard scanning
    ;after reset many keyboards don't start sending scan codes until scanning is enabled
    call wait_inp_buf_empty
    cmp ax, 1
    jne .error

    ;send command for enabling scanning
    mov al, 0xF4
    out 0x60, al

    ;wait for response
    call wait_outp_buf_full
    cmp ax, 1
    jne .error

    in al, 0x60 ;read response
    cmp al, 0xFA ;response should be 0xFA
    jne .error

    call enable_ps2_irq1
    cmp ax, 1
    jne .error

    ;keyboard is initialized, start polling scan codes

    mov ax, 1
    ret

    .error:
        mov ax, 0
        ret

;must be called after calling init_keyboard
;in that case ax has either 1 (success) or 0 (failure)
print_init_keyb_result:
    ;helper functions destroy ax so save it
    push ax

    ;move cursor to 6th row
    push 6
    push 0
    call far [0x4000+2+8] ;common.asm/move_cursor()

    ;print 'PS/2 SELF-TEST: '
    push 'K'
    push 'E'
    push 'Y'
    push 'B'
    push ' '
    push 'I'
    push 'N'
    push 'I'
    push 'T'
    push ' '
    push 'R'
    push 'E'
    push 'S'
    push 'U'
    push 'L'
    push 'T'
    push ':'
    push ' '
    push 18
    call far [0x4000+2+5*8] ;common.asm/print_stack()
    add sp, 38

    ;restore ax for the actual print
    pop ax

    ;print ax (result)
    call far [0x4000+2+6*8] ;print value of ax

    ret

;expects scan code in al register
kbd_enqueue:
    mov bx, LSEG
    mov ds, bx

    xor bx, bx
    mov bl, [kbd_head]

    mov byte [kbd_queue+bx], al

    inc byte [kbd_head]
    and byte [kbd_head], 127

    ret

;puts the dequeued item in al
kbd_dequeue:
    cli

    mov ax, LSEG
    mov ds, ax

    mov al, [kbd_head]
    cmp al, [kbd_tail]
    je .empty

    xor bx, bx
    mov bl, [kbd_tail]

    xor ax, ax
    mov al, [kbd_queue+bx]

    inc byte [kbd_tail]
    and byte [kbd_tail], 127

    sti
    clc
    ret

    .empty:
        sti
        stc
        ret

;returns the ascii code in al
kbd_process:
    .loop:
        call kbd_dequeue
        jc .done

        ;al has scan code
        ; call far [0x4000+2+6*8] ;print scancode (value of ax)

        ;skip this entry in the queue if break code
        test al, 0x80
        jnz .loop

        ;treat backspace special
        ; cmp al, 0x0E
        ; je .backspace
        
        mov bx, LSEG
        mov ds, bx

        xor bx, bx
        mov bl, al

        mov al, [scan_set1_to_ascii+bx]
        
        ;for call fars set ds to where api table is
        mov bx, 0x0000 ;api table is in segment 0
        mov ds, bx

        ;print ascii char with putchar
        ; call far [0x4000+2+4*8]

        ;hardcoded receiver
        ;later make save the pointer to an "active receiver" and call
        ;the function at that pointer with al = ascii code for char
        ;this way later multitasking can be easier to implement
        call far [0x6000+2+8] ;tty_put_char ;+2 skips export count, + (previous entries * 8) selects entry

        jmp .loop

    ;this code assumes we use vga memory
    ; .backspace:
    ;     call far [0x4000+2+2*8] ;common.asm/get_cursor()
    ;     ;ax now has cursor position

    ;     ;sub 2 bytes (one position on screen)
    ;     sub ax, 2

    ;     ;set_cursor expects new position in ax
    ;     call far [0x4000+2+3*8] ;common.asm/set_cursor()

    ;     jmp .loop

    .done:
        retf

;scan code queue related
kbd_queue: times 128 db 0
kbd_head: db 0
kbd_tail: db 0

;state related
shift_pressed: db 0
ctrl_pressed: db 0
alt_pressed: db 0

%include "scan_set1_to_ascii.inc"

kbd_process_name: db 'kbd_process', 0

times 2048 - ($ - $$) db 0