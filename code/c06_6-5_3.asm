; nasm -f bin c06_6-5_3.asm -l c06_6-5_3.lst -o c06_6-5_3.bin
; dd if=/dev/zero of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=510 count=1 conv=notrunc
; dd if=c06_6-5_3.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	jmp near start


start:
	mov ax,0x7c0
	mov ds,ax

	mov cx,0
	mov ax,0
delay:
	inc ax
	loop delay

	jmp near $

times 510-($-$$) db 0
				 db 0x55,0xaa
