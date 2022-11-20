; nasm -f bin c05_exercises01.asm -l c05_exercises01.lst -o c05_exercises01.bin
; dd if=/dev/zero of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=510 count=1 conv=notrunc
; dd if=c05_exercises01.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
mov ax,21015
mov bl,10
div bl
and cl,0xf0
