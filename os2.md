/ *在First Fit算法中，分配器保留可用块的列表
 *（称为免费列表）。收到分配内存的请求后，
 *它沿列表扫描第一个块，该块足够大，可以满足
 *要求。如果所选块明显大于请求的块，则它
 *通常是分割的，其余的将作为添加到列表中
 *另一个免费块。
 *请参考阎维民中文书第8.2〜196页至第198页
 *“数据结构-C编程语言”。
* /
// LAB2练习1：您的代码
//您应该重写以下函数：default_init，default_init_memmap，
//`default_alloc_pages`，`default_free_pages`。
/ *
 * FFMA的详细信息
 *（1）准备：
 *为了实现“第一适配内存分配”（FFMA），我们应该
 *使用列表管理可用内存块。使用结构`free_area_t`
 *用于管理空闲内存块。
 *首先，您应该熟悉list.h中的结构`list`。结构
 *`list`是一个简单的双向链表实现。你应该知道如何
 *使用`list_init`，`list_add`（`list_add_after`），`list_add_before`，`list_del`，
 *`list_next`，`list_prev`。
 *有一个棘手的方法是将一般的`list`结构转换为
 *特殊结构（例如struct`page`），使用以下宏：`le2page`
 *（在memlayout.h中），以及在以后的实验室中：`le2vma`（在vmm.h中），`le2proc`（在
 * proc.h）等）。
 *（2）`default_init`：
 *您可以重用演示`default_init`函数来初始化`free_list`
 *并将“ nr_free”设置为0。“ free_list”用于记录可用内存块。
 *`nr_free`是空闲内存块的总数。
 *（3）`default_init_memmap`：
 *通话图：`kern_init`->`pmm_init`->`page_init`->`init_memmap`->
 *`pmm_manager`->`init_memmap`
 *此函数用于初始化空闲块（带有参数`addr_base`，
 *`page_number`）。为了初始化空闲块，首先，您应该
 *初始化此空闲块中的每个页面（在memlayout.h中定义）。这
 *程序包括：
 *-设置`p-> flags`的`PG_property`位，这意味着该页面是
 * 有效的。 P.S.在函数“ pmm_init”（在pmm.c中）中，“ PG_reserved”位
 *`p-> flags'已经设置。
 *-如果此页面是免费的，而不是可用块的第一页，
 *`p-> property`应该设置为0。
 *-如果该页面是免费的，并且是一个免费块的第一页，则`p-> property`
 *应设置为块中的总页数。
 *-p-> ref应该为0，因为现在p是免费的，没有参考。
 *之后，我们可以使用`p-> page_link`将该页面链接到`free_list`。
 *（例如：`list_add_before（＆free_list，＆（p-> page_link））;`）
 *最后，我们应该更新可用内存块的总和：`nr_free + = n`。
 *（4）`default_alloc_pages`：
 *在空闲列表中搜索第一个空闲块（块大小> = n）并重新排列
 *找到的块，返回该块的地址作为所需的地址
 *`malloc`。
 *（4.1）
 *因此，您应该像这样搜索免费列表：
 * list_entry_t le =＆free_list;
 * while（（le = list_next（le））！=＆free_list）{
 * ...
 *（4.1.1）
 *在while循环中，获取结构`page`并检查`p-> property`
 *（在此块中记录可用页数）> = n。
 * struct Page * p = le2page（le，page_link）;
 * if（p->属性> = n）{...
 *（4.1.2）
 *如果找到此`p`，则表示我们找到了一个大小为空的自由块
 *> = n，可以分配前n个页面。此页面的一些标志位
 *应设置如下：`PG_reserved = 1`，`PG_property = 0`。
 *然后，从`free_list`断开页面链接。
 *（4.1.2.1）
 *如果`p-> property> n`，我们应该重新计算剩余的数量
 *此免费块的页面。 （例如：`le2page（le，page_link））->属性
 * = p->属性-n;`）
 *（4.1.3）
 *重新计算`nr_free`（所有可用块中其余部分的编号）。
 *（4.1.4）
 *返回`p`。
 *（4.2）
 *如果找不到大小大于等于n的空闲块，则返回NULL。
 *（5）`default_free_pages`：
 *将页面重新链接到空闲列表中，并可能将小的空闲块合并到
 *大的。
 *（5.1）
 *根据提取的块的基地址，搜索免费的
 *列出其正确位置（地址从低到高），然后插入
 *页面。 （可以使用`list_next`，`le2page`，`list_add_before`）
 *（5.2）
 *重置页面的字段，例如`p-> ref`和`p-> flags'（PageProperty）
 *（5.3）
 *尝试合并地址较低或较高的块。注意：这应该
 *正确更改某些页面的“ p->属性”。
 * /



 2
 / *实验2：您的代码
     *
     *如果您需要访问实际地址，请使用KADDR（）
     *请阅读pmm.h以获取有用的宏
     *
     *也许您需要帮助注释，下面的注释可以帮助您完成代码
     *
     *一些有用的宏和定义，您可以在下面的实现中使用它们。
     *宏或功能：
     * PDX（la）=虚拟地址la的页面目录条目的索引。
     * KADDR（pa）：获取一个物理地址并返回相应的内核虚拟地址。
     * set_page_ref（page，1）：表示该页面被引用一次
     * page2pa（page）：获取此（struct Page *）页面管理的内存的物理地址
     * struct Page * alloc_page（）：分配一个页面
     * memset（void * s，char c，size_t n）：设置s指向的存储区域的前n个字节
     *至指定值c。
     *定义：
     * PTE_P 0x001 //页表/目录条目标志位：当前
     * PTE_W 0x002 //页表/目录条目标志位：可写
     * PTE_U 0x004 //页面表/目录条目标志位：用户可以访问
     * /
#if 0
    pde_t * pdep = NULL; //（1）查找页面目录条目
    if（0）{//（2）检查条目是否不存在
                          //（3）检查是否需要创建，然后为页面表分配页面
                          //注意：此页面用于页面表，而不用于公共数据页面
                          //（4）设置页面参考
        uintptr_t pa = 0; //（5）获取页面的线性地址
                          //（6）使用memset清除页面内容
                          //（7）设置页面目录条目的权限
    }
    返回NULL; //（8）返回页表项
＃万一
}

3
/ *实验3：您的代码
     *
     *请检查ptep是否有效，如果更新了映射，则必须手动更新tlb
     *
     *也许您需要帮助注释，下面的注释可以帮助您完成代码
     *
     *一些有用的宏和定义，您可以在下面的实现中使用它们。
     *宏或功能：
     * struct Page * page pte2page（* ptep）：从ptep的值获取相应的页面
     * free_page：释放页面
     * page_ref_dec（page）：减少page-> ref。注意：ff page-> ref == 0，那么此页面应该是免费的。
     * tlb_invalidate（pde_t * pgdir，uintptr_t la）：使TLB条目无效，但仅当页表被
     *编辑的是处理器当前正在使用的那些。
     *定义：
     * PTE_P 0x001 //页表/目录条目标志位：当前
     * /
#if 0
    if（0）{//（1）检查此页表项是否存在
        struct Page * page = NULL; //（2）找到对应的页面到pte
                                  //（3）减少页面引用
                                  //（4）并在页面引用达到0时释放此页面
                                  //（5）清除第二页表条目
                                  //（6）刷新tlb
    }






    int 15h
    通过BIOS中断获取内存可调用参数为e820h的INT 15h BIOS中断。
    系统内存映射地址类型的值：
01h 内存，可用于OS
02h 保留，不可用（例如系统ROM，内存映射设备）
03h ACPI回收内存（在读取ACPI表后可由OS使用）
04h ACPI NVS内存（需要操作系统才能在NVS会话之间保存此内存）
其他尚未定义-视为保留

INT15h BIOS中断的详细调用参数:

eax：e820h：INT 15的中断调用参数；
edx：534D4150h (即4个ASCII字符“SMAP”) ，这只是一个签名而已；
ebx：如果是第一次调用或内存区域扫描完毕，则为0。 如果不是，则存放上次调用之后的计数值；
ecx：保存地址范围描述符的内存大小,应该大于等于20字节；
es:di：指向保存地址范围描述符结构的缓冲区，BIOS把信息写入这个结构的起始地址。

此中断的返回值为:

cflags的CF位：若INT 15中断执行成功，则不置位，否则置位；

eax：534D4150h ('SMAP') ；

es:di：指向保存地址范围描述符的缓冲区,此时缓冲区内的数据已由BIOS填写完毕

ebx：下一个地址范围描述符的计数地址

ecx    ：返回BIOS往ES:DI处写的地址范围描述符的字节大小

ah：失败时保存出错代码

现物理内存探测

物理内存探测是在bootasm.S中实现的，相关代码很短，如下所示：

probe_memory:
//对0x8000处的32位单元清零,即给位于0x8000处的
//struct e820map的成员变量nr_map清零
           movl $0, 0x8000
                  xorl %ebx, %ebx
//表示设置调用INT 15h BIOS中断后，BIOS返回的映射地址描述符的起始地址
                  movw $0x8004, %di
start_probe:
                  movl $0xE820, %eax // INT 15的中断调用参数
//设置地址范围描述符的大小为20字节，其大小等于struct e820map的成员变量map的大小
                  movl $20, %ecx
//设置edx为534D4150h (即4个ASCII字符“SMAP”)，这是一个约定
                  movl $SMAP, %edx
//调用int 0x15中断，要求BIOS返回一个用地址范围描述符表示的内存段信息
                  int $0x15
//如果eflags的CF位为0，则表示还有内存段需要探测
                  jnc cont
//探测有问题，结束探测
                  movw $12345, 0x8000
                  jmp finish_probe
cont:
//设置下一个BIOS返回的映射地址描述符的起始地址
                  addw $20, %di
//递增struct e820map的成员变量nr_map
                  incl 0x8000
//如果INT0x15返回的ebx为零，表示探测结束，否则继续探测
                  cmpl $0, %ebx
                  jnz start_probe
finish_probe:
上述代码正常执行完毕后，在0x8000地址处保存了从BIOS中获得的内存分布信息，此信息按照struct e820map的设置来进行填充。这部分信息将在bootloader启动ucore后，由ucore的page_init函数来根据struct e820map的memmap（定义了起始地址为0x8000）来完成对整个机器中的物理内存的总体管理。


CR3: 用来存放页目录表物理内存基地址
//这条指令运行在低地址上，所以说不能放到前面
//jmp next是通过偏移进行相对跳转 jmp *%eax 是直接把eax的值赋值给eip


#define REALLOC(x) (x - KERNBASE)
#这里是内核的代码段，被加载在物理地址的1mB的位置
.text
.globl kern_entry
kern_entry:

 

    # 初始化内核环境的页表,把页目录表地址重定位后放入cr3
    #页目录表分析在下面
    movl $REALLOC(__boot_pgdir), %eax
    movl %eax, %cr3

    # 使能 paging.
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0

    # 现在我们要更新eip寄存器，现在的eip = 0x1.....
    # mind here！（注意这里）
    #为什么我们要更新eip寄存器？以及为何我们需要一个暂时的（0-4m）:（0-4m）的地址映射？
    #因为我们刚刚开启了分页，这时候要寻址的话，eip寄存器里面应该存的是虚拟地址，但问题是现在ip寄存器里面存的还是我们开启分页以前的物理地址，如果我们直接使用(kernbase,kernbase+4m）:（0-4m）的地址映射的话就会找不到地方，所以我们现在需要一个（0-4m）:（0-4m）的映射来在我们更新eip寄存器（把正确的虚拟地址放到eip寄存器里面替换现在的物理地址）完成之前还能让程序找到地方。
    
    # 执行下面这条指令时,虽然访问的仍然是处于[0,4MB)的物理空间（kernelbase开始的虚拟地址）,因为开启了分页了,会经过页表的查找.将虚拟地址映射到物理地址
    # 为了更新 eip
    # 将next的地址存入eax，存入的next是虚拟地址，jmp之后eip里面也就是虚拟地址了
    leal next, %eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
    //此时的内核（EIP）还在0~4M的低虚拟地址区域运行，而在之后，这个区域的虚拟内存是要给用户程序使用的。为此，需要使用一个绝对跳转来使内核跳转到高虚拟地址，即上面代码中的jmp 到next里面

next:
    # jmp 过来之后，eip也就成功的从物理地址切换到虚拟地址了。所以我们现在不需要（0-4m）:（0-4m）的映射了
    # 在这里取消虚拟地址 0 ~ 4M 的映射,即将 __boot_pgdir 置零.
    xorl %eax, %eax
    movl %eax, __boot_pgdir
    //为什么不能放前面？//这条指令运行在低地址上，所以说不能放到前面
//jmp next是通过偏移进行相对跳转 jmp *%eax 是直接把eax的值赋值给eip

    # set ebp, esp，搭建栈（ss在之前已经设定好了）
    movl $0x0, %ebp

    # 内核栈范围是 [bootstack, bootstacktop)
    # 内核栈大小是 KSTACKSIZE (8KB), 在memlayout.h 中定义.
    movl $bootstacktop, %esp

    # 内核栈就绪, 调用C 函数
    call kern_init

# should never get here
spin:
    jmp spin

#这里是数据段
.data
.align PGSIZE
    .globl bootstack
bootstack:
    .space KSTACKSIZE
    .globl bootstacktop
bootstacktop:


# 内核内置一级页表.
# 每个一级页表对应 1024 个二级页表,即一个一级页表（页目录）对应4MB的内存
# 我们只需要映射两块,把对虚拟内存 [0,4M)和[KERNBASE, KERNBASE+4M)都映射到物理内存[0,4M)上.
# 所以只需 2 个一级页表项.
# 第一个页表项的上限是KERNBASE,共占用 768 个 entry,共 3072Byte<PAGESIZE,加上第二个页表项,再加上对齐,也没超过1 个 PAGESIZE.
# 而一个 PAGESIZE 可以容纳 4K/4=1K 个 entry. KERNBASE 大概在其中 3/4 的位置,还可以容纳 1K - 768 = 256 个 entry,即 1G 的容量.
# 实际 nm 输出
# c0158000 d __boot_pt1
# c0157c00 d __second_PDE
# c0157000 D __boot_pgdir
# 也可以得到验证, 一级页表共占用 0x1000Byte=4KB


.section .data.pgdir
.align PGSIZE
__boot_pgdir:
.globl __boot_pgdir
    # 第一个一级页表项,把虚拟地址 0 ~ 4M 临时映射到 0 ~ 4M. 在跳到 kern_init 之前就已抹除.
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    # 从 0 到KERNBASE,中间间隔了 KERNBASE/4M = 3072/4=768 项,共 768*4B = 3072Byte,不到一个 PAGESIZE.
    # 为何最后还要<<2 ?每个页表项占用 1 个long,是 32bit,从 byte 到 long 需要*4,即<<2
    .space (KERNBASE >> PGSHIFT >> 10 << 2) - (. - __boot_pgdir) # 与 KERNBASE 的一级页表项对齐
__second_PDE:
    # 第二个一级页表项,把虚拟地址 KERNBASE + (0 ~ 4M) 映射到物理地址 0 ~ 4M
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    .space PGSIZE - (. - __boot_pgdir) # 与 PAGESIZE 对齐.

# ↓ 两个一级页表项都指向下边的二级页表项

# boot 阶段临时单个二级页表内容,专门用于映射至 [0,4MB)
# 定义: 一个二级页表 1024 项,即按 1K 再次分页
# 每项的内容: 从 0 开始,每项的值递增 4096,即 i * PGSIZE,辅以属性
.set i, 0
__boot_pt1:
.globl __boot_pt1
.rept 1024
    .long i * PGSIZE + (PTE_P | PTE_W)
    .set i, i + 1
.endr




//pmm_init - 建立pmm管理物理地址, 建立PDT&PT开启分页机制 
void
pmm_init(void) {
   // 之前已经开启了paging,用的是 bootloader 的页表基址.现在单独维护一个变量boot_cr3 即内核一级页表基址.这个boot_pgdir就是我们刚刚开启分页时所采用的那个一级页表
   
    boot_cr3 = PADDR(boot_pgdir);//physical addr()
    LOG_TAB("已维护内核页表物理地址;当前页表只临时维护了 KERNBASE 起的 4M 映射,页表内容:\n");
    print_all_pt(boot_pgdir);

    // 初始化物理内存分配器,之后即可使用其 alloc/free pages 的功能
    init_pmm_manager();

    // 探测物理内存分布,初始化 pages, 然后调用 pmm->init_memmap 来初始化 freelist
    page_init();

    // 测试pmm 的alloc/free
    check_alloc_page();
    //测试用函数
    check_pgdir();

    // 编译时校验: KERNBASE和KERNTOP都是PTSIZE的整数,即可以用两级页表管理(4M 的倍数)
    static_assert(KERNBASE % PTSIZE == 0);
    static_assert( KERNTOP % PTSIZE == 0);

    //自映射实现：下文会具体探讨，在这里留个印象
    LOG("\n开始建立一级页表自映射: [VPT, VPT + 4MB) => [PADDR(boot_pgdir), PADDR(boot_pgdir) + 4MB).\n");
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
    LOG("\n自映射完毕.\n");
    print_all_pt(boot_pgdir);


    // 把所有物理内存区域映射到虚拟空间.即 [0, KMEMSIZE)->[KERNBASE, KERNBASE+KERNBASE);
    // 在此过程中会建立二级页表, 写对应的一级页表.
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
    print_all_pt(boot_pgdir);

    // 到目前为止还是用的 bootloader 的GDT.
    // 现在更新为内核的 GDT,把内存平铺, virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G.
    // 然后设置内存中的TSS即 ts, ss:esp, 设置 gdt 中的 TSS指向&ts, 最后设置 TR 寄存器的值为 gdt 中 TSS 项索引.
    gdt_init();

    // 基本的虚拟地址空间分布已经建立.检查其正确性.
    check_boot_pgdir();

    print_pgdir();
    
    kmalloc_init();
    LOG_LINE("初始化完毕:内存管理模块");
}


static void
page_init(void) {
    LOG_LINE("初始化开始:内存分页记账");
    LOG("目标: 根据探测得到的物理空间分布,初始化 pages 表格.\n\n");
    LOG_TAB("1. 确定 pages 基址. 通过 ends 向上取整得到, 位于 end 之上, 这意味着从此就已经突破了内核文件本身的内存空间,开始动态分配内存\n");
    LOG_TAB("2. 确定 page 数 npages,即 可管理内存的页数.\n");
    LOG_TAB("\t2.1 确定实际管理的物理内存大小maxpa.即向上取探测结果中的最大可用地址,但不得大于管理上限 KMEMSIZE. maxpa = min{maxpa, KMEMSIZE}.\n");
    LOG_TAB("\t2.2 npage = maxpa/PAGESIZE.\n");
    LOG_TAB("\t3. 确定可管理内存中每个空闲 page 的属性,便于日后的换入换出的调度; 加入到 freelist 中.\n\n");
     
    //memmap是一个描述物理区域状态的数组，具体见下文
    //这个结构体的实例mmemmap是之前内存探测时候就初始化好了的，描述物理空间状态，保存在0x8000的地方（初始化见指导书lab2附录2）
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;     // 可管理物理空间上限,最大不超过 KMEMSIZE

    LOG("1) e820map信息报告:\n\n");
    LOG("   共探测到%d块内存区域:\n\n",memmap->nr_map);

    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
        uint64_t range_begin = memmap->map[i].addr, range_end = range_begin + memmap->map[i].size;
        LOG_TAB("区间[%d]:[%08llx, %08llx], 大小: 0x%08llx Byte, 类型: %d, ",
                i, range_begin, range_end - 1, memmap->map[i].size, memmap->map[i].type);

        if (memmap->map[i].type == E820_ARM) {  // E820_ARM,ARM=address range memory,可用内存,值=1
            LOG_TAB("系可用内存.\n");
            if (maxpa < range_end && range_begin < KMEMSIZE) {
                maxpa = range_end;
                LOG_TAB("\t调整已知物理空间最大值 maxpa 至 0x%08llx = %lld K = %lld M\n", maxpa, maxpa /1024, maxpa /1024/1024);
            }
        }else{
            LOG_TAB("系不可用内存.\n");
        }
    }
    if (maxpa > KMEMSIZE) { // 可管理物理空间上限不超过 KMEMSIZE=0x38000000
        maxpa = KMEMSIZE;   
    }

    extern char end[];  //bootloader加载ucore的结束地址，这是在linker script里面定义的

    npage = maxpa / PGSIZE;//页面（框）数
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (i = 0; i < npage; i ++) {
        SetPageReserved(pages + i); // 设置 pages 表格中 page 的属性为不可交换，供内核使用
    }
    LOG("\n2) 物理内存维护表格 pages 初始化:\n     \n");

    LOG_TAB("实际管理物理内存大小 maxpa = 0x%08llx = %dM\n",maxpa,maxpa/1024/1024);
    LOG_TAB("需要管理的内存页数 npage = maxpa/PGSIZE = %d\n", npage);
    LOG_TAB("内核文件地址边界 end: 0x%08llx\n",end);
    LOG_TAB("表格起始地址 pages = ROUNDUP(end) = 0x%08lx = %d M\n", (uintptr_t)pages, (uintptr_t)pages/1024/1024);
    LOG_TAB("pages 表格自身内核虚拟地址区间 [pages,pages*n): [0x%08lx, 0x%08lx)B,已被设置为不可交换.\n",pages,((uintptr_t)pages + sizeof(struct Page) * npage), (uintptr_t)pages/1024/1024, ((uintptr_t)pages + sizeof(struct Page) * npage)/1024/1024);

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);

    LOG_TAB("pages 表格结束于物理地址 freemem :0x%08lxB ≈ %dM. 也是后序可用内存的起始地址. \n\n",freemem, freemem/1024/1024);
    LOG_TAB("考察管理区间, 将空闲区域标记为可用.\n");

//初始化这些页的一些属性
    for (i = 0; i < memmap->nr_map; i ++) {
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
        LOG_TAB("考察区间: [%08llx,%08llx):\t",begin,end);
        if (memmap->map[i].type == E820_ARM) {
            if (begin < freemem) {
                begin = freemem;
            }
            if (end > KMEMSIZE) {
                end = KMEMSIZE;
            }
            if (begin < end) {
                begin = ROUNDUP(begin, PGSIZE);
                end = ROUNDDOWN(end, PGSIZE);
                if (begin < end) {
                    LOG_TAB("此区间可用, 大小为 0x%08llx B = %lld KB = %lld MB = %lld page.\n", (end - begin), (end - begin)/1024, (end - begin)/1024/1024, (end - begin)/PGSIZE);
                    //initmemmap将一块连续的空闲地址加入freelist
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);
                }
            }else{
                LOG_TAB("此区间不可用, 原因: 边界非法.\n");
            }
        }else{
            LOG_TAB("此区间不可用, 原因: BIOS 认定非可用内存.\n");
        }
    }
    LOG_LINE("初始化完毕: 内存分页记账");
}

上面开启分页总共可分为如下几步：
1.根据探测内存的结果，找到最后一个可用空间的结束地址或内核结束地址的小者，算出物理空间总共有多少个页
2.找到内核结束地址（end），定义在连接脚本里面，从这个地址的下一个页（pages）写入page的信息(参考上面的内存分布图）
3.从pages开始，将所有页信息设置为系统预留
4.找到free页开始地址，初始化这些页的信息。


自映射
一个线性地址正是高10位作为页目录偏移，中10位为页表偏移，低12位为页内偏移。

/**
 * 对区域进行映射,专用于内核.
 *      把虚拟地址[la, la + size)映射至物理地址[pa, pa + size),映射关系保存在 pgdir 指向的一级页表上.
 *      la 和 pa 将向下对 PGSIZE 取整.
 * 映射过程: 
 *      对于给定的虚拟地址,每隔一个 PGSIZE值,就根据指定的一级页表地址pgdir,找到对应的二级页表项,写入相应的的物理地址和属性.
 * 
 * 计算: 对于内核初始值 KMEMSIZE=896MB,需要多少个/多大空间的二级页表来保存映射关系?
 *      1) 对于一级页表, 参考 entry.S, 一个 PAGESIZE 大小的一级页表,在 KERNELBASE之上还可以维护 1G 的内存>896MB,所以仍然使用已经定义的一级页表__boot_pgdir即可.
 *      2) 对于二级页表, 则需要896M/4K=224K个 entry,每个二级页表含 1K个 entry,所以共需要 224 个二级页表.
 *      3) ucore 中比较方便地设定为每个页表的大小是 1024 个,正好占用一个 page.所以需要224*4K=896KB 的空间容纳这些页表.
 */ 
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    LOG_LINE("开始: 内核区域映射");

    //LOG_TAB("一级页表地址:0x%08lx\n",pgdir);
    LOG_TAB("映射区间[0x%08lx,0x%08lx + 0x%08lx ) => [0x%08lx, 0x%08lx + 0x%08lx )\n", la, la, size, pa, pa, size);
    LOG_TAB("区间长度 = %u M\n", size/1024/1024);

    assert(PGOFF(la) == PGOFF(pa));// 要映射的地址在 page 内的偏移量应当相同
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    LOG_TAB("校准后映射区间: [0x%08lx, 0x%08lx), 页数:%u\n", la, pa, n);
    LOG_TAB("校准后映射区间: [0x%08lx,0x%08lx + 0x%08lx ) => [0x%08lx, 0x%08lx + 0x%08lx )\n", la, la, n * PGSIZE, pa, pa, n * PGSIZE);

    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;  // 写 la 对应的二级页表; 要保证权限的正确性.
    }
    LOG_TAB("映射完毕, 直接按照可管理内存上限映射. 虚存对一级页表比例: [KERNBASE, KERNBASE + KMEMSIZE) <=> [768, 896) <=> [3/4, 7/8)\n");
    
    LOG_LINE("完毕: 内核区域映射");
}

