#include "defs.h"
    .extern start_kernel
    .extern _traps
    .extern clock_set_next_event
    .extern task_init
    .extern mm_init
    # .extern early_pgtbl
    .section .text.init
    .globl _start
    .globl relocate
    
_start:
    # initialize idle stack
_init_stack:
    la sp, boot_stack_top

    call setup_vm
    call relocate

    # initialize CSR
_init_csr_trap:
    # set stvec = _traps
    la t0, _traps
    csrw stvec, t0
    
    # initialize memory management
    call mm_init
    call setup_vm_final

    # set sie[STIE] = 1
    li t1, (1 << 5)
    csrs sie, t1
    # set first time interrupt
    call clock_set_next_event
    # set sstatus[SIE] = 1
    # (
    #   lab4里面要在内核启动后立即进行调度，即手动调用schedule函数；
    #   为避免在此过程中发生时钟中断，需要先将SIE置0
    # )
    # li t1, (1 << 1)
    # csrs sstatus, t1
    # set sstatus[SSP] = 1
    li t0, (1 << 8)
    csrs sstatus, t0
    # set sstatus[SPIE] = 1
    li t0, (1 << 8)
    csrs sstatus, t0

    # initialize tasks
_tasks_init:
    call task_init
    
    # start kernel
_kernel_start:
    j start_kernel

relocate:
    # set ra = ra + PA2VA_OFFSET
    # set sp = sp + PA2VA_OFFSET (If you have set the sp before)

    ###################### 
    li t0, PA2VA_OFFSET
    add ra, ra, t0
    add sp, sp, t0
    ######################

    # # need a fence to ensure the new translations are in use
    # sfence.vma zero, zero

    # set satp with early_pgtbl

    ######################
    # 设置MODE段
    li t1, 8
    slli t1, t1, 60
    # 设置PPN段
    la t2, early_pgtbl
    srli t2, t2, 12
    # 组装（ASID本实验中直接置0）
    or t1, t1, t2
    csrw satp, t1
    ######################

    # need a fence to ensure the new translations are in use
    sfence.vma zero, zero

    ret

    .section .bss.stack
    .globl boot_stack
boot_stack:
    .space 4096 # <-- change to your stack size

    .globl boot_stack_top
boot_stack_top:
