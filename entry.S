.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)

    pushl %edx              # push arg
    call *%ebx              # call fn

    pushl %eax              # 保存fn(arg)的返回值
    call do_exit            # call do_exit 终止当前的线程

