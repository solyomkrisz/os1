%macro call_draw_rectangle 5
    ; %1=x, %2=y, %3=rows, %4=cols, %5=color
    push %1
    push %2
    push %3
    push %4
    push %5
    ;call draw_rectangle
    call far [0x7E04]   ;given that we load draw_rectangle into the first api table entry
%endmacro