#include "mm.h"
#include "../include/defs.h"
#include "../include/proc.h"
#include "stdlib.h"
#include "printk.h"
#include "vm.h"
#include "elf.h"

extern void __dummy();
extern void __switch_to(struct task_struct *prev, struct task_struct *next);

struct task_struct *idle;           // idle process
struct task_struct *current;        // 指向当前运行线程的 task_struct
struct task_struct *task[NR_TASKS]; // 线程数组，所有的线程都保存在此

extern char _sramdisk[];
extern char _eramdisk[];

// /* --- uapp加载为纯二进制文件 --- */

// void task_init() {
//     srand(2024);

//     // 1. 调用 kalloc() 为 idle 分配一个物理页
//     // 2. 设置 state 为 TASK_RUNNING;
//     // 3. 由于 idle 不参与调度，可以将其 counter / priority 设置为 0
//     // 4. 设置 idle 的 pid 为 0
//     // 5. 将 current 和 task[0] 指向 idle

//     /* YOUR CODE HERE */
//     idle = (struct task_struct *)kalloc();
//     idle->state = TASK_RUNNING;
//     idle->counter = 0;
//     idle->priority = 0;
//     idle->pid = 0;
//     // idle->thread.sp = (uint64_t)idle + PGSIZE;
//     // idle->thread.ra = (uint64_t)__dummy;
//     current = idle;
//     task[0] = idle;

//     // 1. 参考 idle 的设置，为 task[1] ~ task[NR_TASKS - 1] 进行初始化
//     // 2. 其中每个线程的 state 为 TASK_RUNNING, 此外，counter 和 priority 进行如下赋值：
//     //     - counter  = 0;
//     //     - priority = rand() 产生的随机数（控制范围在 [PRIORITY_MIN, PRIORITY_MAX] 之间）
//     // 3. 为 task[1] ~ task[NR_TASKS - 1] 设置 thread_struct 中的 ra 和 sp
//     //     - ra 设置为 __dummy（见 4.2.2）的地址
//     //     - sp 设置为该线程申请的物理页的高地址

//     /* YOUR CODE HERE */
//     for(int i = 1; i < NR_TASKS; i++){
//         struct task_struct *temp = (struct task_struct *)kalloc();
//         temp->pid = i;
//         temp->state = TASK_RUNNING;
//         temp->counter = 0;
//         temp->priority = rand() % (PRIORITY_MAX - PRIORITY_MIN + 1) + PRIORITY_MIN;     //每日tip积累：生成n-m的随机数——>rand()%(m-n+1)+n
//         temp->thread.ra = (uint64_t)__dummy;
//         // 设置用户态进程的内核态栈
//         temp->thread.sp = (uint64_t)temp + PGSIZE;
        
//         /* --- 初始化thread_struct中的三个CSR变量值 --- */
//         // 1. 将 sepc 设置为 USER_START
//         temp->thread.sepc = USER_START;
//         // 2. 配置 sstatus 中的 SPP（使得 sret 返回至 U-Mode）、SUM（S-Mode 可以访问 User 页面）
//         temp->thread.sstatus = csr_read(sstatus);
//         temp->thread.sstatus &= ~(1 << 8); // SPP = 0
//         temp->thread.sstatus |= (1 << 5); // SPIE = 1
//         temp->thread.sstatus |= (1 << 18); // SUM = 1
//         // 3. 将 sscratch 设置为 U-Mode 的 sp，其值为 USER_END （将用户态栈放置在 user space 的最后一个页面）
//         temp->thread.sscratch = USER_END;

//         /* --- 对于每个进程，创建属于它自己的页表 --- */
//         // 1. 将swapper_pg_dir复制到每个进程的页表中
//         temp->pgd = (uint64_t *)kalloc();
//         memcpy(temp->pgd, swapper_pg_dir, PGSIZE);
//         // 2. 对于每个进程，分配一块新的内存地址，将uapp二进制文件内容拷贝过去，之后再将其所在的页面映射到对应进程的表中
//         //    拷贝具体方法：先计算所需的页数（uapp的大小除以PGSIZE后向上取整），调用alloc_pages()函数，再将uapp memcpy过去
//         uint64_t uapp_size = (uint64_t)_eramdisk - (uint64_t)_sramdisk;
//         uint64_t page_num = (uapp_size + PGSIZE - 1) / PGSIZE;
//         uint64_t *uapp_copy = (uint64_t *)alloc_pages(page_num);
//         // if(!uapp_copy){
//         //     printk("Failed to allocate pages for uapp\n");
//         //     continue;
//         // }
//         memcpy(uapp_copy, _sramdisk, uapp_size);
//         // 将拷贝好的uapp所在页映射到表中
//         create_mapping(temp->pgd, USER_START, (uint64_t)uapp_copy - PA2VA_OFFSET, page_num * PGSIZE, PTE_U | PTE_X | PTE_W | PTE_R | PTE_V);

//         /* --- 设置用户态栈 --- */
//         // 1. 申请一个空的页面来作为用户态栈，并映射到进程的页表中
//         temp->user_stack = kalloc();
//         create_mapping(temp->pgd, USER_END - PGSIZE, temp->user_stack - PA2VA_OFFSET, PGSIZE, PTE_U | PTE_W | PTE_R | PTE_V);
//         // 提前计算存储对应的satp，免去切换线程时计算的麻烦
//         temp->satp = (csr_read(satp) >> 44) << 44;
//         temp->satp |= ((uint64_t)(temp->pgd) - PA2VA_OFFSET) >> 12;
//         task[i] = temp;
//     }

//     printk("...task_init done!\n");
// }

/* --- uapp加载为ELF文件 --- */

void load_program(struct task_struct *task) {
    Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
    Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk + ehdr->e_phoff);
    for (int i = 0; i < ehdr->e_phnum; ++i) {
        Elf64_Phdr *phdr = phdrs + i;
        if (phdr->p_type == PT_LOAD) {
            // alloc space and copy content
            uint64_t va_start = PGROUNDDOWN(phdr->p_vaddr);
            uint64_t offset = phdr->p_vaddr - va_start;

            uint64_t page_num = (phdr->p_memsz + PGSIZE - 1) / PGSIZE;
            char *mem_copy = alloc_pages(page_num);
            memcpy(mem_copy + offset, (char *)ehdr + phdr->p_offset, phdr->p_filesz);
            if(phdr->p_memsz > phdr->p_filesz){
                memset(mem_copy + offset + phdr->p_filesz, 0, phdr->p_memsz - phdr->p_filesz);
            }

            // 验证入口点指令
            if (phdr->p_vaddr <= ehdr->e_entry && 
                ehdr->e_entry < phdr->p_vaddr + phdr->p_memsz) {
                uint32_t *entry_instr = (uint32_t *)(mem_copy + offset + 
                                            (ehdr->e_entry - phdr->p_vaddr));
                printk("  Entry instruction at 0x%lx: 0x%08x\n", 
                       ehdr->e_entry, *entry_instr);
            }

            // do mapping
            uint64_t pa_start = (uint64_t)mem_copy - PA2VA_OFFSET;
            uint64_t size = PGROUNDUP(va_start + phdr->p_memsz) - va_start;
            uint64_t perm = PTE_V | PTE_U;
            if(phdr->p_flags & PF_R){
                perm |= PTE_R;
            }
            if(phdr->p_flags & PF_W){
                perm |= PTE_W;
            }
            if(phdr->p_flags & PF_X){
                perm |= PTE_X;
            }
            create_mapping(task->pgd, va_start, pa_start, size, perm);
            // code...
        }
    }
    task->thread.sepc = ehdr->e_entry;
    printk("Loaded ELF: entry=0x%lx, sepc set to 0x%lx\n", 
       ehdr->e_entry, task->thread.sepc);
}


void task_init() {
    srand(2024);

    // 1. 调用 kalloc() 为 idle 分配一个物理页
    // 2. 设置 state 为 TASK_RUNNING;
    // 3. 由于 idle 不参与调度，可以将其 counter / priority 设置为 0
    // 4. 设置 idle 的 pid 为 0
    // 5. 将 current 和 task[0] 指向 idle

    /* YOUR CODE HERE */
    idle = (struct task_struct *)kalloc();
    idle->state = TASK_RUNNING;
    idle->counter = 0;
    idle->priority = 0;
    idle->pid = 0;
    // idle->thread.sp = (uint64_t)idle + PGSIZE;
    // idle->thread.ra = (uint64_t)__dummy;
    current = idle;
    task[0] = idle;

    // 1. 参考 idle 的设置，为 task[1] ~ task[NR_TASKS - 1] 进行初始化
    // 2. 其中每个线程的 state 为 TASK_RUNNING, 此外，counter 和 priority 进行如下赋值：
    //     - counter  = 0;
    //     - priority = rand() 产生的随机数（控制范围在 [PRIORITY_MIN, PRIORITY_MAX] 之间）
    // 3. 为 task[1] ~ task[NR_TASKS - 1] 设置 thread_struct 中的 ra 和 sp
    //     - ra 设置为 __dummy（见 4.2.2）的地址
    //     - sp 设置为该线程申请的物理页的高地址

    /* YOUR CODE HERE */
    for(int i = 1; i < NR_TASKS; i++){
        struct task_struct *temp = (struct task_struct *)kalloc();
        temp->pid = i;
        temp->state = TASK_RUNNING;
        temp->counter = 0;
        temp->priority = rand() % (PRIORITY_MAX - PRIORITY_MIN + 1) + PRIORITY_MIN;     //每日tip积累：生成n-m的随机数——>rand()%(m-n+1)+n
        temp->thread.ra = (uint64_t)__dummy;
        // 设置用户态进程的内核态栈
        temp->thread.sp = (uint64_t)temp + PGSIZE;
        
        /* --- 初始化thread_struct中的三个CSR变量值 --- */
        // 1. 将 sepc 设置为 USER_START
        // temp->thread.sepc = USER_START;
        
        // 2. 配置 sstatus 中的 SPP（使得 sret 返回至 U-Mode）、SUM（S-Mode 可以访问 User 页面）
        temp->thread.sstatus = csr_read(sstatus);
        temp->thread.sstatus &= ~(1 << 8); // SPP = 0
        temp->thread.sstatus |= (1 << 5); // SPIE = 1
        temp->thread.sstatus |= (1 << 18); // SUM = 1
        // temp->thread.sstatus &= ~(1 << 18); // (供验收测试) SUM = 0

        // 3. 将 sscratch 设置为 U-Mode 的 sp，其值为 USER_END （将用户态栈放置在 user space 的最后一个页面）
        temp->thread.sscratch = USER_END;

        /* --- 对于每个进程，创建属于它自己的页表 --- */
        // 1. 将swapper_pg_dir复制到每个进程的页表中
        temp->pgd = (uint64_t *)kalloc();
        memcpy(temp->pgd, swapper_pg_dir, PGSIZE);
        // 2. 将uapp加载进内存
        load_program(temp);
        
        /* --- 设置用户态栈 --- */
        // 1. 申请一个空的页面来作为用户态栈，并映射到进程的页表中
        temp->user_stack = kalloc();
        create_mapping(temp->pgd, USER_END - PGSIZE, temp->user_stack - PA2VA_OFFSET, PGSIZE, PTE_U | PTE_W | PTE_R | PTE_V);
        // 提前计算存储对应的satp，免去切换线程时计算的麻烦
        temp->satp = (csr_read(satp) >> 44) << 44;
        temp->satp |= ((uint64_t)(temp->pgd) - PA2VA_OFFSET) >> 12;
        task[i] = temp;
    }

    printk("...task_init done!\n");
}

#if TEST_SCHED
#define MAX_OUTPUT ((NR_TASKS - 1) * 10)
char tasks_output[MAX_OUTPUT];
int tasks_output_index = 0;
char expected_output[] = "2222222222111111133334222222222211111113";
#include "sbi.h"
#endif

void dummy() {
    uint64_t MOD = 1000000007;
    uint64_t auto_inc_local_var = 0;
    int last_counter = -1;
    while (1) {
        if ((last_counter == -1 || current->counter != last_counter) && current->counter > 0) {
            uint64_t current_sp;
            asm volatile(
                "mv %0, sp"
                : "=r" (current_sp)
            );
            uint64_t page_base = PGROUNDDOWN(current_sp);
            if (current->counter == 1) {
                --(current->counter);   // forced the counter to be zero if this thread is going to be scheduled
            }                           // in case that the new counter is also 1, leading the information not printed.
            last_counter = current->counter;
            auto_inc_local_var = (auto_inc_local_var + 1) % MOD;
            printk("[PID = %d] is running. auto_inc_local_var = %d,", current->pid, auto_inc_local_var);
            printk(YELLOW " sp = 0x%lx, task_struct = 0x%lx\n"CLEAR, current_sp, page_base);
            #if TEST_SCHED
            tasks_output[tasks_output_index++] = current->pid + '0';
            if (tasks_output_index == MAX_OUTPUT) {
                for (int i = 0; i < MAX_OUTPUT; ++i) {
                    if (tasks_output[i] != expected_output[i]) {
                        printk("\033[31mTest failed!\033[0m\n");
                        printk("\033[31m    Expected: %s\033[0m\n", expected_output);
                        printk("\033[31m    Got:      %s\033[0m\n", tasks_output);
                        sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
                    }
                }
                printk("\033[32mTest passed!\033[0m\n");
                printk("\033[32m    Output: %s\033[0m\n", expected_output);
                sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
            }
            #endif
        }
    }
}

void schedule() {
    // YOUR CODE HERE
    bool all_zero = true;
    struct task_struct* next;
    // 如果所有线程 counter 都为 0，则令所有线程 counter = priority
    //     即优先级越高，运行的时间越长，且越先运行
    //     设置完后需要重新进行调度
    for(int i = 0; i < NR_TASKS; i++){
        if(task[i]->counter != 0){
            all_zero = false;
            break;
        }
    }
    if(all_zero){
        for(int i = 0; i < NR_TASKS; i++){
            task[i]->counter = task[i]->priority;
            printk("SET [PID = %d PRIORITY = %d COUNTER = %d]\n", task[i]->pid, task[i]->priority, task[i]->counter);
        }
    }
    // 调度时选择 counter 最大的线程运行
    next = task[0];
    for(int i = 1; i < NR_TASKS; i++){
        if(next->counter < task[i]->counter){
            next = task[i];
        }
    }
    switch_to(next);
}

void switch_to(struct task_struct *next) {
    // YOUR CODE HERE
    // 如果next和current是同一个线程，则无需做任何处理
    // int local = 0x1234;
    if(current->pid != next->pid){
        printk("switch to [PID = %d PRIORITY = %d COUNTER = %d]\n", next->pid, next->priority, next->counter);
        struct task_struct* prev = current;
        current = next;
        __switch_to(prev, next);
    }
}



void do_timer() {
    // 1. 如果当前线程是 idle 线程或当前线程时间片耗尽则直接进行调度
    // 2. 否则对当前线程的运行剩余时间减 1，若剩余时间仍然大于 0 则直接返回，否则进行调度
    // YOUR CODE HERE
    if(current->pid == 0 || current->counter == 0){
        schedule();
    }
    else{
        current->counter--;
        // printk("now the count of PID %d is %d left\n", current->pid, current->counter);
        if(current->counter > 0){
            return;
        }
        else{
            schedule();
        }
    }
}