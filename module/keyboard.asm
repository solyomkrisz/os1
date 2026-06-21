[bits 16]
[org 0x5000]

init:
    call mask_irq1

    push 5
    push 0
    call far [0x7E08]

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
    call far [0x7E10]
    add sp, 34

    call run_ps2_self_test ;leaves response code in ax
    call far [0x7E14] ;print value of ax

    ;returns in ax, so we must keep it
    call init_keyboard
    call print_init_keyb_result

    retf

;mask IRQ1 so BIOS INT 09h doesn't consume keyboard scan codes (etc)
;later we will install our own custom ISR so the mask can be removed then
;for now we will poll directly the keyboard controller
mask_irq1:
    in al, 0x21 ;read current PIC mask
    or al, 00000010b ;set bit 1 (IRQ1)
    out 0x21, al ;write the updated mask back

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
        ;call far [0x7E14] ;print value of ax

        ;jmp .done

    .success:
        ;print the result code
        ;call far [0x7E14] ;print value of ax

    .done:
        ret

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
    call far [0x7E08]

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
    call far [0x7E10]
    add sp, 38

    ;restore ax for the actual print
    pop ax

    ;print ax (result)
    call far [0x7E14] ;print value of ax

    ret

times 1024 - ($ - $$) db 0