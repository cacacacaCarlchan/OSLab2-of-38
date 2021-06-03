#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle
enum proc_state {
    PROC_UNINIT = 0,  // 未初始化
    PROC_SLEEPING,    // 睡眠中
    PROC_RUNNABLE,    // 可运行，可能正在运行
    PROC_ZOMBIE,      // 快死了，等待父进程回收它的资源
};

// 为内核上下文切换保存寄存器。
// 不需要保存所有的 %fs 等段寄存器，
// 因为它们在内核上下文中是不变的。
// 保存所有的通用寄存器regular registers，所以我们不需要关心
// 哪些是调用者保存的，但不是返回寄存器 %eax。
//（不保存 %eax 只是简化了切换代码。）
// 上下文的布局必须匹配 switch.S 中的代码。
struct context {
    uint32_t eip;
    uint32_t esp;
    uint32_t ebx;
    uint32_t ecx;
    uint32_t edx;
    uint32_t esi;
    uint32_t edi;
    uint32_t ebp;
};

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

extern list_entry_t proc_list;
//进程控制块 
struct proc_struct {
    enum proc_state state;                      // 进程状态
    int pid;                                    // 进程ID
    int runs;                                   // 进程的运行时间
    uintptr_t kstack;                           // 进程的内核栈的位置
    volatile bool need_resched;                 // bool值：是否需要被重新调度以释放cpu?
    struct proc_struct *parent;                 // 父进程
    struct mm_struct *mm;                       // 进程的虚拟内存管理空间
// mm：内存管理的信息，包括内存映射列表、页表指针等。mm成员变量在lab3中用于虚存管理。但在实际OS中，内核线程常驻内存，不需要考虑swap page问题，在lab5中涉及到了用户进程，才考虑进程用户内存空间的swap page问题，mm才会发挥作用。所以在lab4中mm对于内核线程就没有用了，这样内核线程的proc_struct的成员变量*mm=0是合理的。mm里有个很重要的项pgdir，记录的是该进程使用的一级页表的物理地址。由于*mm=NULL，所以在proc_struct数据结构中需要有一个代替pgdir项来记录页表起始地址，这就是proc_struct数据结构中的cr3成员变量。
    struct context context;                     // 上下文
    struct trapframe *tf;                       // Trap frame当前的中断帧
    uintptr_t cr3;                              // CR3 register: 当前页目录表PDT的基地址
    uint32_t flags;                             // 进程状态
    char name[PROC_NAME_LEN + 1];               // 进程名字
    list_entry_t list_link;                     // Process link list进程链表
    list_entry_t hash_link;                     // Process hash list
};

#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)//返回该链表指向的进程

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

