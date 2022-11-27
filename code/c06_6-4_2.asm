; nasm -f bin c06_6-4_2.asm -l c06_6-4_2.lst -o c06_6-4_2.bin
; dd if=/dev/zero of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=510 count=1 conv=notrunc
; dd if=c06_6-4_2.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	jmp near start

lbbtext db "LBB"
lbztext db "LBZ"
lbltext db "LBL"

start:
	mov ax,0x7c0
	mov ds,ax

	mov ax,0xb800
	mov es,ax

	mov ax,1
	mov bx,2
	cmp ax,bx
	ja lbb
	je lbz
	jb lbl
lbb:
	mov si,lbbtext
	jmp near end
lbz:
	mov si,lbztext
	jmp near end
lbl:
	mov si,lbltext
	jmp near end
end:
	mov di,0
	mov cx,3
	cld

show:
	mov al,[si]
	mov ah,0x07
	mov [es:di],ax
	inc si
	add di,2
	loop show

	jmp near $

times 510-($-$$) db 0
				 db 0x55,0xaa
