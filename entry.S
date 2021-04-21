#include <mmu.h>
#include <memlayout.h>

#define REALLOC(x) (x - KERNBASE)

.text
.globl kern_entry
kern_entry:
    //# load pa of boot pgdir设置page directory
    movl $REALLOC(__boot_pgdir), %eax
    movl %eax, %cr3 //把页目录表的起始地址存入CR3寄存器中

    # enable paging
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax  //jmp next是通过偏移进行相对跳转 jmp *%eax 是直接把eax的值赋值给eip
next:
//# 在这里取消虚拟地址 0 ~ 4M 的映射,即将 __boot_pgdir 置零.
    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
    movl %eax, __boot_pgdir

    # set ebp, esp
    movl $0x0, %ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
//# 内核栈范围是 [bootstack, bootstacktop)
  //  # 内核栈大小是 KSTACKSIZE (8KB), 在memlayout.h 中定义.
    # now kernel stack is ready , call the first C function
    call kern_init

# should never get here
spin:
    jmp spin

.data
.align PGSIZE
    .globl bootstack
bootstack:
    .space KSTACKSIZE
    .globl bootstacktop
bootstacktop:


/*# 内核内置一级页表.
# 每个一级页表对应 1024 个二级页表,即一个一级页表（页目录）对应4MB的内存
# 我们只需要映射两块,把对虚拟内存 [0,4M)和[KERNBASE, KERNBASE+4M)都映射到物理内存[0,4M)上.
# 所以只需 2 个一级页表项.
# 第一个页表项的上限是KERNBASE,共占用 768 个 entry,共 3072Byte<PAGESIZE,加上第二个页表项,再加上对齐,也没超过1 个 PAGESIZE.
# 而一个 PAGESIZE 可以容纳 4K/4=1K 个 entry. KERNBASE 大概在其中 3/4 的位置,还可以容纳 1K - 768 = 256 个 entry,即 1G 的容量.
# 实际 nm 输出
# c0158000 d __boot_pt1
# c0157c00 d __second_PDE
# c0157000 D __boot_pgdir
# 也可以得到验证, 一级页表共占用 0x1000Byte=4KB*/

# kernel builtin pgdir
# an initial page directory (Page Directory Table, PDT)
# These page directory table and page table can be reused!
.section .data.pgdir
.align PGSIZE
__boot_pgdir:
.globl __boot_pgdir
    # map va 0 ~ 4M to pa 0 ~ 4M (temporary)
//# 第一个一级页表项,把虚拟地址 0 ~ 4M 临时映射到 0 ~ 4M. 在跳到 kern_init 之前就已抹除.
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
// # 从 0 到KERNBASE,中间间隔了 KERNBASE/4M = 3072/4=768 项,共 768*4B = 3072Byte,不到一个 PAGESIZE.
//# 为何最后还要<<2 ?每个页表项占用 1 个long,是 32bit,从 byte 到 long 需要*4,即<<2
    .space (KERNBASE >> PGSHIFT >> 10 << 2) - (. - __boot_pgdir) # pad to PDE of KERNBASE
    # map va KERNBASE + (0 ~ 4M) to pa 0 ~ 4M
//# 第二个一级页表项,把虚拟地址 KERNBASE + (0 ~ 4M) 映射到物理地址 0 ~ 4M
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)
    .space PGSIZE - (. - __boot_pgdir) # pad to PGSIZE

//# boot 阶段临时单个二级页表内容,专门用于映射至 [0,4MB)
//# 定义: 一个二级页表 1024 项,即按 1K 再次分页
//# 每项的内容: 从 0 开始,每项的值递增 4096,即 i * PGSIZE4096,辅以属性
.set i, 0
__boot_pt1:
.rept 1024
    .long i * PGSIZE + (PTE_P | PTE_W)
    .set i, i + 1
.endr

