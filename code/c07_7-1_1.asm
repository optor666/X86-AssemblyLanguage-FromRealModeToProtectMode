; nasm -f bin c07_7-1_1.asm -l c07_7-1_1.lst -o c07_7-1_1.bin
; dd if=c07_7-1_1.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	jmp near start

data db 0x55,0xaa

start:
	mov ax,0x7c0
	mov ds,ax

	mov ax,0xfff0
	and [data],ax
	or ax,[data]

	jmp near $

times 510-($-$$) db 0
				 db 0x55,0xaa
