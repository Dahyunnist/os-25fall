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
int nr_tasks = 2; // 执行fork测试使用此行
// int nr_tasks = NR_TASKS; // 执行page fault测试使用此行


/*
* @mm       : current thread's mm_struct
* @addr     : the va to look up
*
* @return   : the VMA if found or NULL if not found
*/
struct vm_area_struct *find_vma(struct mm_struct *mm, uint64_t addr){
    if(mm == NULL){
        return NULL;
    }
    struct vm_area_struct *cur = mm->mmap;
    if(cur == NULL){
        return NULL;
    }
    while(cur != NULL){
        if(addr >= cur->vm_start && addr < cur->vm_end){
            return cur;
        }
        cur = cur->vm_next;
    }
    return NULL;
}

/*
* @mm       : current thread's mm_struct
* @addr     : the va to map
* @len      : memory size to map
* @vm_pgoff : phdr->p_offset
* @vm_filesz: phdr->p_filesz
* @flags    : flags for the new VMA
*
* @return   : start va
*/
uint64_t do_mmap(struct mm_struct *mm, uint64_t addr, uint64_t len, uint64_t vm_pgoff, uint64_t vm_filesz, uint64_t flags){
    // 新建vm_area_struct结构体
    struct vm_area_struct *vma = (struct vm_area_struct *)kalloc();
    vma->vm_next = NULL;
    vma->vm_prev = NULL;

    // 计算起讫地址(此处只需如实记录即可，对齐是在分配物理页时要做的工作)
    uint64_t vm_start = addr;
    uint64_t vm_end = addr + len;

    // 检查地址有效性
    if(vm_start < USER_START || vm_end > USER_END || vm_end <= vm_start){
        return 0;
    }
    // 将传入的参数填入vma
    vma->vm_mm = mm;
    vma->vm_start = vm_start;
    vma->vm_end = vm_end;
    vma->vm_flags = flags;
    vma->vm_pgoff = vm_pgoff;
    vma->vm_filesz = vm_filesz;

    // 插入mmap，需要检查地址是否重叠并找到合适的插入位置
    // 如果此时链表尚为空，vma就是头节点
    if(mm->mmap == NULL){
        mm->mmap = vma;
        return vma->vm_start; // 注意此处要直接return，不然会和后面检查是否要插入到头节点前面的逻辑冲突，导致同一节点插入两次形成循环列表
    }

    // 遍历链表
    struct vm_area_struct *curr = mm->mmap;
    struct vm_area_struct *prev = NULL;
    while(curr != NULL){
        if(vm_start < curr->vm_end && vm_end > curr->vm_start){
            Err("[Overlap] [%lx, %lx) overlapped with [%lx, %lx)\n", vm_start, vm_end, curr->vm_start, curr->vm_end);
            kfree(vma);
            return 0;
        }
        if(vm_end <= curr->vm_start){
            break;
        }
        prev = curr;
        curr = curr->vm_next;
    }

    // 如果prev为空，说明curr为空直接没进入循环或者要插入到头节点前面，而前者已经在上面处理过了
    if(prev == NULL){
        vma->vm_next = mm->mmap;
        mm->mmap->vm_prev = vma;
        mm->mmap = vma;
    }
    else{
        vma->vm_prev = prev;
        vma->vm_next = prev->vm_next;
        prev->vm_next = vma;
        if(vma->vm_next != NULL){
            vma->vm_next->vm_prev = vma;
        }
    }
    // printk("VMA set: [%lx, %lx) with flags %lx\n", vma->vm_start, vma->vm_end, vma->vm_flags);
    // printk("vm_pgoff = %lx, vm_filesz = %lx, vm_next = %lx, vm_prev = %lx\n", vma->vm_pgoff, vma->vm_filesz, vma->vm_next, vma->vm_prev);
    return vma->vm_start;
}


void task_init() {
    srand(2024);

    // 1. 调用 kalloc() 为 idle 分配一个物理页
    // 2. 设置 state 为 TASK_RUNNING;
    // 3. 由于 idle 不参与调度，可以将其 counter / priority 设置为 0
    // 4. 设置 idle 的 pid 为 0
    // 5. 将 current 和 task[0] 指向 idle
    idle = (struct task_struct *)kalloc();
    idle->state = TASK_RUNNING;
    idle->counter = 0;
    idle->priority = 0;
    idle->pid = 0;
    current = idle;
    task[0] = idle;

    // 为 task[1] ~ task[nr_tasks - 1] 进行初始化

    /* YOUR CODE HERE */
    for(int i = 1; i < nr_tasks; i++){
        struct task_struct *temp = (struct task_struct *)kalloc();
        temp->pid = i;
        temp->state = TASK_RUNNING;
        temp->counter = 0;
        temp->priority = rand() % (PRIORITY_MAX - PRIORITY_MIN + 1) + PRIORITY_MIN;     //每日tip积累：生成n-m的随机数——>rand()%(m-n+1)+n
        temp->thread.ra = (uint64_t)__dummy;
        // 设置用户态进程的内核态栈 
        temp->kernel_stack = (uint64_t)temp + PGSIZE;
        temp->thread.sp = temp->kernel_stack;
        
        /* --- 初始化thread_struct中的三个CSR变量值 --- */
        // 2. 配置 sstatus 中的 SPP（使得 sret 返回至 U-Mode）、SUM（S-Mode 可以访问 User 页面）
        temp->thread.sstatus = csr_read(sstatus);
        temp->thread.sstatus &= ~(1 << 8); // SPP = 0
        temp->thread.sstatus |= (1 << 5); // SPIE = 1
        temp->thread.sstatus |= (1 << 18); // SUM = 1

        // 3. 将 sscratch 设置为 U-Mode 的 sp，其值为 USER_END （将用户态栈放置在 user space 的最后一个页面）
        temp->thread.sscratch = USER_END;

        // mmap初始化
        temp->mm.mmap = NULL;

        /* --- 对于每个进程，创建属于它自己的页表 --- */
        // 1. 将swapper_pg_dir复制到每个进程的页表中
        temp->pgd = (uint64_t *)kalloc();
        memcpy(temp->pgd, swapper_pg_dir, PGSIZE);

        // 2. 将uapp加载进内存
        Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
        Elf64_Phdr *phdrs = (Elf64_Phdr *)(_sramdisk + ehdr->e_phoff);
        // Log("Loading ELF program for task PID %d\n", temp->pid);
        // Log("%d segments to be loaded\n", ehdr->e_phnum);
        for (int i = 0; i < ehdr->e_phnum; ++i) {
            Log("do mapping for program segment %d\n", i);
            Elf64_Phdr *phdr = phdrs + i;
            printk("  Segment %d: type=%lu (PT_LOAD=%lu)\n", i, phdr->p_type, PT_LOAD);
            if (phdr->p_type == PT_LOAD) {
                uint64_t perm = 0;
                if(phdr->p_flags & PF_R){
                    perm |= VM_READ;
                }
                if(phdr->p_flags & PF_W){
                    perm |= VM_WRITE;
                }
                if(phdr->p_flags & PF_X){
                    perm |= VM_EXEC;
                }
                // printk("elf header: phdr->p_vaddr = %lx, phdr->p_memsz = %lx, phdr->p_offset = %lx, phdr->p_filesz = %lx", phdr->p_vaddr, phdr->p_memsz, phdr->p_offset, phdr->p_filesz);
                uint64_t ret = do_mmap(&temp->mm, phdr->p_vaddr, phdr->p_memsz, phdr->p_offset, phdr->p_filesz, perm);
                if (ret == 0) {
                    Err("load_program: do_mmap failed for segment %d", i);
                }
            }
            // else if (phdr->p_type == PT_GNU_STACK) {
            //     printk("    -> This is a GNU_STACK segment (ignore)\n");
            // } 
            // else if (phdr->p_type == PT_RISCV_ATTRIBUTES) {
            //     printk("    -> This is a RISCV_ATTRIBUTES segment (ignore)\n");
            // } 
            // else {
            //     printk("    -> Unknown segment type 0x%lx\n", phdr->p_type);
            // }
        }
        temp->thread.sepc = ehdr->e_entry;
        printk("Loaded ELF: entry=0x%lx, sepc set to 0x%lx\n", 
        ehdr->e_entry, temp->thread.sepc);

        /* --- 设置用户态栈 --- */
        do_mmap(&temp->mm, USER_END - PGSIZE, PGSIZE, 0, 0, VM_ANON | VM_READ | VM_WRITE);
        // 提前计算存储对应的satp，免去切换线程时计算的麻烦
        temp->satp = (csr_read(satp) >> 44) << 44;
        temp->satp |= ((uint64_t)(temp->pgd) - PA2VA_OFFSET) >> 12;
        task[i] = temp;
        // struct vm_area_struct* vma_iter = find_vma(&temp->mm, USER_END - 10);
        // if(vma_iter != NULL){
        //     printk("VMA for USER_END - 10: [%lx, %lx) with flags %lx\n", vma_iter->vm_start, vma_iter->vm_end, vma_iter->vm_flags);
        //     printk("vm_pgoff = %lx, vm_filesz = %lx, vm_next = %lx, vm_prev = %lx\n", vma_iter->vm_pgoff, vma_iter->vm_filesz, vma_iter->vm_next, vma_iter->vm_prev);
        // }
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
    for(int i = 0; i < nr_tasks; i++){
        if(task[i]->counter != 0){
            all_zero = false;
            break;
        }
    }
    if(all_zero){
        for(int i = 0; i < nr_tasks; i++){
            task[i]->counter = task[i]->priority;
            printk("SET [PID = %d PRIORITY = %d COUNTER = %d]\n", task[i]->pid, task[i]->priority, task[i]->counter);
        }
    }
    // 调度时选择 counter 最大的线程运行
    next = task[0];
    for(int i = 1; i < nr_tasks; i++){
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