#include "stdint.h"
#include "clock.h"
#include "printk.h"
#include "proc.h"

void trap_handler(uint64_t scause, uint64_t sepc) {
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
        }
        else if(scause == 0x8000000000000009){
            printk("[S] Supervisor external Interrupt(Not handled yet)\n");
        }
        else if(scause == 0x800000000000000D){
            printk("[S] Counter-overflow Interrupt(Not handled yet)\n");
        }
        else{
            printk("[S] Other interruptions(Not handled yet)\n");
        }
    }
    else{  // Exception
        if(scause == 0x0000000000000002){
            printk("[S] Illegal instruction(Not handled yet)\n");
        }
        else{
            printk("[S] Other exceptions(Not handled yet)\n");
        }
    }
    
}