@echo off

cd /d "%~dp0"

wsl bash -c "nasm -I include/ -f bin boot/boot.asm -o boot.bin && nasm -I include/ -f bin kernel/kernel.asm -o kernel.bin && nasm -I include/ -f bin module/rectangle.asm -o rectangle.bin && nasm -I include/ -f bin module/timer.asm -o timer.bin && nasm -I include/ -f bin module/common.asm -o common.bin && cat boot.bin kernel.bin rectangle.bin timer.bin common.bin > ekms.img"

pause