#include "mm.h"
#include "defs.h"
#include "proc.h"
#include "stdlib.h"
#include "printk.h"

extern void __dummy();
extern void __switch_to(struct task_struct *prev, struct task_struct *next);

struct task_struct *idle;           // idle process
struct task_struct *current;        // 指向当前运行线程的 task_struct
struct task_struct *task[NR_TASKS]; // 线程数组，所有的线程都保存在此

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
        temp->thread.sp = (uint64_t)temp + PGSIZE;
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
            if (current->counter == 1) {
                --(current->counter);   // forced the counter to be zero if this thread is going to be scheduled
            }                           // in case that the new counter is also 1, leading the information not printed.
            last_counter = current->counter;
            auto_inc_local_var = (auto_inc_local_var + 1) % MOD;
            printk("[PID = %d] is running. auto_inc_local_var = %d\n", current->pid, auto_inc_local_var);
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