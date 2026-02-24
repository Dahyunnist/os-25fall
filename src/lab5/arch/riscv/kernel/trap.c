#include "stdint.h"
#include "clock.h"
#include "printk.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"
#include "mm.h"
#include "vm.h"
#include "syscall.h"
#include "trap.h"
#include <string.h>

void do_page_fault(struct pt_regs *regs) {
    // 捕获异常
    uint64_t sepc = regs->sepc;
    uint64_t bad_addr = regs->stval;
    Log("bad address = %llx, sepc = %llx\n", bad_addr, sepc);
    uint64_t scause = regs->scause;
   
    // 寻找当前 task 中导致产生了异常的地址对应的 VMA
    struct vm_area_struct *vma = find_vma(&current->mm, bad_addr);

    // 如果当前访问的虚拟地址在 VMA 中没有记录，即是不合法的地址，则运行出错（本实验不涉及）
    if(vma == NULL){
        Err("Illegal Address: Page fault at address %llx not in any VMA\n", bad_addr);
        return;
    }

    // 根据 vma 的 flags 权限判断当前 page fault 是否合法
    if(scause == PF_INSTRUCTION_PAGE_FAULT && !(vma->vm_flags & VM_EXEC)){
        Err("Permission Error: Instruction Page Fault at address %llx without EXEC permission\n", bad_addr);
        return;
    }
    if(scause == PF_LOAD_PAGE_FAULT && !(vma->vm_flags & VM_READ)){
        Err("Permission Error: Load Page Fault at address %llx without READ permission\n", bad_addr);
        return;
    }
    if(scause == PF_STORE_PAGE_FAULT && !(vma->vm_flags & VM_WRITE)){
        Err("Permission Error: Store Page Fault at address %llx without WRITE permission\n", bad_addr);
        return;
    }

    // 分配一个页，接下来要将这个页映射到对应的用户地址空间
    char *mem_page = alloc_page();
    memset(mem_page, 0, PGSIZE);

    // 准备好权限位
    uint64_t perm = PTE_V | PTE_U | PTE_A | PTE_D;
    if(vma->vm_flags & VM_READ){
        perm |= PTE_R;
    }
    if(vma->vm_flags & VM_WRITE){
        perm |= PTE_W;
    }
    if(vma->vm_flags & VM_EXEC){
        perm |= PTE_X;
    }

    uint64_t va_start = PGROUNDDOWN(bad_addr);
    uint64_t pa_start = (uint64_t)mem_page - PA2VA_OFFSET;
    // 通过 (vma->vm_flags & VM_ANON) 获得当前的 VMA 是否是匿名空间
    // 如果是匿名空间，则直接映射即可
    // 如果不是，则需要根据 vma->vm_pgoff 等信息从 ELF 中读取数据，填充后映射到用户空间
    if(!(vma->vm_flags & VM_ANON)){
        Elf64_Ehdr *ehdr = (Elf64_Ehdr *)_sramdisk;
        
        // 应进行文件数据复制的范围：
        // 地址bad_addr对齐后分配的一整页区域 —— [va_start, va_start + PGSIZE)
        // 和文件数据区 —— [vma->vm_start, vma->vm_start + vma->vm_filesz) 的交集，否则直接置0
        uint64_t copy_area_start = max(va_start, vma->vm_start);
        uint64_t copy_area_end = min(va_start + PGSIZE, vma->vm_start + vma->vm_filesz);
        if(copy_area_start < copy_area_end){
            uint64_t file_offset = (copy_area_start - vma->vm_start) + vma->vm_pgoff;
            uint64_t page_offset = copy_area_start - va_start;
            uint64_t copy_size = copy_area_end - copy_area_start;
            memcpy(mem_page + page_offset, (char *)ehdr + file_offset, copy_size);
        }
    }

    create_mapping(current->pgd, va_start, pa_start, PGSIZE, perm);

    // 返回到产生了该缺页异常的那条指令，并继续执行程序
    asm volatile("sfence.vma zero, zero");
}

void trap_handler(uint64_t scause, uint64_t sepc, struct pt_regs *regs, uint64_t stval){
    // 通过 `scause` 判断 trap 类型
    // 如果是 interrupt 判断是否是 timer interrupt
    // 如果是 timer interrupt 则打印输出相关信息，并通过 `clock_set_next_event()` 设置下一次时钟中断
    // `clock_set_next_event()` 见 4.3.4 节
    // 其他 interrupt / exception 可以直接忽略，推荐打印出来供以后调试
    if(scause & 0x8000000000000000){  // Interrupt

        if(scause == 0x8000000000000005){ // timer interrupt
            // printk("[S] Supervisor Mode Timer Interrupt\n");
            clock_set_next_event();
            do_timer();
        }
        else if(scause == 0x8000000000000001){
            Log("[S] Supervisor software Interrupt(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }
        else if(scause == 0x8000000000000009){
            Log("[S] Supervisor external Interrupt(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }   
        else if(scause == 0x800000000000000D){
            Log("[S] Counter-overflow Interrupt(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }
        else{
            Log("[S] Other interruptions(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }
    }
    else{  // Exception
        if(scause == 0x0000000000000002){
            Log("[S] Illegal instruction(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }
        else if(scause == 0x0000000000000008){
            // printk("[S] Environment Call from U-mode\n");
            syscall(regs);
            // return;
        }
        else if(scause == 0x000000000000000c){
            Log("[S] Instruction Page Fault scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
            do_page_fault(regs);
        }
        else if(scause == 0x000000000000000d){
            Log("[S] Load Page Fault scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
            do_page_fault(regs);
        }
        else if(scause == 0x000000000000000f){
            Log("[S] Store/AMO Page Fault scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
            do_page_fault(regs);
        }
        else{
            Log("[S] Other exceptions(Not handled yet) scause = %lx, sepc = %llx, stval = %llx\n", scause, sepc, stval);
        }
    }
    
}


void test_print(uint64_t sp){
    printk("Ready to return! pid = %d, sp = %lx\n", current->pid, sp);
}

