#ifndef __DEFS_H__
#define __DEFS_H__

#ifndef __ASSEMBLER__
#include "stdint.h"

#define csr_read(csr)                   \
  ({                                    \
    uint64_t __v;                       \
    asm volatile("csrr %0, " #csr: "=r"(__v)::"memory");\
    __v;                                \
  })

#define csr_write(csr, val)                                    \
  ({                                                           \
    uint64_t __v = (uint64_t)(val);                            \
    asm volatile("csrw " #csr ", %0" : : "r"(__v) : "memory"); \
  })
#endif

#define PHY_START 0x0000000080000000
#define PHY_SIZE 128 * 1024 * 1024 // 128 MiB，QEMU 默认内存大小
#define PHY_END (PHY_START + PHY_SIZE)

#define PGSIZE 0x1000 // 4 KiB
#define PGROUNDUP(addr) ((addr + PGSIZE - 1) & (~(PGSIZE - 1)))
#define PGROUNDDOWN(addr) (addr & (~(PGSIZE - 1)))

#define OPENSBI_SIZE (0x200000)

#define VM_START (0xffffffe000000000)
#define VM_END (0xffffffff00000000)
#define VM_SIZE (VM_END - VM_START)

#define PA2VA_OFFSET (VM_START - PHY_START)

#define USER_START (0x0000000000000000) // user space start virtual address
#define USER_END (0x0000004000000000) // user space end virtual address

// 取虚拟页号VPN[0-2]
#define VPN0(va) (((uint64_t)(va) >> 12) & 0x1ff)
#define VPN1(va) (((uint64_t)(va) >> 21) & 0x1ff)
#define VPN2(va) (((uint64_t)(va) >> 30) & 0x1ff)
// PTE转换为物理地址
#define PHY(pte) (((uint64_t)(pte) >> 10) << 12)
// 物理地址转换为PPN，而后可与权限位组合成PTE
#define PPN(phy) (((uint64_t)(phy) >> 12) << 10)
// PTE权限位
#define PTE_V (1L << 0)
#define PTE_R (1L << 1)
#define PTE_W (1L << 2)
#define PTE_X (1L << 3)
#define PTE_U (1L << 4)
#define PTE_G (1L << 5)
#define PTE_A (1L << 6)
#define PTE_D (1L << 7)

// vm_flag
#define VM_ANON 0x1
#define VM_READ 0x2
#define VM_WRITE 0x4
#define VM_EXEC 0x8

// system call
#define SYS_WRITE 64
#define SYS_GETPID 172
#define SYS_CLONE 220

// page fault
#define PF_INSTRUCTION_PAGE_FAULT 0x000000000000000c
#define PF_LOAD_PAGE_FAULT 0x000000000000000d
#define PF_STORE_PAGE_FAULT 0x000000000000000f


// debug
#define RED "\033[31m"
#define GREEN "\033[32m"
#define YELLOW "\033[33m"
#define BLUE "\033[34m"
#define PURPLE "\033[35m"
#define DEEPGREEN "\033[36m"
#define CLEAR "\033[0m"

#define Log(format, ...) \
    printk("\33[1;35m[%s,%d,%s] " format "\33[0m\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__)

#define Err(format, ...) {                              \
    printk("\33[1;31m[%s,%d,%s] " format "\33[0m\n",    \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__);  \
    while(1);                                           \
}

#endif

