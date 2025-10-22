    .extern start_kernel
    .extern _traps
    .extern clock_set_next_event
    .section .text.init
    .globl _start
_start:
    # 1. initialize stack
_init_stack:
    la sp, boot_stack_top

    # 2. initialize CSR
_init_csr:
    # set stvec = _traps
    la t0, _traps
    csrw stvec, t0
    # set sie[STIE] = 1
    li t1, (1 << 5)
    csrs sie, t1

    # 3. set first time interrupt
_first_interrupt:
    call clock_set_next_event

    # 4. set sstatus[SIE] = 1
_set_sstatus:
    li t1, (1 << 1)
    csrs sstatus, t1
    
    # 5. jump to start_kernel
_kernel_start:
    j start_kernel

    .section .bss.stack
    .globl boot_stack
boot_stack:
    .space 4096 # <-- change to your stack size

    .globl boot_stack_top
boot_stack_top:

# 我们首先为即将运行的第一个 C 函数设置程序栈（栈的大小可以设置为 4KiB），
# 并将该栈放置在 .bss.stack 段。
# 接下来我们只需要通过跳转指令，跳转至 main.c 中的 start_kernel 函数即可。