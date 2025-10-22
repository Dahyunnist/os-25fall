// #include "sbi.h"
// #include "printk.h"
// #include "defs.h"

// void test() {
//         uint64_t test_val = 0x00005685;
//         csr_write(sscratch, test_val);
//         uint64_t sscratch_val = csr_read(sscratch);
//         printk("sscratch = 0x%llx\n", sscratch_val);
//         sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
//         __builtin_unreachable();
//     }
#include "printk.h"

void test() {
    int i = 0;
    while (1) {
        if ((++i) % 100000000 == 0) {
            printk("kernel is running!\n");
            i = 0;
        }
    }
}