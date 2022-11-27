; nasm -f bin c06_6-5_2.asm -l c06_6-5_2.lst -o c06_6-5_2.bin
; dd if=/dev/zero of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=510 count=1 conv=notrunc
; dd if=c06_6-5_2.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	jmp near start

data1 db 0x05,0xff,0x80,0xf0,0x97,0x30
data2 dw 0x90,0xfff0,0xa0,0x1235,0x2f,0xc0,0xc5bc

start:
	mov ax,0x7c0
	mov ds,ax

	mov cx,(data2-data1)
	mov bx,data1
	mov si,0
	mov dx,0

countdata1:
	mov al,[bx+si]
	cmp al,0
	jge L1
	inc dx
L1:
	inc si
	loop countdata1

	mov cx,(start-data2)/2
	mov bx,data2
	mov si,0
	mov dx,0

countdata2:
	mov ax,[bx+si]
	cmp ax,0
	jge L2
	inc dx
L2:
	add si,2
	loop countdata2

	jmp near $

times 510-($-$$) db 0
				 db 0x55,0xaa
