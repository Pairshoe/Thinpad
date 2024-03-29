<font face="宋体">

# <center>计算机组成原理 流水线实验 报告</center>

<center>罗富文  计91  2019011409 &nbsp; 刘家宏  计94  2019011297 &nbsp; 王拓为  计94  2018011917</center>

<br><br>

## 1. 实验目标

 - 深入理解流水线结构计算机指令的执行方式，掌握流水处理器的基本设计方法。
 - 深入理解计算机的各部件组成及内部工作原理，掌握计算机外部输入输出的设计。
 - 加深对于 RISCV-32I 指令集的理解。
 - 提高硬件设计和调试的能力。

## 2. 实验内容

### 2.1. 流水线

本次实验中，流水线共分为 5 个阶段，分别为 IF 取指、 ID 译码、 EXE 执行、 MEM 访存和 WB 写回，每条指令依次经过 5 个阶段完成执行。在流水线不断流的情况下，同时有 5 条指令被执行。

#### 2.1.1. 指令在不同阶段之间的传递

指令在不同阶段之间的传递主要通过阶段寄存器进行。每两个阶段之间均存在若干阶段寄存器，用于记录上一个阶段的运算结果中对本阶段及以后的阶段有用的数据。一个阶段在执行时，从其与上一阶段之间的阶段寄存器读取数据并执行操作，并将需要传递给下一阶段的结果写入其与下一阶段之间的阶段寄存器。

在本次实验中，我们组采用计数器和 `done` 信号相结合的方式控制指令的传递。为了处理流水线冲突和生成各种控制信号，每一阶段的第 0 周期均不执行任何计算操作，该周期保留给 controller 使用。除此以外， ID 和 EXE 阶段由纯组合逻辑实现，需 1 个周期完成； WB 阶段有写寄存器操作，需要 2 个周期完成； IF 和 MEM 阶段需要访存，由于页表、 TLB 、 Cache 等机制的存在，其执行周期数不固定。另外，为了编程方便，我们选择等待所有阶段执行完毕后统一进行指令的传递。综上所述，我们在流水线中引入了计数器 `counter` ，每一阶段开始时将其置 0 ，每经过 1 周期其计数增加 1 ；另外，我们在 SRAM 模块增加 `done` 信号。当流水线识别到计数器的值大于 2 且 `done` 信号值为 1 时，其传递指令并开启下一阶段的执行。

#### 2.1.2. 气泡的插入与指令的废除

为了方便处理流水线冲突，我们设置了一个特别的阶段寄存器 `abort` ，并为每一阶段设置了暂停信号 `stall` 。 `abort` 寄存器记录该指令是否被废除，当其值为 1 时，该阶段不进行任何操作（相当于执行 `nop` 指令）。 `stall` 信号用于暂停某几个阶段的执行，受流水线结构特点的限制，被暂停的阶段必须是连续的且 IF 阶段必须被包括在内。

插入气泡时， `stall` 信号为 1 的阶段均不执行操作，系统在最后一个被暂停的阶段与第一个未被暂停的阶段之间插入一条指令，其 `abort` 寄存器的值为 1 ；废除指令时，只需将需要废除的指令对应的 `abort` 寄存器的值置为 1 即可。

### 2.2. 流水线冲突处理

对流水线冲突的处理工作主要由 controller 完成，其在每个阶段的第 0 周期生成信号对流水线进行控制。

#### 2.2.1. 控制冲突处理：动态分支预测

流水线执行过程中遇到 B 型指令或 J 型指令时可能发生跳转，但执行跳转操作时该指令已完成 EXE 阶段，此时处于 IF 和 ID 阶段的指令不应被执行，这就产生了控制冲突。

我们采用动态分支预测的方法解决冲突。我们采用 32 项预测表，用直接映射的方法读写表项。需要注意的是，本次实验中采用 32 位地址，指令地址是 4 字节对齐的，所以我们用地址的第 2 - 6 位而不是 0 - 4 位进行映射。当发生跳转时，预测表中会记录跳转指令的地址和跳转目的地址，下次执行至该位置时即预测跳转， IF 阶段结束后把 pc 指针设置为目的地址；当预测跳转失败时，从表中删除该项。

需要注意的是，当预测跳转失败或未成功预测跳转时，需要把位于 IF 和 ID 阶段的指令废除，将其 `abort` 寄存器的值置为 1 。

#### 2.2.2. 数据冲突处理：数据旁路

在本实验中，仅存在 Read After Write 型数据冲突，即需要从寄存器中读出的值在 ID 阶段尚未写入寄存器。对此，需要分如下几种情况处理。

 - 若写寄存器的指令类型为 LOAD ，则无法进行数据前传。这种情况下冲突的解决方法为暂停 IF 和 ID 阶段流水线的运行直至该指令访存完毕；
 - 若写寄存器的指令位于 EXE 阶段，则将 EXE 阶段的计算结果前传至 ID 阶段；
 - 若写寄存器的指令位于 MEM 阶段，则将 MEM 阶段对应阶段寄存器的值前传至 ID 阶段。

需要注意的是，数据冲突优先级低于控制冲突，若发生控制冲突则无需处理数据冲突。

#### 2.2.3. 结构冲突处理

结构冲突指 IF 和 MEM 阶段需要同时访存而导致冲突。此时只需暂停 IF 阶段流水线的运行直至 MEM 阶段访存完毕即可。

### 2.3. SRAM 与 UART

SRAM 与 UART 的功能由同一模块完成。该模块中还集成了 Cache 、页表和 TLB 等功能。其中页表和 TLB 将在 2.5 节作详细说明。

#### 2.3.1. SRAM 与 UART 时序

SRAM 和 UART 由一个状态机控制，状态机各状态如下所示。

 - IDLE ：闲置状态。当不对 SRAM 或 UART 进行读写时，状态机处于该状态。每个时钟周期上升沿到来时，该模块检测 oe 或 we 信号是否为高电平。若信号为高电平则根据 oe / we 信号和地址 address 进入 SRAM_READ 、 SRAM_WRITE 、 UART_READ 、 UART_WRITE 等状态。需要注意的是，对于 UART 读写状态位等 MMIO ，其值由寄存器而不是 SRAM 保存，因此无需进入上述状态而直接进入 FINISHED 状态。
 - SRAM_READ ：读内存状态。把 base_ram_oe_n 或 ext_ram_oe_n 拉低并从内存中读数。
 - SRAM_WRITE ：写内存状态。把 base_ram_we_n 或 ext_ram_we_n 拉低并向内存中写数。
 - UART_READ ：读串口状态。把 uart_rdn 拉低并读取数据。需要注意的是，若读取数据前 dataready 不为 1 则不能读出正确的数据。
 - UART_WRITE ：写串口状态。把 uart_wrn 拉低并向串口写数据。
 - FINISHED ：完成状态。拉高所有控制信号并输出 done 信号。

#### 2.3.2. UART 读写状态位的控制

对于 UART 读状态位，当 dataready 信号为高电平且 SRAM 模块处于闲置状态时即可将其置 1 。

对于 UART 写状态位，需要在向 UART 写入数据后等待 tbre 信号变为高电平，然后再等待 tsre 信号变为高电平后放可将其置 1 。为此，需要一个单独的状态机对写状态位进行控制。

#### 2.3.3. Cache

在本次实验中我们的 Cache 表共 32 项，由寄存器实现，每项中记录了数据的物理地址和 4 字节的数据。 Cache 采用直接映射的方式设计，由于每项共 4 字节数据，所以我们用地址的第 2 - 6 位而不是 0 - 4 位进行映射。读写 Cache 的具体过程如下。

 - 读 Cache ：当 SRAM 模块主状态机为 IDLE 状态且检测到 oe 信号为高电平时，尝试将地址 address 与 Cache 表中对应项的地址进行比对，若表项有效且地址相同则直接输出对应的值，进入 FINISHED 状态，否则进入 SRAM_READ 或 UART_READ 状态。
 - Cache 表项更新：当 SRAM 模块主状态机为 SRAM_READ 状态时，说明发生了 Cache Miss 且正在从内存中读取数据。此时根据地址 address 和读取的数据值对表项进行覆盖即可。
 - 数据写入：采用 Write Through 模式。当 SRAM 模块主状态机为 IDLE 状态且检测到 we 信号为高电平时，尝试将地址 address 与 Cache 表中对应项的地址进行比对，若地址相同则对表项进行覆盖，同时进入 SRAM_WRITE 状态；否则无需更新 Cache 表，直接进入 SRAM_WRITE 或 UART_WRITE 状态。

### 2.4. 中断与异常

中断和异常部分主要有以下任务：1.解析一些特权指令；2.实现csr寄存器和mmio寄存器的读写；3.根据指令和寄存器的实现相应修改数据通路；4.根据监控程序的需求在流水线中处理中断和异常。主要涉及的文件有：`alu.h`，`alu.vh`，`csr_index.vh`，`csr_regfile.v`，`decoder.v`，`exception_interrupt.vh`，`pipeline.v`，`sram.v`。

需要解析的指令包括CSRRC、CSRRS、CSRRW、EBREAK、ECALL、MRET、SLTU。SLTU为常规指令，EBREAK、ECALL、MRET只需要让流水线得知即可，不需要特殊处理，这四条指令只需要修改decoder。CSRR系列指令比较麻烦，同时涉及到普通寄存器和csr寄存器的读写及运算。为此在流水线中增加控制信号，将普通寄存器和csr寄存器值都输入alu运算，并**另开一条通路用于csr寄存器写入**，此外还要将其**并入数据旁路**。

csr寄存器存储在`csr_regfile.v`中。这一部分实际上只实现了mtvec、mscratch、mepc、mcause、mstatus、mie、mip、mtval这8个寄存器。设置两种读写方式：普通读写和专用读写。普通读写是通过**csr寄存器索引值**来读写，若索引值有效（是实现的8个寄存器之一）则读写有效，若索引值无效则读为0、写弃置。专用读写将实现的8个寄存器**分别接线**到流水线中，方便流水线对中断和异常的处理。同时，区分普通和专用也是考虑到CSRR系列指令对csr寄存器的读写和中断异常处理对csr寄存器的读写**可能的冲突**。为了保存当前所在的特权状态（U/M/S），增加一个**mode寄存器**，通过专用读写线连到流水线中。

mmio寄存器并入`sram.v` 处理，在mem阶段读写，**类似于对串口状态位的处理**，特判地址即可。mtime的更新也在`sram.v`中完成，在用户态下默认每两个时钟周期加一。

监控程序需要实现的异常有：U态ecall、U态ebreak；需要实现的中断只有时钟中断。时钟中断的**优先级最高**，由`sram.v`内部进行超时的检测，向流水线发出**超时信号**。流水线检测到超时后立即暂停流水线，跳转到异常处理地址，并设置mcause、mstatus、mepc和mode。由于监控程序在检测到M态时钟中断后会直接返回，故默认只有U态才会发生时钟中断。ecall和ebreak在**id阶段的一开始**就可以检测到并开始处理，同样是暂停流水线、跳转、设置csr寄存器和mode。mret与ecall和ebreak同级检测，区别只是mret跳转到mepc对应的地址，以及寄存器写入的值不同而已。

### 2.5. 页表与 TLB 

#### 2.5.1. 页表

在实现中断异常处理的基础上，可以进一步实现页表支持，完成用户态的地址映射。

我们小组实现的是 RV32 指令，对应于 Sv32 的页表格式，监控程序中给出了 SV32 的映射方式，出于简化的目的实际映射都为线性映射。在 RV32 下，页表的页面大小（$PAGESIZE$）为 $2^{12}$ Byte，页表的级数为 2，页表的表项大小（$PTESIZE$）为 4 Byte。

页表支持本质上是地址翻译的过程，将用户态的虚拟地址翻译为实际的物理地址，主要需要执行以下几个步骤：

（1）计算一级页表对应表项的地址，其地址可以通过寄存器 `satp` 中的 PPN 部分和虚拟地址的 VPN[1] 部分计算得到，具体的计算方法为：
$$
ADDRESS=satp.ppn\times PAGESIZE+va.vpn[1]\times PTESIZE
$$
（2）得到一级页表对应表项的地址后，首先对表项进行检查。如果其 V 位为 0 或者 其 R 位为 0 且 W 位为 1，则停止转换，产生 PageFault 的报错。

（3）检查无误后，计算二级页表对应表项的地址，其地址可以通过一级页表表项的 PPN 部分和虚拟地址的 VPN[0] 部分得到，具体的计算方法为：
$$
ADDRESS=pte.ppn\times PAGESIZE+va.vpn[0]\times PTESIZE
$$
（4）得到二级页表对应表项的地址后，首先对表项进行检查。如果其 V 位为 0 或者 其 R 位为 0 且 W 位为 1，则停止转换，产生 PageFault 的报错。如果其 R 位、W 位、X 位、U 位和发起的内存访问请求不符，则停止转换，产生 PageFault 报错。

（5）检查无误后，计算实际的物理地址，其地址可以通过二级页表表项的 PPN 部分和虚拟地址的 OFFSET 部分得到，具体的计算方法为：
$$
ADDRESS=pte.ppn\times PAGESIZE+va.offset
$$
（6）由此可以根据得到实际物理地址对内存进行访问。

在实现中，主要的改动位于 SRAM 部分，由于需要进行页表转换，需要在原有的 IDLE 状态和 SRAM_WRITE 或 SRAM_READ 状态之间加入新的状态，主要分为以下几点：

（1）在 IDLE 状态，增加对于是否开启页表的判断，判断的依据是：寄存器 `satp` 的最高位是否为 1 同时当前状态是否为用户态。如果是，则根据写/读进入对应的页表转换状态 SRAM_WRITE_PAGE_0/SRAM_READ_PAGE_0，在进入前给出一级页表的地址，同时拉低 base_ram_oe_n，并将数据线设置为高阻；如果不是，则直接进入常规写/读状态 SRAM_WRITE/SRAM_READ。

（2）在 SRAM_WRITE_PAGE_0/SRAM_READ_PAGE_0 状态，根据得到的一级页表对应表项数据计算二级页表地址，进入 SRAM_WRITE_PAGE_1/SRAM_READ_PAGE_1 状态。

（3）在 SRAM_WRITE_PAGE_1/SRAM_READ_PAGE_1 状态，根据得到的二级页表对应表项数据计算实际物理地址，进入 SRAM_WRITE_PAGE_2/SRAM_READ_PAGE_2 状态。

（4）在 SRAM_WRITE_PAGE_2/SRAM_READ_PAGE_2 状态，将 base_ram_oe_n 拉高，根据所得物理地址对应 BaseRam 还是 ExtRam 改变对应的读写控制信号，进入常规写/读状态 SRAM_WRITE/SRAM_READ。

值得一提的是，在上述状态转换中，利用了 SRAM 读时序中保持使能信号持续拉低，只需更改地址则可以实现不同地址上数据的读取这一特性。

#### 2.5.2. TLB

通过上面的过程我们可以看到，页表的转换十分繁琐，增加了 2 次从 SRAM 中读取数据的操作。为了减小这种开销，我们可以利用缓存相关的思想，使用 TLB 存储虚拟寻址，实现地址映射的加速。

在我们的实现中，TLB 主要有以下 3 个部分组成：有效位、虚拟地址和物理地址。其中，有效位表示该项 TLB 是否有效，虚拟地址和物理地址形成了一种一一对应的关系。

在查询真正的页表之前，查询 TLB 中是否有对应的物理地址，如果有则直接从中取出进入常规的内存读写；

在查询真正的页表之后，检查 TLB 中是否有无效的表项，如果有则将新的虚拟地址和物理地址写入其中。

我们还实现了新的指令 `sfence.vma`，通过更改 TLB 对应的有效位，控制 TLB 刷新。

值得一提的是，由于一项 TLB 即可覆盖 4KB 的地址映射，因此我们只实现了 4 项 TLB 便收获不错的效果。

### 2.6. VGA

VGA部分主要有以下任务：1.控制vga的输出显示；2.使用bram作为显存完成实时读写；3.实现拓展功能的逻辑。主要涉及的文件有：`vga.v`，`bram.v`。

vga的基本控制逻辑已经在示例代码中给出，需要完成的实际上是在**输入横坐标hdata和纵坐标vdata时，输出确定的颜色组合**（video_red、video_green、video_blue）。为此，开出模块`vga.v`和`bram.v`，在`vga.v`中输出hdata和vdata并输入到`bram.v`，在`bram.v`中使用组合逻辑输出颜色值。

显存使用bram而非sram，一方面是因为bram读写效率更高，另一方面是防止内存数据冲突。实验用的FPGA板上提供了多种可直接实例化的bram，`bram.v`中使用**xpm_memory_tdpram**，它有**两个独立的读写端口**。在实现中，**B端口只使用读功能**，通过特定的组合逻辑将输出的**横纵坐标映射为读取的地址**，将读出的数据输出，这便实时给出了vga显示需要的数据。**A端口可读可写**，用于拓展功能的逻辑实现。由于一个颜色组合恰好可用8位来唯一确定，故bram的**数据位宽就设置为8位**，另外地址位宽设置为14位可以保证拓展功能的空间足够。

**扩展功能1是寄存器值显示**。即通过拨码开关显示当前32个寄存器中任意一个寄存器的值。首先，获取0到f的点阵字体，将其存入到数据文件中并作为bram的MEMORY_INIT_FILE，这样**点阵数据就存到了bram中**。其次，通过在将寄存器值和拨码开关的数据接入到bram中，再将B端口的**读取地址映射到对应的点阵字体**，这样就实现了显示。

**扩展功能2是可控制的康威生命游戏**。康威生命游戏是一个基于离散方格图的状态机，它下一时刻的状态仅由当前时刻状态决定。最终版本可以用特定程序和拨码开关控制一个16*16大小的生命游戏的启动与暂停，同时可以用拨码开关控制在其中任意一个位置进行死、活细胞状态的修改。生命游戏的介绍可参考[Conway's Game of Life - LifeWiki (conwaylife.com)](https://www.conwaylife.com/wiki/Conway's_Game_of_Life)。

实现该功能的基本思路仍然是**外部信号的接入**和**bram特定地址的读写**。此处16*16的空间映射到bram中一段连续的地址中，读写对应的都是这一段地址。在暂停状态下，细胞状态的修改实际上就是用**A端口对由拨码开关确定的地址进行写入**。在启动状态下，每隔0.5s（25M个时钟周期），会根据生命游戏规则进行一次状态转换，这是通过**A端口一系列连续读写**实现。启动和暂停的控制是通过检测拨码开关值和cpu发来的信号值实现的。cpu的信号由**检测decoder的两个特殊指令值**确定，这样如果**将特殊的指令写成汇编程序，就可以通过执行这个程序来控制生命游戏的启动和暂停**。

## 3. 效果展示

### 3.1 基础功能及其优化

用终端连接在线平台的实验板，运行基础版本的监控程序，依次执行5个性能测试程序。在此处可以看到流水线的优化和cache的效果：

<img src="images\3.1.png" alt="3.1" style="zoom:50%;" />

同时，在线功能测试保证了基础版本执行的正确性：

<img src="images\3.2.png" alt="3.2" style="zoom: 50%;" />

### 3.2 中断和异常

再改用页表版本监控程序（含中断异常），运行以下汇编测例：

1.测试ebreak的正确性。在汇编程序的一开始就进行ebreak，程序应当立即执行完毕，如下图：

<img src="images\3.3.png" alt="3.3" style="zoom:50%;" />

2.测试ecall的正确性。汇编程序由一系列的ecall组成，最后会正常返回。最终运行表现为输出一个字符串：

<img src="images\3.4.png" alt="3.4" style="zoom:50%;" />

3.测试时钟中断。汇编程序只有一行，为一个不断原地跳转的死循环。cpu最终在0.4s后杀掉了程序，说明时钟中断表现正确：

<img src="images\3.5.png" alt="3.5" style="zoom:50%;" />

4.ecall+时钟中断。在输出字符串后进入死循环。表现出来为程序输出一段字符串之后被杀掉：

<img src="images\3.6.png" alt="3.6" style="zoom:50%;" />

### 3.3 页表和TLB

继续使用页表版本监控程序。设置一个测例：进行一系列ecall，然后正常返回。将该测例读入到不同物理地址并运行，可以确认页表映射的正确性。

1.放置到物理地址0x80100000，分别在虚拟地址0x00000000和0x80100000运行：

<img src="images\3.8.png" alt="3.8" style="zoom:50%;" />

<img src="images\3.7.png" alt="3.7" style="zoom:50%;" />

2.放置到物理地址0x803f0000，在虚拟地址0x002f0000运行：

<img src="images\3.9.png" alt="3.9" style="zoom:50%;" />

<img src="images\3.10.png" alt="3.10" style="zoom:50%;" />

3.放置到物理地址0x80400000，在虚拟地址0x7fc10000运行：

<img src="images\3.11.png" alt="3.11" style="zoom:50%;" />

<img src="images\3.12.png" alt="3.12" style="zoom:50%;" />

4.放置到物理地址0x807e0000，在虚拟地址0x7fff0000运行：

<img src="images\3.13.png" alt="3.13" style="zoom:50%;" />

<img src="images\3.14.png" alt="3.14" style="zoom:50%;" />

### 3.4 VGA及其拓展功能

如下图，左边为DVI输出，上方为寄存器值显示，下方为康威生命游戏显示。右边为命令行，读入了控制康威生命游戏启动/暂停的两个程序。

<img src="images\3.15.png" alt="3.15" style="zoom:50%;" />

通过执行两个程序及控制拨码开关，可以控制上方数字显示不同寄存器的值，及对生命游戏进行读写、启动和暂停操作，以改变其状态。

<img src="images\3.16.png" alt="3.16" style="zoom:50%;" />



## 4. 实验心得体会

由于很久之前便听到过关于贵系“奋战三星期，造台计算机”的种种传闻，在实验开始时便对即将遇到的困难有了充足的心理准备。秉承“笨鸟先飞”的精神，我们小组在正式开始造机的一周前便开始了流水线的构建工作。而这也使我们小组免去了被 DDL 追赶的苦恼，每一周的工作都在按部就班的进行，不算快速却有条不紊。

硬件和软件之间的差异令人印象深刻，一个最直接的体现在编程思想上。我们在软件编程可以将精力集中在数据结构和算法上，力求在抽象的世界中写出优雅的代码；而在硬件编程时，我们则要时刻思考硬件的底层实现，所谓的高级语言也更像是对硬件的一种描述和刻画。

但是二者之间并非没有相通之处，无论是软件还是硬件，简洁往往都意味着好。软件上的简洁之美不必多说，在硬件上简洁的电路则意味着更短的数据通路、更小的电路延迟和更稳定的运行表现。硬件编程的一大阻碍在于调试，我们无法像软件中一样打印输出或插入断点单步执行，我们所拥有的只有一个又一个信号的波形。当电路变得庞大时，信号的数量飞速增加，信号之间的逻辑关系也变得复杂，加之对于底层的硬件特性不够清楚，调试往往变得极为困难，甚至许多问题不得不归结于“玄学”。在这种情况下，一个简洁的实现就变得更加重要和珍贵。

造机本质上是对计算机袪魅的过程，我们看到无论上层世界是多么的华丽酷炫，在底层世界里都会变为一个个简单的指令，在处理器的流水线中被忠实的执行。我们意识到，上层世界本质上是基本指令的排列组合，其内核在于指导这种排列组合的方法和思想，底层世界本质上是基本指令的执行处理，其内核在于对物理硬件和指令本身的理解。为久居上层世界的同学打开一扇通往底层世界的大门，或许是造机最大的意义所在。

不管怎样，造机结束了。未来再次打开 Vivado 编程的概率或许是渺茫的，但是当遇到困难时，我们大概率会想起造机的时光：无论出现了多少红叉，要做的无非是找到第一个出现红叉的地方，一个波形一个波形的看下去！



## 5. 遇到的困难与解决方案

在本次实验中，我们遇到的最大困难为程序在通过功能仿真和后仿真的情况下无法稳定通过自动化测试。经过调试，可能是如下问题导致的。

 - 程序中出现大段组合逻辑，生成电路过于复杂，导致时延较大。
 - 程序中存在过深的 if - else 嵌套，导致时延较大。
 - 部分状态机由于某些未知原因，在后仿真时报 timing violation 错误。

为了提高程序稳定性，我们采取了如下策略。

 - 拆分或简化组合逻辑，避免过大的组合逻辑电路。
 - 削减 if - else 嵌套，必要时增加时钟周期数以保证逻辑电路的稳定运行。
 - 简化或重写状态机以避开出问题的寄存器。

经实测检验，上述方法能有效提升程序稳定性，使程序稳定通过自动化测试。虽然该问题与代码逻辑实现无关，甚至一部分造成错误的原因无法解释，但是对程序逻辑的简化确实能起到提升程序稳定性的效果。这说明硬件编程时我们需要多注意代码的简洁性，避免代码过于冗长。

## 6. 设计框图（wtw）



## 7. 数据通路图（wtw）



## 8. 思考题

### 8.1. 流水线 CPU 设计与多周期 CPU 设计的异同？插入等待周期（气泡）和数据旁路在处理数据冲突的性能上有什么差异。

流水线 CPU 与多周期 CPU 设计的相同点是均需设计 5 个 Stage ，与内存、串口等模块的交互也是类似的。不同点在于流水线 CPU 需要使用阶段寄存器传递各阶段的运算结果，且由于不同阶段同时执行，需要处理控制冲突、数据冲突、结构冲突等。

数据旁路在发生冲突的写寄存器指令非读内存或串口类型的指令时可以通过数据前传的方式在不打断流水线的情况下保证程序运行的正确性，而插入等待周期会导致流水线中断。因此，数据旁路相较插入等待周期的方法在处理数据冲突时性能更优。

### 8.2. 如何使用 Flash 作为外存，如果要求 CPU 在启动时，能够将存放在 Flash 上固定位置的监控程序读入内存，CPU 应当做什么样的改动？

（1）闪存是一种电可擦除的可编程只读存储器，可以分为 NOR Flash 和 NAND Flash 两种。NOR Flash 具有随机存取和对字节执行写操作的能力，但读和擦除操作的速度较慢，而 NAND Flash 则恰恰相反。由于在实际中支持 NAND Flash 的处理器较多，我们以 NAND Flash 为例进行说明：

NAND Flash 具有 8 或 16 位接口，通过 8 或 16 位宽的双向数据总线，主数据被连接到 NAND Flash。在16位模式下，指令和地址利用低 8 位，高 8 位仅在数据传输周期使用。

NAND Flash 的基本操作包括：复位操作、读 ID 操作、读状态操作、编程操作、随机数据输入操作和读操作。

除了 I/O 总线，NAND接口由6个主要控制信号构成：

（1）芯片启动（CE）：如果没有检测到 CE 信号，NAND Flash 将保持待机模式，不对任何控制信号作出响应。

（2）写使能（WE）：WE 负责将数据、地址或指令写入 NAND Flash 之中。

（3）读使能（RE）：RE 允许输出数据缓冲器。

（4）指令锁存使能（CLE）: 当 CLE 为高时，在 WE 信号的上升沿，指令被锁存到 NAND 指令寄存器中。

（5）地址锁存使能（ALE）：当 ALE 为高时，在 WE 信号的上升沿，地址被锁存到 NAND 地址寄存器中。

（6）就绪/忙（R/B）：如果 NAND Flash 忙，R/B 信号将变低。该信号是漏极开路，需要采用上拉电阻。

数据每次进/出 NAND Flash 都是通过 8 位或 16 位接口。当进行编程操作的时候，待编程的数据进入数据寄存器，处于在 WE 信号的上升沿。在寄存器内随机存取或移动数据，要采用专用指令以便于随机存取。

数据寄存器输出数据的方式与利用 RE 信号的方式类似，负责输出现有的数据，并增加到下一个地址。

当输出一串 WE 时钟时，通过在 I/O 位 [7:0] 上设置指令、驱动 CE 变低且 CLE 变高，就可以实现一个指令周期。

为了提供指令，处理器在数据总线上输出想要的指令，并输出地址 0010h；为了输出任意数量的地址周期，处理器仅仅要依次在处理器地址 0020h 之后输出想要的 NAND Flash 地址。

（2）一种可能的实现方法是在 Ram 中编写一段用于将 Flash 固定位置的程序加载进 Ram 中并随后跳转至加载位置的代码，将 CPU 执行指令的起始地址设置为该段代码起点，使得 CPU 在 boot 阶段执行该段代码。

### 8.3. 如何将DVI作为系统的输出设备，从而在屏幕上显示文字？

首先，需要根据DVI的参数，对应设置一个能与时钟同步的逐像素扫描控制器。它每个时钟周期输出一个确定的横纵坐标、横纵同步信号以及有效位。扫描控制器可以逐行扫描或逐列扫描。其次，对于有效的横纵坐标，需要即时（组合逻辑）确定R、G、B三种颜色的值并输出到DVI。完成这两点后，DVI就可以同步显示出图像。

如果需要显示特定的文字，首先需要设置一段显存空间，至少要求是可读的。其次，将需要使用的文字组织为点阵字体文件，连续地合并到一个文件中（一般为.mem格式），并将此文件作为显存的初始化文件，这样文字数据就保存在了显存中。在需要显示时，将扫描控制器给出的横纵坐标映射到特定的地址，读取对应的显存数据并输出。

## 9. 致谢

由于我们组在造机过程中遇到问题较多，所以经常找老师和助教答疑。在老师和助教的指导下，我们的硬件编程和调试能力有了显著的提高。感谢老师和助教对我们组问的问题的耐心解答和对我们组的悉心指导！

