[bits 16]
[org 0x7C00]

%include "memory.inc"
%include "disk.inc"

xor ax, ax
mov ds, ax

mov [BOOT_INFO + BOOT_DRIVE_OFF], dl    ;save boot drive number

read_disk KERNEL_SEG, KERNEL_OFF, KERNEL_SECTORS, KERNEL_LBA, disk_error

jmp KERNEL_SEG:KERNEL_OFF

disk_error:
    hlt
    jmp disk_error

times 510 - ($ - $$) db 0
dw 0xAA55