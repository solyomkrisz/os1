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

    call run_ps2_self_test

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

    ;check result
    cmp al, 0x55 ;0x55 is success
    je .success

    .failure:
        ;al contains failure code
        call far [0x7E14] ;print value of ax

        jmp .done

    .success:
        ;print the result code
        call far [0x7E14] ;print value of ax

    .done:
        ret

times 1024 - ($ - $$) db 0