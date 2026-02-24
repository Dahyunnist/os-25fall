#include "syscall.h"
#include "proc.h"
#include "printk.h"
#include "mm.h"
#include "defs.h"
#include <string.h>
#include <stdlib.h>
#include "vm.h"

extern void __ret_from_fork();

uint64_t do_fork(struct pt_regs *regs){
    // 创建一个新进程
    struct task_struct *_task = (struct task_struct*)kalloc();
    
    /* --- 拷贝内核栈 --- */
    // 关于子进程的所有信息都要在深拷贝之后再进行赋值，因为深拷贝之后，拷贝来的父进程信息会把前面的操作都覆盖掉
    // 深拷贝整个页
    memcpy((void*)_task, (void*)current, PGSIZE);
    _task->kernel_stack = (uint64_t)_task + PGSIZE;
    _task->pid = nr_tasks;  
    _task->pgd = (uint64_t *)kalloc();
    _task->mm.mmap = NULL; 
    // 计算子进程的pt_regs位置（在内核栈上，和父进程一样的位置）
    uint64_t pt_regs_offset = (uint64_t)regs - (uint64_t)current;
    struct pt_regs *child_regs = (uint64_t)_task + (uint64_t)pt_regs_offset;
    // printk("current = %llx, regs = %llx, _task = %llx, pt_regs_offset = %llx, _task + pt_regs_offset = %llx, child_regs = %llx\n", (uint64_t)current, (uint64_t)regs, (uint64_t)_task, pt_regs_offset, (uint64_t)_task + pt_regs_offset, (uint64_t)child_regs);
    // printk("regs->a6 = %llx, child_regs->a6 = %llx\n", regs->a6, child_regs->a6);


    /* --- 创建子进程页表 --- */
    // 拷贝内核页表 swapper_pg_dir
    memcpy(_task->pgd, swapper_pg_dir, PGSIZE);
    _task->satp = (csr_read(satp) >> 44) << 44;
    _task->satp |= ((uint64_t)(_task->pgd) - PA2VA_OFFSET) >> 12;

    // 遍历父进程 vma，并遍历父进程页表
    // 将这个 vma 也添加到新进程的 vma 链表中
    // 如果该 vma 项有对应的页表项存在（说明已经创建了映射），则需要深拷贝一整页的内容并映射到新页表中
    struct vm_area_struct *vma = current->mm.mmap;
    while(vma != NULL){
        // 把vma添加到新进程的vma链表中
        do_mmap(&_task->mm, vma->vm_start, vma->vm_end - vma->vm_start, vma->vm_pgoff, vma->vm_filesz, vma->vm_flags);
        // 从vma的开始地址开始一页一页检查，直到到达vma的结束地址为止
        uint64_t va_start = PGROUNDDOWN(vma->vm_start);
        uint64_t va_end = PGROUNDUP(vma->vm_end);
        uint64_t *cur_tbl, cur_vpn0, cur_vpn1, cur_vpn2, cur_pte;
        // 从va开始一页一页检查，直到到达va末为止
        for(uint64_t cur_va = va_start; cur_va < va_end; cur_va += PGSIZE){
            cur_vpn0 = VPN0(cur_va);
            cur_vpn1 = VPN1(cur_va);
            cur_vpn2 = VPN2(cur_va);
            // 先从父进程的根页表查，看vpn[2]对应的页是否有效，无效则遍历下一页
            cur_tbl = current->pgd;
            if(cur_tbl == NULL){
                continue;  // 安全检查：如果页表为空，跳过
            }
            cur_pte = *(cur_tbl + cur_vpn2);
            if(!(cur_pte & PTE_V)){
                continue;
            }
            // 第二级，查看vpn[1]对应的页是否有效，无效则遍历下一页
            cur_tbl = (uint64_t*)(PHY(cur_pte) + PA2VA_OFFSET);
            cur_pte = *(cur_tbl + cur_vpn1);
            if(!(cur_pte & PTE_V)){
                continue;
            }
            // 第三级页表指向具体的数据页
            cur_tbl = (uint64_t*)(PHY(cur_pte) + PA2VA_OFFSET);
            cur_pte = *(cur_tbl + cur_vpn0);
            if(cur_pte & PTE_V){
                uint64_t pa = PHY(cur_pte);  // 从 PTE 中提取物理地址
                uint64_t kva = pa + PA2VA_OFFSET;  // 转换为内核虚拟地址
                
                // 分配新页并拷贝内容
                char *mem_page = alloc_page();
                memcpy(mem_page, (void*)kva, PGSIZE);  
                uint64_t perm = cur_pte & 0xFF;
                create_mapping(_task->pgd, cur_va, (uint64_t)mem_page - PA2VA_OFFSET, PGSIZE, perm);
            }
        }
        vma = vma->vm_next;
    }

    // 处理子进程返回逻辑：父进程处理完fork回到哪里子进程就回到哪里
    _task->thread.ra = (uint64_t)__ret_from_fork;

    // 把child_regs放在thread.sp，经__switch_to传给sp, 然后来到__ret_from_fork，执行和父进程一样的恢复pt_regs值操作
    _task->thread.sp = (uint64_t)child_regs;
    // 用户栈指针放在thread.sscratch里面，经__switch_to传给sscratch，再经__ret_from_fork换给sp，回到用户态执行
    _task->thread.sscratch = csr_read(sscratch);
    // 内核栈指针放在child_regs->sp里面，经__ret_from_fork赋给sp，再交换到sscratch里面
    // 不是把regs->sp赋给child_regs->sp，因为regs->sp是父进程的内核栈指针，需要自己计算子进程的内核栈指针
    child_regs->sp = _task->kernel_stack;

    // 处理子进程返回值
    child_regs->a0 = 0;  // 子进程返回 0
    child_regs->sepc += 4;  // 跳过 ecall 指令

    task[nr_tasks] = _task;
    nr_tasks++;

    printk("[FORK] [PID = %d] forked from [PID = %d]\n", _task->pid, current->pid);

    return _task->pid;
}


// 64 号系统调用 `#!c sys_write(unsigned int fd, const char* buf, size_t count)` 该调用将用户态传递的字符串打印到屏幕上，此处 `fd` 为标准输出即 `1`，`buf` 为用户需要打印的起始地址，`count` 为字符串长度，返回打印的字符数；
// 172 号系统调用 `sys_getpid()` 该调用从 `current` 中获取当前的 pid 放入 a0 中返回，无参数
// 220 号系统调用 `sys_fork()` 该调用创建一个新进程，返回新进程的 pid
void syscall(struct pt_regs *regs){
    if(regs->a7 == SYS_WRITE){
        // 3个参数：fd 为标准输出即 1，buf 为用户需要打印的起始地址，count 为字符串长度
        if(regs->a0 == 1){
            char *buf = (char *)regs->a1;
            for(int i = 0; i < regs->a2; i++){
                printk("%c", buf[i]);
            }
            // 返回打印的字符数
            regs->a0 = regs->a2;
        }
        else{
            printk("SYS_WRITE with fd = %d not supported yet\n", regs->a0);
        }
    }
    else if(regs->a7 == SYS_GETPID){
        regs->a0 = current->pid;
    }
    else if(regs->a7 == SYS_CLONE){
        regs->a0 = do_fork(regs);
    }
    else{
        printk("syscall %d not supported yet", regs->a7);
    }
    // 需要手动给sepc加4，不然返回后还是执行同一条ecall，循环不停
    regs->sepc += 4;
}