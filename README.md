# X86 汇编语言 —— 从实模式到保护模式
## 相关书籍
1. 《穿越计算机的迷雾》
2. [《x86 PC汇编语言、设计与接口（第五版）》](https://www.phei.com.cn/module/goods/wssd_content.jsp?bookid=21715)

## 本书环境
1. NASM 汇编语言编译器
2. VirtualBox 虚拟机软件
3. 16/32/64 位软件代码示例
4. 虚拟 8086 模式（该模式是为了兼容传统的 8086 程序，目前已经过时，本书不予以介绍）、16 位实模式、32 位保护模式
5. 不借助于 BIOS、DOS、Windows、Linux 或任何其他软件支持的情况下，直接使用汇编语言控制硬件：显示字符、读取硬盘数据、控制其他硬件
6. 完全抛弃 BIOS 中断和 DOS 中断，直接访问硬件
7. 使用 nasm 汇编器汇编后的机器代码，除了处理器能够识别的机器代码外，别的任何东西都不包含。这样一来，因为缺少操作系统所需要的加载和重定位信息，它就很难在 Windows、DOS 和 Linux 上作为一个普通的应用程序运行

## 基础背景
### CPU
1. 在处理器众多引脚中，有一个是 RESET，用于接受复位信号。每当处理器加电，或者 RESET 引脚的电平由低到高时，处理器都会执行一个硬件初始化，以及一个可选的内部自测试（Build-in Self-Test，BIST），然后将内部所有寄存器内容初始化到一个预置的状态。
2. 对于 Intel 8086 来说，复位将使代码段寄存器（CS）的内容为 0xFFFF，其他所有寄存器的内容都为 0x0000，包括指令指针寄存器（IP）。8086 之后的处理器并未延续这种设计。
3. Intel 8086 有 20 根地址线，可以访问 1MB 的内存空间，地址范围为 0x00000 到 0xFFFFF。出于各方面的考虑，计算机系统的设计者将这 1MB 的内存空间从物理上分为几个部分。
    - 0x00000 - 0x9FFFF，640 KB，分配给了物理内存 DRAM；
    - 0xA0000 - 0xEFFFF，320 KB，分配给了其他外围设备；
    - 0xF0000 - 0xFFFFF，64 KB，分配给了只读存储器 ROM；
4. 8086 加电或复位时，CS=0xFFFF，IP=0x0000，所以，它取的第一条指令位于物理地址 0xFFFF0，正好位于 ROM 中，那里固化了开机时需要执行的指令。处理器取指令的自然顺序是从内存的低地址往高地址推荐。从 0xFFFF0 开始执行，这个位置离 1MB 内存的顶端（物理地址 0xFFFFF）只有 16 个字节的长度，一旦 IP 寄存器的值超过 0x000F，比如 IP=0x0011，那么，它与 CS 一起形成的物理地址将因为溢出而变成 0x00001，这将绕到 1MB 内存的最低端。所以，ROM 中位于物理地址 0xFFFF0 的地方，通常是一个跳转指令，它通过改变 CS 和 IP 的内容，使处理器从 ROM 中的较低位置处开始取指令执行。
5. 这块 ROM 芯片中的内容包括很多部分，主要是进行硬件的诊断、检测和初始化。所谓初始化，就是让硬件处于一个正常的、默认的工作状态。最后，它还负责提供一套软件例程，让人们在不必了解硬件细节的情况下从外围设备（比如键盘）获取输入数据，或者向外围设备（比如显示器）输出数据。设备当然是很多的，所以这块 ROM 芯片只针对那些最基本的、对于使用计算机而言最重要的设备，而它所提供的软件例程，也只包含最基本、最常规的功能。正因为如此，这块芯片又叫基本输入输出系统（Base Imput & Output System，BIOS）ROM。
6. ROM-BIOS 的容量是有限的，当它完成自己的使命后，最后所要做的，就是从辅助存储设备读取指令数据，然后转到那里开始执行。基本上，这相当于接力赛中的交接棒。

### 软盘 Floppy Disk
### 硬盘 Hard Disk, HDD
1. （盘片）硬盘可以只有一个盘片（这称为单碟)，也可能有好几个盘片。但无论如何，它们都串在同一个轴上，由电动机带动着一起高速旋转。
2. （盘面 & 磁头）每个盘片都有两个磁头（Head)，上面一个，下面一个，所以经常用磁头来指代盘面。磁头都有编号，第 1 个盘片，上面的磁头编号为 0，下面的磁头编号为 1；第 2 个盘片，上面的磁头编号为 2，下面的磁头编号为 3，以此类推。
3. 每个磁头不是单独移动的。相反，它们都通过磁头臂固定在同一个支架上，由步进电动机带动着一起在盘片的中心和边缘之间来回移动。也就是说，它们是同进退的。步进电动机由脉冲驱动，每次可以旋转一个固定的角度，即可以步进一次。
4. （磁道）可以想象，当盘片高速旋转时，磁头每步进一次，都会从它所在的位置开始，绕着圆心“画”出一个看不见的圆圈，这就是磁道（Track)。磁道是数据记录的轨迹。
5. （柱面）因为所有磁头都是联动的，故每个盘面上的同一条磁道又可以形成一不虚拟的圆柱，称为柱面（Cyinder）。磁道，或者耗面，也要编号、编号是从盘面最边缘的那条磁道开始，向着圆心的方向，从 0 开始编号。柱面是一个用来优化数据读写的概念。初看起来，用硬盘来记录数据时，应该先将一个盘面填满后，再填写另一个盘面。实际上，移动磁头是一个机械动作，看似很快，但对处理器来说，却很漫长，这就是寻道时间。为了加速数据在硬盘上的读写，最好的办法就是尽量不移动磁头。这样，当 0 面的磁道不足以容纳要写入的数据时，应当把剩余的部分写在 1 面的同一磁道上。如果还写不下，那就继续把剩余的部分写在 2 面的同一磁道上。换句话说，在硬盘上，数据的访问是以柱面来组织的。
6. （扇区）实际上，磁道还不是硬盘数据读写的最小单位，磁道还要进一步划分为扇区（Sector)。磁道很窄，也着不见，但在想象中，它仍呈带状，占有一定的宽度。将它划分许多分段之后，每一部分都呈扇形，这就是扇区的由来。每条磁道能够划分为几个扇区，取决于磁盘的制造者，但通常为 63 个。而且，每个扇区都有一个编号，与磁头和磁道不同，扇区的编号是从 1 开始的。
7. 扇区与扇区之间以间隙（空白）间隔开来，每个扇区以扇区头开始，然后是 512 个字节的数据区。扇区头包含了每个扇区自己的信息，主要有本扇区的磁道号、磁头号和扇区号，用来供硬盘定位机构使用。现代的硬盘还会在扇区头部包括一个指示扇区是否健康的标志，以及用来替换该扇区的扇区地址。用于替换扇区的，是一些保留和隐藏的磁道。
8. （主引导扇区）前面说到，当 ROM-BIOS 完成自己的使命之前，最后要做的一件事是从外存储设备读取更多的指令来交给处理器执行。现实的情况是，绝大多数时候，对于 ROM-BIOS 来说，硬盘都是首选的外存储设备。硬盘的第一个扇区是 0 面 0 道 1 扇区，或者说是 0 头 0 柱 1 扇区，这个扇区称为主引导扇区。如果计算机的设置是从硬盘启动，那么，ROM-BIOS 将读取硬盘主引导扇区的内容，将它加载到内存地址 0x0000:0x7c00 处（也就是物理地址 0x07C00)，然后用一个 jmp 指令跳到那里接着执行：`jmp 0x0000:0x7c00`。
9. （启动区）启动区一定在第一扇区，但第一扇区并不一定是启动区。只要硬盘中的 0 盘 0 道 1 扇区（第一扇区）的 512 个字节的最后两个字节分别是 0x55 和 0xaa，那么 BIOS 就会认为它是个启动区。

## 出版社
1. 书籍主页1：https://www.phei.com.cn/module/goods/wssd_content.jsp?bookid=58930
2. 书籍主页2：https://www.phei.com.cn/module/goods/wssd_content.jsp?bookid=34945 （有两个主页，定价也不一样，应该是个 bug）
3. 随书配套资源：https://www.hxedu.com.cn/hxedu/hg/book/bookInfo.html?code=TP187990

## 作者联系方式
1. Email：leechung@126.com
2. Blog: http://blog.163.com/leechung@126


## 学习记录
第 3 章 汇编语言和汇编软件
