; nasm -f bin c09_9-3_2.asm -l c09_9-3_2.lst -o c09_9-3_2.bin
; dd if=c09_9-3_2.bin of='/Users/clearbug/VirtualBox VMs/LEARN-ASM/LEARN-ASM.vhd' bs=512 count=2 oseek=100 conv=notrunc
         ;代码清单9-1
         ;文件名：c09_9-3_2.asm
         ;文件说明：用户程序 
         ;创建日期：2011-4-16 22:03
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code.start   ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;段重定位表项个数[0x0a]
    
    realloc_begin:
    ;段重定位表           
    code_segment    dd section.code.start   ;[0x0c]
    data_segment    dd section.data.start   ;[0x14]
    stack_segment   dd section.stack.start  ;[0x1c]
    
header_end:                
    
;===============================================================================
SECTION code align=16 vstart=0           ;定义代码段（16字节对齐） 
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es
      
                                         ;是不必要的 
      xor al,al
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(秒)
      push ax

      mov al,2
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(分)
      push ax

      mov al,4
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(时)
      push ax

      mov al,0x0c                        ;寄存器C的索引。且开放NMI 
      out 0x70,al
      in al,0x71                         ;读一下RTC的寄存器C，否则只发生一次中断
                                         ;此处不考虑闹钟和周期性中断的情况 
      mov ax,0xb800
      mov es,ax

      pop ax
      call bcd_to_ascii
      mov bx,12*160 + 36*2               ;从屏幕上的12行36列开始显示

      mov [es:bx],ah
      mov [es:bx+2],al                   ;显示两位小时数字

      mov al,':'
      mov [es:bx+4],al                   ;显示分隔符':'
      not byte [es:bx+5]                 ;反转显示属性 

      pop ax
      call bcd_to_ascii
      mov [es:bx+6],ah
      mov [es:bx+8],al                   ;显示两位分钟数字

      mov al,':'
      mov [es:bx+10],al                  ;显示分隔符':'
      not byte [es:bx+11]                ;反转显示属性

      pop ax
      call bcd_to_ascii
      mov [es:bx+12],ah
      mov [es:bx+14],al                  ;显示两位小时数字
      
; 在 8259 芯片内部，有一个中断服务寄存器（Ihnternupt Servie Register， ISR），这是一个 8 位寄存器，每一位都对应着一个中断输入引脚。
; 当中断处理过程开始时，8259 芯片会将相应的位置 1，表明正在服务从该引脚来的中断。
; 一旦响应了中断。8259 中断控制器无法知道该中断什么时候才能处理结束。同时，如果不清除相应的位，下次从同一个引脚出现的中断将得不到处理。
; 在这种情况下，需要程序在中断处理过程的结尾，显式地对 8259 芯片编程来清除该标志，方法是向 8259 芯片发送中断结束命令（End Of Interrupt, EOI)。中断结束命令的代码是 0x20。
;代码清单 9-1 第 92~94 行就用来做这件事。
; 需要注意的是，如果外部中断是 8259 主片处理的，那么，EOI 命令仅发送给主片即可，端口号是 0x20；
; 如果外部中断是由从片处理的。就像本章的例子，那么，EOI 命令既要发往从片（端口号(0xa0)），也要发往主片。
; 最后，第 96～102 行，从栈中恢复被中断程序的现场，并用中断返回指令 iret 回到中断之前的地方继续执行。iret 的意思是 Internupt Return。
      mov al,0x20                        ;中断结束命令EOI 
      out 0xa0,al                        ;向从片发送 
      out 0x20,al                        ;向主片发送 

      pop es
      pop dx
      pop cx
      pop bx
      pop ax

      iret

;-------------------------------------------------------------------------------
bcd_to_ascii:                            ;BCD码转ASCII
                                         ;输入：AL=bcd码
                                         ;输出：AX=ascii
      mov ah,al                          ;分拆成两个数字 
      and al,0x0f                        ;仅保留低4位 
      add al,0x30                        ;转换成ASCII 

      shr ah,4                           ;逻辑右移4位 
      and ah,0x0f                        
      add ah,0x30

      ret

;-------------------------------------------------------------------------------
start:
; 将数据段寄存器置为本程序自身的数据段
; 将栈段寄存器置为本程序自身的栈段
; 将栈指针寄存器置为栈段顶部
      mov ax,[stack_segment]
; 当处理器执行任何一条改变栈段寄存器 SS 的指令时，它会在下一条指令执行完期间禁止中断。
; 栈无疑是很重要的，不能被破坏。要想改变代码段和数据段，只需要改变段寄存器就可以了。
; 但栈段不同，因为它除了有段寄存器，还有栈指针。因此，绝大多数时候，对栈的改变是分两步进行的：先改变段寄存器 SS 的内容，接着又修改栈指针寄存器 SP 的内容。
; 想象一下，如果刚刚修改了段寄存器 SS，在还没来得及修改 SP 的情况下，就发生了中断，会出现什么后果，而且要知道，中断是需要依靠栈来工作的。
      mov ss,ax
      mov sp,ss_pointer
      mov ax,[data_segment]
      mov ds,ax
      
      mov bx,init_msg                    ;显示初始信息 
      call put_string

      mov bx,inst_msg                    ;显示安装信息 
      call put_string

; RTC 芯片的中断信号，通向中断控制器 8259 从片的第 1 个中断引脚 IR0。
; 在计算机启动期间，BIOS 会初始化中断控制器，将主片的中断号设为从 0x08 开始，将从片的中断号设为从 0x70 开始。
; 所以，计算机启动后，RTC 芯片的中断号默认是 0x70。

; 计算 0x70 号中断在中断向量表中的位置，并将该位置放入 bx 寄存器中
      mov al,0x70
      mov bl,4
      mul bl                             ;计算0x70号中断在IVT中的偏移
      mov bx,ax                          

      cli                                ;防止改动期间发生新的0x70号中断

; 将本程序写的 0x70 号中断处理程序所在的段地址和偏移地址写入中断向量表中
      push es
      mov ax,0x0000
      mov es,ax
      mov word [es:bx],new_int_0x70      ;偏移地址。
                                          
      mov word [es:bx+2],cs              ;段地址
      pop es

; 对于 CMOS RAM 的访问，需要通过两个端口来进行。0x70 或者 0x74 是索引端口，用来指定 CMOS RAM 内的单元；0x71 或者 0x75 是数据端口，用来读写相应单元里的内容。

; 设置 RTC 寄存器A：先读出寄存器A的当前值，修改之，再设置回去
	mov al,0x0a
	or al,0x80
	out 0x70,al
	in al,0x71
	and al,0xf0
	or al,0x0e
	out 0x71,al

; 设置 RTC 寄存器B
      mov al,0x0b                        ;RTC寄存器B
      or al,0x80                         ;阻断NMI 
      out 0x70,al
      mov al,0x42                        ;设置寄存器B，开放周期性中断，禁止更 
      out 0x71,al                        ;新结束后中断，BCD码，24小时制 

; 每次当中断实际发生时，可以在程序（中断处理过程）中读寄存器 C 的内容来检查中断的原因。
; 比如，每当更新周期结束中断发生时，RTC 就将它的第 4 位置 1.
; 该寄存器还有个特点，就是每次读取它后，所有内容自动清零。而且，如果不读取它的话（换句话说，相应的位没有清零），同样的中断将不再产生。

; 这里读一下寄存器 C 的内容，使之开始产生中断信号。并且，向索引端口 0x70 写入的同时，也打开了 NMI。毕竟，这是最后一次在主程序中访问 RTC。
      mov al,0x0c
      out 0x70,al
      in al,0x71                         ;读RTC寄存器C，复位未决的中断状态

; RTC 芯片设置完毕后，再来打通它到 8259 的最后一道屏障。正常情况下，8259 是不会允许 RTC 中断的，所以，需要修改它内部的中断屏蔽寄存器 IMR。
; IMR 是一个 8 位寄存器，位 0 对应着中断输入引脚 IR0，位 7 对应着中断输入引脚 IR7，相应的位是 0 时，允许中断，为 1 时，关掉中断。
; 8259 芯片是我见过的芯片中，访问起来最麻烦，也是我最讨厌的一个。好在有关它的资料非常好找，这里就简单地进行讲解。
; 通过端口 0xa1 读取 8259 从片的 IRM 寄存器，用 and 指令清除第 0 位，其他各位保持原状，然后再写回去。于是，RTC 的中断可以被 8259 处理了。
      in al,0xa1                         ;读8259从片的IMR寄存器 
      and al,0xfe                        ;清除bit 0(此位连接RTC)
      out 0xa1,al                        ;写回此寄存器 

; sti 指令将标志寄存器的 IF 位置 1，开放设备中断。
      sti                                ;重新开放中断 

      mov bx,done_msg                    ;显示安装完成信息 
      call put_string

      mov bx,tips_msg                    ;显示提示信息
      call put_string
      
      mov cx,0xb800
      mov ds,cx
      mov byte [12*160 + 33*2],'@'       ;屏幕第 12 行，33 列
       
 .idle:
      hlt                                ;使CPU进入低功耗状态，直到用中断唤醒
      not byte [12*160 + 33*2+1]         ;反转显示属性 
      jmp .idle

;-------------------------------------------------------------------------------
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
         mov cl,[bx]
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;是的，返回主程序 
         call put_char
         inc bx                          ;下一个字符 
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符
                                         ;输入：cl=字符ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ; 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al

         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;===============================================================================
SECTION data align=16 vstart=0

    init_msg       db 'Starting...',0x0d,0x0a,0
                   
    inst_msg       db 'Installing a new interrupt 70H...',0
    
    done_msg       db 'Done.',0x0d,0x0a,0

    tips_msg       db 'Clock is now working.',0
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end:
