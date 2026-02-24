#include "stdint.h"
#include "clock.h"
#include "printk.h"
#include "proc.h"
#include "defs.h"

struct pt_regs {
    uint64_t zero;      // x0
    uint64_t ra;        // x1
    uint64_t sp;        // x2
    uint64_t gp;        // x3
    uint64_t tp;        // x4
    uint64_t t0;        // x5
    uint64_t t1;        // x6
    uint64_t t2;        // x7
    uint64_t s0;        // x8
    uint64_t s1;        // x9
    uint64_t a0;        // x10  <-- 系统调用返回值
    uint64_t a1;        // x11
    uint64_t a2;        // x12
    uint64_t a3;        // x13
    uint64_t a4;        // x14
    uint64_t a5;        // x15
    uint64_t a6;        // x16  <-- 系统调用号
    uint64_t a7;        // x17
    uint64_t s2;        // x18
    uint64_t s3;        // x19
    uint64_t s4;        // x20
    uint64_t s5;        // x21
    uint64_t s6;        // x22
    uint64_t s7;        // x23
    uint64_t s8;        // x24
    uint64_t s9;        // x25
    uint64_t s10;       // x26
    uint64_t s11;       // x27
    uint64_t t3;        // x28
    uint64_t t4;        // x29
    uint64_t t5;        // x30
    uint64_t t6;        // x31
    uint64_t sepc;
    uint64_t sstatus;
};

// 64 号系统调用 `#!c sys_write(unsigned int fd, const char* buf, size_t count)` 该调用将用户态传递的字符串打印到屏幕上，此处 `fd` 为标准输出即 `1`，`buf` 为用户需要打印的起始地址，`count` 为字符串长度，返回打印的字符数；
// 172 号系统调用 `sys_getpid()` 该调用从 `current` 中获取当前的 pid 放入 a0 中返回，无参数
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
    else{
        printk("syscall %d not supported yet", regs->a7);
    }
    // 需要手动给sepc加4，不然返回后还是执行同一条ecall，循环不停
    regs->sepc += 4;
}

void trap_handler(uint64_t scause, uint64_t sepc, struct pt_regs *regs) {
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
            printk("[S] Supervisor software Interrupt(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }
        else if(scause == 0x8000000000000009){
            printk("[S] Supervisor external Interrupt(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }   
        else if(scause == 0x800000000000000D){
            printk("[S] Counter-overflow Interrupt(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }
        else{
            printk("[S] Other interruptions(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }
    }
    else{  // Exception
        if(scause == 0x0000000000000002){
            printk("[S] Illegal instruction(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }
        else if(scause == 0x0000000000000008){
            Log("[S] Environment Call from U-mode\n");
            syscall(regs);
            // return;
        }
        else{
            printk("[S] Other exceptions(Not handled yet)\n");
            printk("scause = %lx, sepc = %llx\n", scause, sepc);
        }
    }
    
}
