#ifndef __SYSCALL_H__
#define __SYSCALL_H__

#include "stdint.h"
#include "trap.h"

uint64_t do_fork(struct pt_regs *regs);
void syscall(struct pt_regs *regs);

#endif