#include "printk.h"

extern void test();

int start_kernel() {
    printk("2024");
    printk(" ZJU Operating System\n");
    // sbi_debug_console_write_byte('@');
    // sbi_system_reset(0, 0);
    test();
    return 0;
}
