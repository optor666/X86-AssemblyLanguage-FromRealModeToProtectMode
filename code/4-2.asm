; nasm -f bin 4-2.asm -o 4-2.bin
; dd if=4-2.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
; hexf '/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd'; 手动修改 0x00000200 前两个字节为 0x55 0xAA
mov ax,0xb800
mov ds,ax
mov byte [0x00],'a'
mov byte [0x02],'s'
mov byte [0x04],'m'
jmp $
