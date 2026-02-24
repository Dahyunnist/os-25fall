#ifndef __VM_H__
#define __VM_H__

#include "defs.h"
#include "stdint.h"
#include "printk.h"
#include "mm.h"
#include <string.h>

/* early_pgtbl: 用于 setup_vm 进行 1GiB 的映射 */
extern uint64_t early_pgtbl[512] __attribute__((__aligned__(0x1000)));

void setup_vm();

/* swapper_pg_dir: kernel pagetable 根目录，在 setup_vm_final 进行映射 */
extern uint64_t swapper_pg_dir[512] __attribute__((__aligned__(0x1000)));


void setup_vm_final();
void create_mapping(uint64_t *pgtbl, uint64_t va, uint64_t pa, uint64_t sz, uint64_t perm);

#endif