; nasm -f bin c08_mbr.asm -l c08_mbr.lst -o c08_mbr.bin
; dd if=c08_mbr.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=1 conv=notrunc
	app_lba_start equ 100

SECTION mbr align=16 vstart=0x7c00
	; cs:0x0000
	; ds:0x0000
	; ss:0x0000
	; es:0x0000

	; 设置堆栈段和栈指针
	mov ax,0
	mov ss,ax
	mov sp,ax

	mov ax,[cs:phy_base] ; 计算用于加载用户程序的逻辑段地址
	mov dx,[cs:phy_base+0x02]
	mov bx,16
	div bx
	mov ds,ax ; 令 DS 和 ES 指向该段以进行操作
	mov es,ax
	; cs:0x0000
	; ds:0x1000
	; ss:0x0000
	; es:0x1000

	; 以下读取程序的起始部分
	xor di,di
	mov si,app_lba_start ; si（100，程序在硬盘上的起始逻辑扇区号)
	xor bx,bx ; 加载到 DS:0x0000 处
	call read_hard_disk_0

	; 以下判断整个程序有多大
	mov dx,[2] ; ds:0x1000
	mov ax,[0]
	mov bx,512
	div bx
	cmp dx,0
	jnz @1 ; 未除尽，因此结果比实际扇区数少 1
	dec ax ; 已经读了一个扇区，扇区总数减 1
@1:
	cmp ax,0 ; 考虑实际长度小于等于 512 个字节的情况
	jz direct

	; 读取剩余的扇区
	push ds ; 以下要用到并改变 DS 寄存器

	mov cx,ax ; 循环次数（剩余扇区数）
@2:
	mov ax,ds
	add ax,0x20 ; 得到下一个以 512 字节为边界的段地址
	mov ds,ax

	xor bx,bx ; 每次读时，偏移地址始终为 0x0000
	inc si ; 下一个逻辑扇区
	call read_hard_disk_0
	loop @2 ; 循环读，直到读完整个功能程序

	pop ds ; 恢复数据段基址到用户程序头部段

	; 计算入口点代码段基址
direct:
	mov dx,[0x08]
	mov ax,[0x06]
	call calc_segment_base
	mov [0x06],ax ; 回填修正后的入口点代码段基址

	; 开始处理段重定位表
	mov cx,[0x0a] ; 需要重定位的项目数量
	mov bx,0x0c ; 重定位表首地址

realloc:
	mov dx,[bx+0x02] ; 32位地址的高16位
	mov ax,[bx]
	call calc_segment_base
	mov [bx],ax ; 回填段的基址
	add bx,4 ; 下一个重定位项（每项占4个字节）
	loop realloc

	jmp far [0x04] ; 转移到用户程序

;------------------------------------------------------
read_hard_disk_0: ; 从硬盘读取一个逻辑扇区
					; 输入：DI:SI=起始逻辑扇区号
					;		DS:BX=目标缓冲区地址
	push ax
	push bx
	push cx
	push dx

	mov dx,0x1f2
	mov al,1
	out dx,al ; 读取的扇区数

	inc dx ; 0x1f3
	mov ax,si
	out dx,al ; LBA地址 7~0

	inc dx ; 0x1f4
	mov al,ah
	out dx,al ; LBA地址 15~8

	inc dx ; 0x1f5
	mov ax,di
	out dx,al ; LBA地址 23~16

	inc dx ; 0x1f6
	mov al,0xe0 ; LBA28模式，主盘
	or al,ah ; LBA地址27~24
	out dx,al

	inc dx ; 0x1f7
	mov al,0x20 ; 读命令
	out dx,al

.waits:
	in al,dx
	and al,0x88
	cmp al,0x08
	jnz .waits ; 不忙，且硬盘已准备好数据传输

	mov cx,256 ; 总共要读取的字数
	mov dx,0x1f0
.readw:
	in ax,dx
	mov [bx],ax
	add bx,2
	loop .readw

	pop dx
	pop cx
	pop bx
	pop ax

	ret

;----------------------------------------------------------
calc_segment_base: ; 计算 16 位段地址
					; 输入：DX:AX=32位物理地址
					; 返回：AX=16位段基地址
	push dx

	add ax,[cs:phy_base]
	adc dx,[cs:phy_base+0x02]
	shr ax,4
	ror dx,4
	and dx,0xf000
	or ax,dx

	pop dx
	ret
;----------------------------------------------------------
	; phy_base 标号地址是相当于段头 vstart=0x7c00 来计算的
	phy_base dd 0x10000 ; 用户程序被加载的物理起始地址

times 510-($-$$) db 0
				 db 0x55,0xaa
