.text
.globl switch_to
#switch_to函数主要完成的是进程的上下文切换，先保存当前寄存器的值，然后再将下一进程的上下文信息保存到对于寄存器中。
switch_to:                      # switch_to(from, to)

   #从寄存器中保存
#首先，保存前一个进程的执行现场，前两条汇编指令保存了进程在返回switch_to函数后的指令地址到context.eip中
    movl 4(%esp), %eax          # 保存from的首地址
    popl 0(%eax)                #  esp--> 返回值，因此先将返回值保存在 FROM 的上下文中
#在接下来的7条汇编指令完成了保存前一个进程的其他7个寄存器到context中的相应成员变量中。至此前一个进程的执行现场保存完毕。
    movl %esp, 4(%eax)
    movl %ebx, 8(%eax)
    movl %ecx, 12(%eax)
    movl %edx, 16(%eax)
    movl %esi, 20(%eax)
    movl %edi, 24(%eax)
    movl %ebp, 28(%eax)

    # 恢复到寄存器
#再往后是恢复向一个进程的执行现场，这其实就是上述保存过程的逆执行过程，即从context的高地址的成员变量ebp开始，逐一把相关成员变量的值赋值给对应的寄存器
    movl 4(%esp), %eax          # not 8(%esp): 已经弹出返回地址
                                # eax 现在指向 to
    movl 28(%eax), %ebp
    movl 24(%eax), %edi
    movl 20(%eax), %esi
    movl 16(%eax), %edx
    movl 12(%eax), %ecx
    movl 8(%eax), %ebx
    movl 4(%eax), %esp
#下一条把context中保存的下一个进程要执行的指令地址context.eip放到了堆栈顶，这样接下来执行最后一条指令“ret”时，会把栈顶的内容赋值给EIP寄存器，这样就切换到下一个进程执行了，即当前进程已经是下一个进程了
    pushl 0(%eax)               #将to的context的 eip压栈，因此返回 addr = to 的 eip

    ret    #在 ret 之后，eip= to 的 eip

