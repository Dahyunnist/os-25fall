#include "defs.h"
#include "stdint.h"
#include "printk.h"
#include "mm.h"
#include <string.h>

/* early_pgtbl: 用于 setup_vm 进行 1GiB 的映射 */
uint64_t early_pgtbl[512] __attribute__((__aligned__(0x1000)));

void setup_vm() {
    /* 
     * 1. 由于是进行 1GiB 的映射，这里不需要使用多级页表 
     * 2. 将 va 的 64bit 作为如下划分： | high bit | 9 bit | 30 bit |
     *     high bit 可以忽略
     *     中间 9 bit 作为 early_pgtbl 的 index
     *     低 30 bit 作为页内偏移，这里注意到 30 = 9 + 9 + 12，即我们只使用根页表，根页表的每个 entry 都对应 1GiB 的区域
     * 3. Page Table Entry 的权限 V | R | W | X 位设置为 1
    **/
    memset(early_pgtbl, 0x0, PGSIZE);
    uint64_t pte = ((PHY_START >> 30) << 28) | 0xF;
    int physical_index = (PHY_START >> 30) & 0x1FF;
    int virtual_index = (VM_START >> 30) & 0x1FF;
    early_pgtbl[physical_index] = pte;
    early_pgtbl[virtual_index] = pte;
}

/* swapper_pg_dir: kernel pagetable 根目录，在 setup_vm_final 进行映射 */
uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));

extern char _stext[], _etext[];
extern char _srodata[], _erodata[];
extern char _sdata[], _edata[];
extern char _sbss[], _ebss[];

void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

void setup_vm_final() {
    memset(swapper_pg_dir, 0x0, PGSIZE);

    // No OpenSBI mapping required
    uint64_t pa = PHY_START + OPENSBI_SIZE;

    // mapping kernel text X|-|R|V
    create_mapping(swapper_pg_dir, (uint64_t)_stext, pa, _srodata - _stext, PTE_X | PTE_R | PTE_V);

    // mapping kernel rodata -|-|R|V
    pa += _srodata - _stext;
    create_mapping(swapper_pg_dir, (uint64_t)_srodata, pa, _sdata - _srodata, PTE_R | PTE_V);

    // mapping other memory -|W|R|V
    pa += _sdata - _srodata;
    create_mapping(swapper_pg_dir, (uint64_t)_sdata, pa, PHY_SIZE - (_sdata - _stext), PTE_W | PTE_R | PTE_V);

    // set satp with swapper_pg_dir
    // YOUR CODE HERE
    // 借用了head.S中设置satp的代码，但其实用csr_write函数更简单些
    // 内联汇编无法识别c文件的宏，所以使用mv而不是li来载入PA2VA_OFFSET
    asm volatile(
        "li t1, 8\n"
        "slli t1, t1, 60\n"
        "la t2, swapper_pg_dir\n"
        "mv t3, %[arg0]\n"
        "sub t2, t2, t3\n"
        "srli t2, t2, 12\n"
        "or t1, t1, t2\n"
        "csrw satp, t1\n"
        :
        : [arg0] "r" (PA2VA_OFFSET)
        : "t1", "t2", "t3", "memory"
    );
    // flush TLB
    asm volatile("sfence.vma zero, zero");

    return;
}


/* 创建多级页表映射关系 */
/* 不要修改该接口的参数和返回值 */
void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm) {
    /*
     * pgtbl 为根页表的基地址
     * va, pa 为需要映射的虚拟地址、物理地址
     * sz 为映射的大小，单位为字节
     * perm 为映射的权限（即页表项的低 8 位）
     * 
     * 创建多级页表的时候可以使用 kalloc() 来获取一页作为页表目录
     * 可以使用 V bit 来判断页表项是否存在
    **/
    Log("root: %lx, mapping [%lx, %lx) to [%lx, %lx), perm: %x", pgtbl, va, va+sz, pa, pa+sz, perm);
    uint64_t va_end = va + sz;
    uint64_t *cur_tbl, cur_vpn0, cur_vpn1, cur_vpn2, cur_pte;
    // 从va开始一页一页分配，直到到达va末为止
    for(uint64_t cur_va = va, cur_pa = pa; cur_va < va_end; cur_va += PGSIZE, cur_pa += PGSIZE){
        cur_vpn0 = VPN0(cur_va);
        cur_vpn1 = VPN1(cur_va);
        cur_vpn2 = VPN2(cur_va);
        // 先从根页表查，看vpn[2]对应的页是否有效，无效则分配新页作为二级页表
        cur_tbl = pgtbl;
        cur_pte = *(cur_tbl + cur_vpn2);
        if(!(cur_pte & PTE_V)){
            uint64_t new_page_phy = (uint64_t)kalloc() - PA2VA_OFFSET;
            cur_pte = PPN(new_page_phy) | PTE_V;
            *(cur_tbl + cur_vpn2) = cur_pte;
        }
        // 第二级，查看vpn[1]对应的页是否有效，无效则分配一个新页作为三级页表
        cur_tbl = (uint64_t*)(PHY(cur_pte) + PA2VA_OFFSET);
        cur_pte = *(cur_tbl + cur_vpn1);
        if(!(cur_pte & PTE_V)){
            uint64_t new_page_phy = (uint64_t)kalloc() - PA2VA_OFFSET;
            cur_pte = PPN(new_page_phy) | PTE_V;
            *(cur_tbl + cur_vpn1) = cur_pte;
        }
        // 第三级页表指向具体的数据页，把pa转换成pte放进vpn[0]即可
        cur_tbl = (uint64_t*)(PHY(cur_pte) + PA2VA_OFFSET);
        cur_pte = PPN(cur_pa) | PTE_V | perm;
        *(cur_tbl + cur_vpn0) = cur_pte;
    }
}