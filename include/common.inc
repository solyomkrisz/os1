%macro call_draw_rectangle 5
    push ds
    ; %1=x, %2=y, %3=rows, %4=cols, %5=color
    push %1
    push %2
    push %3
    push %4
    push %5
    
    ;call draw_rectangle - its loaded to 0x0000:0x2000
    mov ax, 0x0000
    mov ds, ax

    call far [0x2000+2+8]   ;given that we load draw_rectangle into the first api table entry

    pop ds
%endmacro