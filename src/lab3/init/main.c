#include "printk.h"
#include "proc.h"

extern void test();

int start_kernel() {
    printk("2024");
    printk(" ZJU Operating System\n");
    int i = 0;
    while(1){
        i++;
    }
    printk("%d", i);
    return 0;
}
