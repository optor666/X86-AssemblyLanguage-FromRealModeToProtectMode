; nasm -f bin c10_10-3_1.asm -l c10_10-3_1.lst -o c10_10-3_1.bin
; dd if=c10_10-3_1.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=2 oseek=100 conv=notrunc
[bits 32]
mov bx,16
mov ebx,16
