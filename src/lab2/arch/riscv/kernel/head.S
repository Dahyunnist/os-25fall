    .extern start_kernel
    .extern _traps
    .extern clock_set_next_event
    .section .text.init
    .globl _start
    .extern task_init
    .extern mm_init
_start:
    # initialize idle stack
_init_stack:
    la sp, boot_stack_top
    
    # initialize CSR
_init_csr_trap:
    # set stvec = _traps
    la t0, _traps
    csrw stvec, t0
    
    # initialize memory management
    call mm_init

    # set sie[STIE] = 1
    li t1, (1 << 5)
    csrs sie, t1
    # set first time interrupt
    call clock_set_next_event
    # set sstatus[SIE] = 1
    li t1, (1 << 1)
    csrs sstatus, t1
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

    .section .bss.stack
    .globl boot_stack
boot_stack:
    .space 4096 # <-- change to your stack size

    .globl boot_stack_top
boot_stack_top:
