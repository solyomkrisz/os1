@echo off
cd /d "%~dp0"

echo ==============================
echo Building EKMS OS image
echo ==============================

echo.
echo Building bootloader...
wsl bash -c "nasm -I include/ -f bin boot/boot.asm -o boot.bin"
if errorlevel 1 goto error

echo Building kernel...
wsl bash -c "nasm -I include/ -f bin kernel/kernel.asm -o kernel.bin"
if errorlevel 1 goto error

echo Building rectangle module...
wsl bash -c "nasm -I include/ -f bin module/rectangle.asm -o rectangle.bin"
if errorlevel 1 goto error

echo Building timer module...
wsl bash -c "nasm -I include/ -f bin module/timer.asm -o timer.bin"
if errorlevel 1 goto error

echo Building common module...
wsl bash -c "nasm -I include/ -f bin module/common.asm -o common.bin"
if errorlevel 1 goto error

echo Building keyboard module...
wsl bash -c "nasm -I include/ -f bin module/keyboard.asm -o keyboard.bin"
if errorlevel 1 goto error

echo Building terminal module...
wsl bash -c "nasm -I include/ -f bin module/terminal.asm -o terminal.bin"
if errorlevel 1 goto error

echo Building memory module...
wsl bash -c "nasm -I include/ -f bin module/memory.asm -o memory.bin"
if errorlevel 1 goto error

echo.
echo Combining binaries into ekms.img...
wsl bash -c "cat boot.bin kernel.bin rectangle.bin timer.bin common.bin keyboard.bin terminal.bin memory.bin > ekms.img"

if errorlevel 1 goto error

echo.
echo ==============================
echo Build completed successfully!
echo Created: ekms.img
echo ==============================
goto done


:error
echo.
echo ==============================
echo BUILD FAILED!
echo Check the error above.
echo ==============================


:done
pause