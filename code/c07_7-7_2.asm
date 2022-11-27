; nasm -f bin c07_7-7_2.asm -l c07_7-7_2.lst -o c07_7-7_2.bin
; dd if=c07_7-7_2.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	jmp near start

message db '1+2+3+...+1000='

start:
	mov ax,0x7c0
	mov ds,ax

	mov ax,0xb800
	mov es,ax

	mov si,message
	mov di,0
	mov cx,start-message
@g:
	mov al,[si]
	mov [es:di],al
	inc di
	mov byte [es:di],0x07
	inc di
	inc si
	loop @g

	xor ax,ax
	xor dx,dx
	mov cx,1
@f:
	add ax,cx
	adc dx,0x0000
	inc cx
	cmp cx,1000
	jle @f

	xor cx,cx
	mov ss,cx
	mov sp,cx

	mov bx,10
	xor cx,cx
@d:
	inc cx
	div bx
	or dl,0x30
	push dx
	xor dx,dx
	cmp ax,0
	jne @d

@a:
	pop dx
	mov [es:di],dl
	inc di
	mov byte [es:di],0x07
	inc di
	loop @a

	jmp near $

times 510-($-$$) db 0
				 db 0x55,0xaa
