%macro read_disk 5
    ; %1 - segment, %2 - offset, %3 - num of sectors, %4 - LBA, %5 - error handler
    mov ax, %1
    mov es, ax
    mov bx, %2

    mov ah, 0x02
    mov al, %3

    mov ch, 0
    mov cl, %4
    mov dh, 0

    mov dl, [BOOT_INFO + BOOT_DRIVE_OFF]

    int 0x13
    jc %5
%endmacro