
../../vmlinux:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <_skernel>:
    .section .text.init
    .globl _start
_start:
    # 1. initialize stack
_init_stack:
    la sp, boot_stack_top
    80200000:	00003117          	auipc	sp,0x3
    80200004:	01013103          	ld	sp,16(sp) # 80203010 <_GLOBAL_OFFSET_TABLE_+0x8>

0000000080200008 <_init_csr>:

    # 2. initialize CSR
_init_csr:
    # set stvec = _traps
    la t0, _traps
    80200008:	00003297          	auipc	t0,0x3
    8020000c:	0102b283          	ld	t0,16(t0) # 80203018 <_GLOBAL_OFFSET_TABLE_+0x10>
    csrw stvec, t0
    80200010:	10529073          	csrw	stvec,t0
    # set sie[STIE] = 1
    li t1, (1 << 5)
    80200014:	02000313          	li	t1,32
    csrs sie, t1
    80200018:	10432073          	csrs	sie,t1

000000008020001c <_first_interrupt>:

    # 3. set first time interrupt
_first_interrupt:
    call clock_set_next_event
    8020001c:	164000ef          	jal	80200180 <clock_set_next_event>

0000000080200020 <_set_sstatus>:

    # 4. set sstatus[SIE] = 1
_set_sstatus:
    li t1, (1 << 1)
    80200020:	00200313          	li	t1,2
    csrs sstatus, t1
    80200024:	10032073          	csrs	sstatus,t1

0000000080200028 <_kernel_start>:
    
    # 5. jump to start_kernel
_kernel_start:
    j start_kernel
    80200028:	66c0006f          	j	80200694 <start_kernel>

000000008020002c <_traps>:
    .align 2
    .globl _traps
_traps:
    # 1. save 32 registers and spec to stack
_save_context:
    addi sp, sp, -264
    8020002c:	ef810113          	addi	sp,sp,-264
    sd x0, 0(sp)
    80200030:	00013023          	sd	zero,0(sp)
    sd x1, 8(sp)
    80200034:	00113423          	sd	ra,8(sp)
    sd x3, 24(sp)
    80200038:	00313c23          	sd	gp,24(sp)
    sd x4, 32(sp)
    8020003c:	02413023          	sd	tp,32(sp)
    sd x5, 40(sp)
    80200040:	02513423          	sd	t0,40(sp)
    sd x6, 48(sp)
    80200044:	02613823          	sd	t1,48(sp)
    sd x7, 56(sp)
    80200048:	02713c23          	sd	t2,56(sp)
    sd x8, 64(sp)
    8020004c:	04813023          	sd	s0,64(sp)
    sd x9, 72(sp)
    80200050:	04913423          	sd	s1,72(sp)
    sd x10, 80(sp)
    80200054:	04a13823          	sd	a0,80(sp)
    sd x11, 88(sp)
    80200058:	04b13c23          	sd	a1,88(sp)
    sd x12, 96(sp)
    8020005c:	06c13023          	sd	a2,96(sp)
    sd x13, 104(sp)
    80200060:	06d13423          	sd	a3,104(sp)
    sd x14, 112(sp)
    80200064:	06e13823          	sd	a4,112(sp)
    sd x15, 120(sp)
    80200068:	06f13c23          	sd	a5,120(sp)
    sd x16, 128(sp)
    8020006c:	09013023          	sd	a6,128(sp)
    sd x17, 136(sp)
    80200070:	09113423          	sd	a7,136(sp)
    sd x18, 144(sp)
    80200074:	09213823          	sd	s2,144(sp)
    sd x19, 152(sp)
    80200078:	09313c23          	sd	s3,152(sp)
    sd x20, 160(sp)
    8020007c:	0b413023          	sd	s4,160(sp)
    sd x21, 168(sp)
    80200080:	0b513423          	sd	s5,168(sp)
    sd x22, 176(sp)
    80200084:	0b613823          	sd	s6,176(sp)
    sd x23, 184(sp)
    80200088:	0b713c23          	sd	s7,184(sp)
    sd x24, 192(sp)
    8020008c:	0d813023          	sd	s8,192(sp)
    sd x25, 200(sp)
    80200090:	0d913423          	sd	s9,200(sp)
    sd x26, 208(sp)
    80200094:	0da13823          	sd	s10,208(sp)
    sd x27, 216(sp)
    80200098:	0db13c23          	sd	s11,216(sp)
    sd x28, 224(sp)
    8020009c:	0fc13023          	sd	t3,224(sp)
    sd x29, 232(sp)
    802000a0:	0fd13423          	sd	t4,232(sp)
    sd x30, 240(sp)
    802000a4:	0fe13823          	sd	t5,240(sp)
    sd x31, 248(sp)
    802000a8:	0ff13c23          	sd	t6,248(sp)
    addi t0, sp, 264
    802000ac:	10810293          	addi	t0,sp,264
    sd t0, 16(sp)
    802000b0:	00513823          	sd	t0,16(sp)
    csrr t1, sepc
    802000b4:	14102373          	csrr	t1,sepc
    sd t1, 256(sp)
    802000b8:	10613023          	sd	t1,256(sp)

00000000802000bc <_call_handler>:

    # 2. call trap_handler
_call_handler:
    csrr a0, scause
    802000bc:	14202573          	csrr	a0,scause
    csrr a1, sepc
    802000c0:	141025f3          	csrr	a1,sepc
    call trap_handler
    802000c4:	4d0000ef          	jal	80200594 <trap_handler>

00000000802000c8 <_restore_context>:

    # 3. restore sepc and 32 registers (x2(sp) should be restore last) from stack
_restore_context:
    ld t1, 256(sp)
    802000c8:	10013303          	ld	t1,256(sp)
    csrw sepc, t1
    802000cc:	14131073          	csrw	sepc,t1
    ld x0, 0(sp)
    802000d0:	00013003          	ld	zero,0(sp)
    ld x1, 8(sp)
    802000d4:	00813083          	ld	ra,8(sp)
    ld x3, 24(sp)
    802000d8:	01813183          	ld	gp,24(sp)
    ld x4, 32(sp)
    802000dc:	02013203          	ld	tp,32(sp)
    ld x5, 40(sp)
    802000e0:	02813283          	ld	t0,40(sp)
    ld x6, 48(sp)
    802000e4:	03013303          	ld	t1,48(sp)
    ld x7, 56(sp)
    802000e8:	03813383          	ld	t2,56(sp)
    ld x8, 64(sp)
    802000ec:	04013403          	ld	s0,64(sp)
    ld x9, 72(sp)
    802000f0:	04813483          	ld	s1,72(sp)
    ld x10, 80(sp)
    802000f4:	05013503          	ld	a0,80(sp)
    ld x11, 88(sp)
    802000f8:	05813583          	ld	a1,88(sp)
    ld x12, 96(sp)
    802000fc:	06013603          	ld	a2,96(sp)
    ld x13, 104(sp)
    80200100:	06813683          	ld	a3,104(sp)
    ld x14, 112(sp)
    80200104:	07013703          	ld	a4,112(sp)
    ld x15, 120(sp)
    80200108:	07813783          	ld	a5,120(sp)
    ld x16, 128(sp)
    8020010c:	08013803          	ld	a6,128(sp)
    ld x17, 136(sp)
    80200110:	08813883          	ld	a7,136(sp)
    ld x18, 144(sp)
    80200114:	09013903          	ld	s2,144(sp)
    ld x19, 152(sp)
    80200118:	09813983          	ld	s3,152(sp)
    ld x20, 160(sp)
    8020011c:	0a013a03          	ld	s4,160(sp)
    ld x21, 168(sp)
    80200120:	0a813a83          	ld	s5,168(sp)
    ld x22, 176(sp)
    80200124:	0b013b03          	ld	s6,176(sp)
    ld x23, 184(sp)
    80200128:	0b813b83          	ld	s7,184(sp)
    ld x24, 192(sp)
    8020012c:	0c013c03          	ld	s8,192(sp)
    ld x25, 200(sp)
    80200130:	0c813c83          	ld	s9,200(sp)
    ld x26, 208(sp)
    80200134:	0d013d03          	ld	s10,208(sp)
    ld x27, 216(sp)
    80200138:	0d813d83          	ld	s11,216(sp)
    ld x28, 224(sp)
    8020013c:	0e013e03          	ld	t3,224(sp)
    ld x29, 232(sp)
    80200140:	0e813e83          	ld	t4,232(sp)
    ld x30, 240(sp)
    80200144:	0f013f03          	ld	t5,240(sp)
    ld x31, 248(sp)
    80200148:	0f813f83          	ld	t6,248(sp)
    ld x2, 16(sp)
    8020014c:	01013103          	ld	sp,16(sp)

0000000080200150 <_trap_return>:

    # 4. return from trap
_trap_return:
    sret
    80200150:	10200073          	sret

0000000080200154 <get_cycles>:
#include "sbi.h"

// QEMU 中时钟的频率是 10MHz，也就是 1 秒钟相当于 10000000 个时钟周期
uint64_t TIMECLOCK = 10000000;

uint64_t get_cycles() {
    80200154:	fe010113          	addi	sp,sp,-32
    80200158:	00813c23          	sd	s0,24(sp)
    8020015c:	02010413          	addi	s0,sp,32
    // 编写内联汇编，使用 rdtime 获取 time 寄存器中（也就是 mtime 寄存器）的值并返回
    uint64_t time = 0;
    80200160:	fe043423          	sd	zero,-24(s0)
    asm volatile(
    80200164:	c01027f3          	rdtime	a5
    80200168:	fef43423          	sd	a5,-24(s0)
        "rdtime %[time]\n"
        : [time] "=r" (time)
        :
        : "memory"
    );
    return time;
    8020016c:	fe843783          	ld	a5,-24(s0)
}
    80200170:	00078513          	mv	a0,a5
    80200174:	01813403          	ld	s0,24(sp)
    80200178:	02010113          	addi	sp,sp,32
    8020017c:	00008067          	ret

0000000080200180 <clock_set_next_event>:

void clock_set_next_event() {
    80200180:	fe010113          	addi	sp,sp,-32
    80200184:	00113c23          	sd	ra,24(sp)
    80200188:	00813823          	sd	s0,16(sp)
    8020018c:	02010413          	addi	s0,sp,32
    // 下一次时钟中断的时间点
    uint64_t next = get_cycles() + TIMECLOCK;
    80200190:	fc5ff0ef          	jal	80200154 <get_cycles>
    80200194:	00050713          	mv	a4,a0
    80200198:	00003797          	auipc	a5,0x3
    8020019c:	e6878793          	addi	a5,a5,-408 # 80203000 <TIMECLOCK>
    802001a0:	0007b783          	ld	a5,0(a5)
    802001a4:	00f707b3          	add	a5,a4,a5
    802001a8:	fef43423          	sd	a5,-24(s0)
    // 使用 sbi_set_timer 来完成对下一次时钟中断的设置
    sbi_set_timer(next);
    802001ac:	fe843503          	ld	a0,-24(s0)
    802001b0:	230000ef          	jal	802003e0 <sbi_set_timer>
    802001b4:	00000013          	nop
    802001b8:	01813083          	ld	ra,24(sp)
    802001bc:	01013403          	ld	s0,16(sp)
    802001c0:	02010113          	addi	sp,sp,32
    802001c4:	00008067          	ret

00000000802001c8 <sbi_ecall>:
#include "stdint.h"
#include "sbi.h"

struct sbiret sbi_ecall(uint64_t eid, uint64_t fid,
                        uint64_t arg0, uint64_t arg1, uint64_t arg2,
                        uint64_t arg3, uint64_t arg4, uint64_t arg5) {
    802001c8:	f7010113          	addi	sp,sp,-144
    802001cc:	08813423          	sd	s0,136(sp)
    802001d0:	08913023          	sd	s1,128(sp)
    802001d4:	07213c23          	sd	s2,120(sp)
    802001d8:	07313823          	sd	s3,112(sp)
    802001dc:	09010413          	addi	s0,sp,144
    802001e0:	faa43423          	sd	a0,-88(s0)
    802001e4:	fab43023          	sd	a1,-96(s0)
    802001e8:	f8c43c23          	sd	a2,-104(s0)
    802001ec:	f8d43823          	sd	a3,-112(s0)
    802001f0:	f8e43423          	sd	a4,-120(s0)
    802001f4:	f8f43023          	sd	a5,-128(s0)
    802001f8:	f7043c23          	sd	a6,-136(s0)
    802001fc:	f7143823          	sd	a7,-144(s0)
    struct sbiret res = {0, 0};
    80200200:	fa043823          	sd	zero,-80(s0)
    80200204:	fa043c23          	sd	zero,-72(s0)
    uint64_t error;
    uint64_t value;
    asm volatile(
    80200208:	fa843e03          	ld	t3,-88(s0)
    8020020c:	fa043e83          	ld	t4,-96(s0)
    80200210:	f9843f03          	ld	t5,-104(s0)
    80200214:	f9043f83          	ld	t6,-112(s0)
    80200218:	f8843283          	ld	t0,-120(s0)
    8020021c:	f8043483          	ld	s1,-128(s0)
    80200220:	f7843903          	ld	s2,-136(s0)
    80200224:	f7043983          	ld	s3,-144(s0)
    80200228:	000e0893          	mv	a7,t3
    8020022c:	000e8813          	mv	a6,t4
    80200230:	000f0513          	mv	a0,t5
    80200234:	000f8593          	mv	a1,t6
    80200238:	00028613          	mv	a2,t0
    8020023c:	00048693          	mv	a3,s1
    80200240:	00090713          	mv	a4,s2
    80200244:	00098793          	mv	a5,s3
    80200248:	00000073          	ecall

000000008020024c <_after_ecall>:
    8020024c:	00050e93          	mv	t4,a0
    80200250:	00058e13          	mv	t3,a1
    80200254:	fdd43c23          	sd	t4,-40(s0)
    80200258:	fdc43823          	sd	t3,-48(s0)
        "mv %[value], a1\n"
        : [error] "=r" (error), [value] "=r" (value)
        : [eid] "r" (eid), [fid] "r" (fid), [arg0] "r" (arg0), [arg1] "r" (arg1), [arg2] "r" (arg2), [arg3] "r" (arg3), [arg4] "r" (arg4), [arg5] "r" (arg5)
        : "memory", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7"
    );
    res.error = error;
    8020025c:	fd843783          	ld	a5,-40(s0)
    80200260:	faf43823          	sd	a5,-80(s0)
    res.value = value;
    80200264:	fd043783          	ld	a5,-48(s0)
    80200268:	faf43c23          	sd	a5,-72(s0)
    return res;
    8020026c:	fb043783          	ld	a5,-80(s0)
    80200270:	fcf43023          	sd	a5,-64(s0)
    80200274:	fb843783          	ld	a5,-72(s0)
    80200278:	fcf43423          	sd	a5,-56(s0)
    8020027c:	fc043703          	ld	a4,-64(s0)
    80200280:	fc843783          	ld	a5,-56(s0)
    80200284:	00070313          	mv	t1,a4
    80200288:	00078393          	mv	t2,a5
    8020028c:	00030713          	mv	a4,t1
    80200290:	00038793          	mv	a5,t2
}
    80200294:	00070513          	mv	a0,a4
    80200298:	00078593          	mv	a1,a5
    8020029c:	08813403          	ld	s0,136(sp)
    802002a0:	08013483          	ld	s1,128(sp)
    802002a4:	07813903          	ld	s2,120(sp)
    802002a8:	07013983          	ld	s3,112(sp)
    802002ac:	09010113          	addi	sp,sp,144
    802002b0:	00008067          	ret

00000000802002b4 <sbi_debug_console_write_byte>:

struct sbiret sbi_debug_console_write_byte(uint8_t byte) {
    802002b4:	fc010113          	addi	sp,sp,-64
    802002b8:	02113c23          	sd	ra,56(sp)
    802002bc:	02813823          	sd	s0,48(sp)
    802002c0:	03213423          	sd	s2,40(sp)
    802002c4:	03313023          	sd	s3,32(sp)
    802002c8:	04010413          	addi	s0,sp,64
    802002cc:	00050793          	mv	a5,a0
    802002d0:	fcf407a3          	sb	a5,-49(s0)
    return sbi_ecall(0x4442434E, 0x2, byte, 0, 0, 0, 0, 0);
    802002d4:	fcf44603          	lbu	a2,-49(s0)
    802002d8:	00000893          	li	a7,0
    802002dc:	00000813          	li	a6,0
    802002e0:	00000793          	li	a5,0
    802002e4:	00000713          	li	a4,0
    802002e8:	00000693          	li	a3,0
    802002ec:	00200593          	li	a1,2
    802002f0:	44424537          	lui	a0,0x44424
    802002f4:	34e50513          	addi	a0,a0,846 # 4442434e <_skernel-0x3bddbcb2>
    802002f8:	ed1ff0ef          	jal	802001c8 <sbi_ecall>
    802002fc:	00050713          	mv	a4,a0
    80200300:	00058793          	mv	a5,a1
    80200304:	fce43823          	sd	a4,-48(s0)
    80200308:	fcf43c23          	sd	a5,-40(s0)
    8020030c:	fd043703          	ld	a4,-48(s0)
    80200310:	fd843783          	ld	a5,-40(s0)
    80200314:	00070913          	mv	s2,a4
    80200318:	00078993          	mv	s3,a5
    8020031c:	00090713          	mv	a4,s2
    80200320:	00098793          	mv	a5,s3
}
    80200324:	00070513          	mv	a0,a4
    80200328:	00078593          	mv	a1,a5
    8020032c:	03813083          	ld	ra,56(sp)
    80200330:	03013403          	ld	s0,48(sp)
    80200334:	02813903          	ld	s2,40(sp)
    80200338:	02013983          	ld	s3,32(sp)
    8020033c:	04010113          	addi	sp,sp,64
    80200340:	00008067          	ret

0000000080200344 <sbi_system_reset>:

struct sbiret sbi_system_reset(uint32_t reset_type, uint32_t reset_reason) {
    80200344:	fc010113          	addi	sp,sp,-64
    80200348:	02113c23          	sd	ra,56(sp)
    8020034c:	02813823          	sd	s0,48(sp)
    80200350:	03213423          	sd	s2,40(sp)
    80200354:	03313023          	sd	s3,32(sp)
    80200358:	04010413          	addi	s0,sp,64
    8020035c:	00050793          	mv	a5,a0
    80200360:	00058713          	mv	a4,a1
    80200364:	fcf42623          	sw	a5,-52(s0)
    80200368:	00070793          	mv	a5,a4
    8020036c:	fcf42423          	sw	a5,-56(s0)
    return sbi_ecall(0x53525354, 0, reset_type, reset_reason, 0, 0, 0, 0);
    80200370:	fcc46603          	lwu	a2,-52(s0)
    80200374:	fc846683          	lwu	a3,-56(s0)
    80200378:	00000893          	li	a7,0
    8020037c:	00000813          	li	a6,0
    80200380:	00000793          	li	a5,0
    80200384:	00000713          	li	a4,0
    80200388:	00000593          	li	a1,0
    8020038c:	53525537          	lui	a0,0x53525
    80200390:	35450513          	addi	a0,a0,852 # 53525354 <_skernel-0x2ccdacac>
    80200394:	e35ff0ef          	jal	802001c8 <sbi_ecall>
    80200398:	00050713          	mv	a4,a0
    8020039c:	00058793          	mv	a5,a1
    802003a0:	fce43823          	sd	a4,-48(s0)
    802003a4:	fcf43c23          	sd	a5,-40(s0)
    802003a8:	fd043703          	ld	a4,-48(s0)
    802003ac:	fd843783          	ld	a5,-40(s0)
    802003b0:	00070913          	mv	s2,a4
    802003b4:	00078993          	mv	s3,a5
    802003b8:	00090713          	mv	a4,s2
    802003bc:	00098793          	mv	a5,s3
}
    802003c0:	00070513          	mv	a0,a4
    802003c4:	00078593          	mv	a1,a5
    802003c8:	03813083          	ld	ra,56(sp)
    802003cc:	03013403          	ld	s0,48(sp)
    802003d0:	02813903          	ld	s2,40(sp)
    802003d4:	02013983          	ld	s3,32(sp)
    802003d8:	04010113          	addi	sp,sp,64
    802003dc:	00008067          	ret

00000000802003e0 <sbi_set_timer>:

struct sbiret sbi_set_timer(uint64_t stime_value){
    802003e0:	fc010113          	addi	sp,sp,-64
    802003e4:	02113c23          	sd	ra,56(sp)
    802003e8:	02813823          	sd	s0,48(sp)
    802003ec:	03213423          	sd	s2,40(sp)
    802003f0:	03313023          	sd	s3,32(sp)
    802003f4:	04010413          	addi	s0,sp,64
    802003f8:	fca43423          	sd	a0,-56(s0)
    return sbi_ecall(0x54494d45, 0, stime_value, 0, 0, 0, 0, 0);
    802003fc:	00000893          	li	a7,0
    80200400:	00000813          	li	a6,0
    80200404:	00000793          	li	a5,0
    80200408:	00000713          	li	a4,0
    8020040c:	00000693          	li	a3,0
    80200410:	fc843603          	ld	a2,-56(s0)
    80200414:	00000593          	li	a1,0
    80200418:	54495537          	lui	a0,0x54495
    8020041c:	d4550513          	addi	a0,a0,-699 # 54494d45 <_skernel-0x2bd6b2bb>
    80200420:	da9ff0ef          	jal	802001c8 <sbi_ecall>
    80200424:	00050713          	mv	a4,a0
    80200428:	00058793          	mv	a5,a1
    8020042c:	fce43823          	sd	a4,-48(s0)
    80200430:	fcf43c23          	sd	a5,-40(s0)
    80200434:	fd043703          	ld	a4,-48(s0)
    80200438:	fd843783          	ld	a5,-40(s0)
    8020043c:	00070913          	mv	s2,a4
    80200440:	00078993          	mv	s3,a5
    80200444:	00090713          	mv	a4,s2
    80200448:	00098793          	mv	a5,s3
}
    8020044c:	00070513          	mv	a0,a4
    80200450:	00078593          	mv	a1,a5
    80200454:	03813083          	ld	ra,56(sp)
    80200458:	03013403          	ld	s0,48(sp)
    8020045c:	02813903          	ld	s2,40(sp)
    80200460:	02013983          	ld	s3,32(sp)
    80200464:	04010113          	addi	sp,sp,64
    80200468:	00008067          	ret

000000008020046c <sbi_debug_console_write>:

struct sbiret sbi_debug_console_write(unsigned long num_bytes, 
                                      unsigned long base_addr_lo, 
                                      unsigned long base_addr_hi){
    8020046c:	fb010113          	addi	sp,sp,-80
    80200470:	04113423          	sd	ra,72(sp)
    80200474:	04813023          	sd	s0,64(sp)
    80200478:	03213c23          	sd	s2,56(sp)
    8020047c:	03313823          	sd	s3,48(sp)
    80200480:	05010413          	addi	s0,sp,80
    80200484:	fca43423          	sd	a0,-56(s0)
    80200488:	fcb43023          	sd	a1,-64(s0)
    8020048c:	fac43c23          	sd	a2,-72(s0)
    return sbi_ecall(0x4442434e, 0, num_bytes, base_addr_lo, base_addr_hi, 0, 0, 0);
    80200490:	00000893          	li	a7,0
    80200494:	00000813          	li	a6,0
    80200498:	00000793          	li	a5,0
    8020049c:	fb843703          	ld	a4,-72(s0)
    802004a0:	fc043683          	ld	a3,-64(s0)
    802004a4:	fc843603          	ld	a2,-56(s0)
    802004a8:	00000593          	li	a1,0
    802004ac:	44424537          	lui	a0,0x44424
    802004b0:	34e50513          	addi	a0,a0,846 # 4442434e <_skernel-0x3bddbcb2>
    802004b4:	d15ff0ef          	jal	802001c8 <sbi_ecall>
    802004b8:	00050713          	mv	a4,a0
    802004bc:	00058793          	mv	a5,a1
    802004c0:	fce43823          	sd	a4,-48(s0)
    802004c4:	fcf43c23          	sd	a5,-40(s0)
    802004c8:	fd043703          	ld	a4,-48(s0)
    802004cc:	fd843783          	ld	a5,-40(s0)
    802004d0:	00070913          	mv	s2,a4
    802004d4:	00078993          	mv	s3,a5
    802004d8:	00090713          	mv	a4,s2
    802004dc:	00098793          	mv	a5,s3
}
    802004e0:	00070513          	mv	a0,a4
    802004e4:	00078593          	mv	a1,a5
    802004e8:	04813083          	ld	ra,72(sp)
    802004ec:	04013403          	ld	s0,64(sp)
    802004f0:	03813903          	ld	s2,56(sp)
    802004f4:	03013983          	ld	s3,48(sp)
    802004f8:	05010113          	addi	sp,sp,80
    802004fc:	00008067          	ret

0000000080200500 <sbi_debug_console_read>:

struct sbiret sbi_debug_console_read(unsigned long num_bytes, 
                                     unsigned long base_addr_lo, 
                                     unsigned long base_addr_hi){
    80200500:	fb010113          	addi	sp,sp,-80
    80200504:	04113423          	sd	ra,72(sp)
    80200508:	04813023          	sd	s0,64(sp)
    8020050c:	03213c23          	sd	s2,56(sp)
    80200510:	03313823          	sd	s3,48(sp)
    80200514:	05010413          	addi	s0,sp,80
    80200518:	fca43423          	sd	a0,-56(s0)
    8020051c:	fcb43023          	sd	a1,-64(s0)
    80200520:	fac43c23          	sd	a2,-72(s0)
    return sbi_ecall(0x4442434e, 0x1, num_bytes, base_addr_lo, base_addr_hi, 0, 0, 0);
    80200524:	00000893          	li	a7,0
    80200528:	00000813          	li	a6,0
    8020052c:	00000793          	li	a5,0
    80200530:	fb843703          	ld	a4,-72(s0)
    80200534:	fc043683          	ld	a3,-64(s0)
    80200538:	fc843603          	ld	a2,-56(s0)
    8020053c:	00100593          	li	a1,1
    80200540:	44424537          	lui	a0,0x44424
    80200544:	34e50513          	addi	a0,a0,846 # 4442434e <_skernel-0x3bddbcb2>
    80200548:	c81ff0ef          	jal	802001c8 <sbi_ecall>
    8020054c:	00050713          	mv	a4,a0
    80200550:	00058793          	mv	a5,a1
    80200554:	fce43823          	sd	a4,-48(s0)
    80200558:	fcf43c23          	sd	a5,-40(s0)
    8020055c:	fd043703          	ld	a4,-48(s0)
    80200560:	fd843783          	ld	a5,-40(s0)
    80200564:	00070913          	mv	s2,a4
    80200568:	00078993          	mv	s3,a5
    8020056c:	00090713          	mv	a4,s2
    80200570:	00098793          	mv	a5,s3
    80200574:	00070513          	mv	a0,a4
    80200578:	00078593          	mv	a1,a5
    8020057c:	04813083          	ld	ra,72(sp)
    80200580:	04013403          	ld	s0,64(sp)
    80200584:	03813903          	ld	s2,56(sp)
    80200588:	03013983          	ld	s3,48(sp)
    8020058c:	05010113          	addi	sp,sp,80
    80200590:	00008067          	ret

0000000080200594 <trap_handler>:
#include "stdint.h"
#include "clock.h"
#include "printk.h"

void trap_handler(uint64_t scause, uint64_t sepc) {
    80200594:	fe010113          	addi	sp,sp,-32
    80200598:	00113c23          	sd	ra,24(sp)
    8020059c:	00813823          	sd	s0,16(sp)
    802005a0:	02010413          	addi	s0,sp,32
    802005a4:	fea43423          	sd	a0,-24(s0)
    802005a8:	feb43023          	sd	a1,-32(s0)
    // 通过 `scause` 判断 trap 类型
    // 如果是 interrupt 判断是否是 timer interrupt
    // 如果是 timer interrupt 则打印输出相关信息，并通过 `clock_set_next_event()` 设置下一次时钟中断
    // `clock_set_next_event()` 见 4.3.4 节
    // 其他 interrupt / exception 可以直接忽略，推荐打印出来供以后调试
    if(scause & 0x8000000000000000){  // Interrupt
    802005ac:	fe843783          	ld	a5,-24(s0)
    802005b0:	0a07d463          	bgez	a5,80200658 <trap_handler+0xc4>
        if(scause == 0x8000000000000005){ // timer interrupt
    802005b4:	fe843703          	ld	a4,-24(s0)
    802005b8:	fff00793          	li	a5,-1
    802005bc:	03f79793          	slli	a5,a5,0x3f
    802005c0:	00578793          	addi	a5,a5,5
    802005c4:	00f71c63          	bne	a4,a5,802005dc <trap_handler+0x48>
            printk("[S] Supervisor Mode Timer Interrupt\n");
    802005c8:	00002517          	auipc	a0,0x2
    802005cc:	a3850513          	addi	a0,a0,-1480 # 80202000 <_srodata>
    802005d0:	7ed000ef          	jal	802015bc <printk>
            clock_set_next_event();
    802005d4:	badff0ef          	jal	80200180 <clock_set_next_event>
        else{
            printk("[S] Other exceptions(Not handled yet)\n");
        }
    }
    
    802005d8:	0a80006f          	j	80200680 <trap_handler+0xec>
        else if(scause == 0x8000000000000001){
    802005dc:	fe843703          	ld	a4,-24(s0)
    802005e0:	fff00793          	li	a5,-1
    802005e4:	03f79793          	slli	a5,a5,0x3f
    802005e8:	00178793          	addi	a5,a5,1
    802005ec:	00f71a63          	bne	a4,a5,80200600 <trap_handler+0x6c>
            printk("[S] Supervisor software Interrupt(Not handled yet)\n");
    802005f0:	00002517          	auipc	a0,0x2
    802005f4:	a3850513          	addi	a0,a0,-1480 # 80202028 <_srodata+0x28>
    802005f8:	7c5000ef          	jal	802015bc <printk>
    802005fc:	0840006f          	j	80200680 <trap_handler+0xec>
        else if(scause == 0x8000000000000009){
    80200600:	fe843703          	ld	a4,-24(s0)
    80200604:	fff00793          	li	a5,-1
    80200608:	03f79793          	slli	a5,a5,0x3f
    8020060c:	00978793          	addi	a5,a5,9
    80200610:	00f71a63          	bne	a4,a5,80200624 <trap_handler+0x90>
            printk("[S] Supervisor external Interrupt(Not handled yet)\n");
    80200614:	00002517          	auipc	a0,0x2
    80200618:	a4c50513          	addi	a0,a0,-1460 # 80202060 <_srodata+0x60>
    8020061c:	7a1000ef          	jal	802015bc <printk>
    80200620:	0600006f          	j	80200680 <trap_handler+0xec>
        else if(scause == 0x800000000000000D){
    80200624:	fe843703          	ld	a4,-24(s0)
    80200628:	fff00793          	li	a5,-1
    8020062c:	03f79793          	slli	a5,a5,0x3f
    80200630:	00d78793          	addi	a5,a5,13
    80200634:	00f71a63          	bne	a4,a5,80200648 <trap_handler+0xb4>
            printk("[S] Counter-overflow Interrupt(Not handled yet)\n");
    80200638:	00002517          	auipc	a0,0x2
    8020063c:	a6050513          	addi	a0,a0,-1440 # 80202098 <_srodata+0x98>
    80200640:	77d000ef          	jal	802015bc <printk>
    80200644:	03c0006f          	j	80200680 <trap_handler+0xec>
            printk("[S] Other interruptions(Not handled yet)\n");
    80200648:	00002517          	auipc	a0,0x2
    8020064c:	a8850513          	addi	a0,a0,-1400 # 802020d0 <_srodata+0xd0>
    80200650:	76d000ef          	jal	802015bc <printk>
    80200654:	02c0006f          	j	80200680 <trap_handler+0xec>
        if(scause == 0x0000000000000002){
    80200658:	fe843703          	ld	a4,-24(s0)
    8020065c:	00200793          	li	a5,2
    80200660:	00f71a63          	bne	a4,a5,80200674 <trap_handler+0xe0>
            printk("[S] Illegal instruction(Not handled yet)\n");
    80200664:	00002517          	auipc	a0,0x2
    80200668:	a9c50513          	addi	a0,a0,-1380 # 80202100 <_srodata+0x100>
    8020066c:	751000ef          	jal	802015bc <printk>
    80200670:	0100006f          	j	80200680 <trap_handler+0xec>
            printk("[S] Other exceptions(Not handled yet)\n");
    80200674:	00002517          	auipc	a0,0x2
    80200678:	abc50513          	addi	a0,a0,-1348 # 80202130 <_srodata+0x130>
    8020067c:	741000ef          	jal	802015bc <printk>
    80200680:	00000013          	nop
    80200684:	01813083          	ld	ra,24(sp)
    80200688:	01013403          	ld	s0,16(sp)
    8020068c:	02010113          	addi	sp,sp,32
    80200690:	00008067          	ret

0000000080200694 <start_kernel>:
#include "printk.h"

extern void test();

int start_kernel() {
    80200694:	ff010113          	addi	sp,sp,-16
    80200698:	00113423          	sd	ra,8(sp)
    8020069c:	00813023          	sd	s0,0(sp)
    802006a0:	01010413          	addi	s0,sp,16
    printk("2024");
    802006a4:	00002517          	auipc	a0,0x2
    802006a8:	ab450513          	addi	a0,a0,-1356 # 80202158 <_srodata+0x158>
    802006ac:	711000ef          	jal	802015bc <printk>
    printk(" ZJU Operating System\n");
    802006b0:	00002517          	auipc	a0,0x2
    802006b4:	ab050513          	addi	a0,a0,-1360 # 80202160 <_srodata+0x160>
    802006b8:	705000ef          	jal	802015bc <printk>
    // sbi_debug_console_write_byte('@');
    // sbi_system_reset(0, 0);
    test();
    802006bc:	01c000ef          	jal	802006d8 <test>
    return 0;
    802006c0:	00000793          	li	a5,0
}
    802006c4:	00078513          	mv	a0,a5
    802006c8:	00813083          	ld	ra,8(sp)
    802006cc:	00013403          	ld	s0,0(sp)
    802006d0:	01010113          	addi	sp,sp,16
    802006d4:	00008067          	ret

00000000802006d8 <test>:
//         sbi_system_reset(SBI_SRST_RESET_TYPE_SHUTDOWN, SBI_SRST_RESET_REASON_NONE);
//         __builtin_unreachable();
//     }
#include "printk.h"

void test() {
    802006d8:	fe010113          	addi	sp,sp,-32
    802006dc:	00113c23          	sd	ra,24(sp)
    802006e0:	00813823          	sd	s0,16(sp)
    802006e4:	02010413          	addi	s0,sp,32
    int i = 0;
    802006e8:	fe042623          	sw	zero,-20(s0)
    while (1) {
        if ((++i) % 100000000 == 0) {
    802006ec:	fec42783          	lw	a5,-20(s0)
    802006f0:	0017879b          	addiw	a5,a5,1
    802006f4:	fef42623          	sw	a5,-20(s0)
    802006f8:	fec42783          	lw	a5,-20(s0)
    802006fc:	00078713          	mv	a4,a5
    80200700:	05f5e7b7          	lui	a5,0x5f5e
    80200704:	1007879b          	addiw	a5,a5,256 # 5f5e100 <_skernel-0x7a2a1f00>
    80200708:	02f767bb          	remw	a5,a4,a5
    8020070c:	0007879b          	sext.w	a5,a5
    80200710:	fc079ee3          	bnez	a5,802006ec <test+0x14>
            printk("kernel is running!\n");
    80200714:	00002517          	auipc	a0,0x2
    80200718:	a6450513          	addi	a0,a0,-1436 # 80202178 <_srodata+0x178>
    8020071c:	6a1000ef          	jal	802015bc <printk>
            i = 0;
    80200720:	fe042623          	sw	zero,-20(s0)
        if ((++i) % 100000000 == 0) {
    80200724:	fc9ff06f          	j	802006ec <test+0x14>

0000000080200728 <putc>:
// credit: 45gfg9 <45gfg9@45gfg9.net>

#include "printk.h"
#include "sbi.h"

int putc(int c) {
    80200728:	fe010113          	addi	sp,sp,-32
    8020072c:	00113c23          	sd	ra,24(sp)
    80200730:	00813823          	sd	s0,16(sp)
    80200734:	02010413          	addi	s0,sp,32
    80200738:	00050793          	mv	a5,a0
    8020073c:	fef42623          	sw	a5,-20(s0)
    sbi_debug_console_write_byte(c);
    80200740:	fec42783          	lw	a5,-20(s0)
    80200744:	0ff7f793          	zext.b	a5,a5
    80200748:	00078513          	mv	a0,a5
    8020074c:	b69ff0ef          	jal	802002b4 <sbi_debug_console_write_byte>
    return (char)c;
    80200750:	fec42783          	lw	a5,-20(s0)
    80200754:	0ff7f793          	zext.b	a5,a5
    80200758:	0007879b          	sext.w	a5,a5
}
    8020075c:	00078513          	mv	a0,a5
    80200760:	01813083          	ld	ra,24(sp)
    80200764:	01013403          	ld	s0,16(sp)
    80200768:	02010113          	addi	sp,sp,32
    8020076c:	00008067          	ret

0000000080200770 <isspace>:
    bool sign;
    int width;
    int prec;
};

int isspace(int c) {
    80200770:	fe010113          	addi	sp,sp,-32
    80200774:	00813c23          	sd	s0,24(sp)
    80200778:	02010413          	addi	s0,sp,32
    8020077c:	00050793          	mv	a5,a0
    80200780:	fef42623          	sw	a5,-20(s0)
    return c == ' ' || (c >= '\t' && c <= '\r');
    80200784:	fec42783          	lw	a5,-20(s0)
    80200788:	0007871b          	sext.w	a4,a5
    8020078c:	02000793          	li	a5,32
    80200790:	02f70263          	beq	a4,a5,802007b4 <isspace+0x44>
    80200794:	fec42783          	lw	a5,-20(s0)
    80200798:	0007871b          	sext.w	a4,a5
    8020079c:	00800793          	li	a5,8
    802007a0:	00e7de63          	bge	a5,a4,802007bc <isspace+0x4c>
    802007a4:	fec42783          	lw	a5,-20(s0)
    802007a8:	0007871b          	sext.w	a4,a5
    802007ac:	00d00793          	li	a5,13
    802007b0:	00e7c663          	blt	a5,a4,802007bc <isspace+0x4c>
    802007b4:	00100793          	li	a5,1
    802007b8:	0080006f          	j	802007c0 <isspace+0x50>
    802007bc:	00000793          	li	a5,0
}
    802007c0:	00078513          	mv	a0,a5
    802007c4:	01813403          	ld	s0,24(sp)
    802007c8:	02010113          	addi	sp,sp,32
    802007cc:	00008067          	ret

00000000802007d0 <strtol>:

long strtol(const char *restrict nptr, char **restrict endptr, int base) {
    802007d0:	fb010113          	addi	sp,sp,-80
    802007d4:	04113423          	sd	ra,72(sp)
    802007d8:	04813023          	sd	s0,64(sp)
    802007dc:	05010413          	addi	s0,sp,80
    802007e0:	fca43423          	sd	a0,-56(s0)
    802007e4:	fcb43023          	sd	a1,-64(s0)
    802007e8:	00060793          	mv	a5,a2
    802007ec:	faf42e23          	sw	a5,-68(s0)
    long ret = 0;
    802007f0:	fe043423          	sd	zero,-24(s0)
    bool neg = false;
    802007f4:	fe0403a3          	sb	zero,-25(s0)
    const char *p = nptr;
    802007f8:	fc843783          	ld	a5,-56(s0)
    802007fc:	fcf43c23          	sd	a5,-40(s0)

    while (isspace(*p)) {
    80200800:	0100006f          	j	80200810 <strtol+0x40>
        p++;
    80200804:	fd843783          	ld	a5,-40(s0)
    80200808:	00178793          	addi	a5,a5,1
    8020080c:	fcf43c23          	sd	a5,-40(s0)
    while (isspace(*p)) {
    80200810:	fd843783          	ld	a5,-40(s0)
    80200814:	0007c783          	lbu	a5,0(a5)
    80200818:	0007879b          	sext.w	a5,a5
    8020081c:	00078513          	mv	a0,a5
    80200820:	f51ff0ef          	jal	80200770 <isspace>
    80200824:	00050793          	mv	a5,a0
    80200828:	fc079ee3          	bnez	a5,80200804 <strtol+0x34>
    }

    if (*p == '-') {
    8020082c:	fd843783          	ld	a5,-40(s0)
    80200830:	0007c783          	lbu	a5,0(a5)
    80200834:	00078713          	mv	a4,a5
    80200838:	02d00793          	li	a5,45
    8020083c:	00f71e63          	bne	a4,a5,80200858 <strtol+0x88>
        neg = true;
    80200840:	00100793          	li	a5,1
    80200844:	fef403a3          	sb	a5,-25(s0)
        p++;
    80200848:	fd843783          	ld	a5,-40(s0)
    8020084c:	00178793          	addi	a5,a5,1
    80200850:	fcf43c23          	sd	a5,-40(s0)
    80200854:	0240006f          	j	80200878 <strtol+0xa8>
    } else if (*p == '+') {
    80200858:	fd843783          	ld	a5,-40(s0)
    8020085c:	0007c783          	lbu	a5,0(a5)
    80200860:	00078713          	mv	a4,a5
    80200864:	02b00793          	li	a5,43
    80200868:	00f71863          	bne	a4,a5,80200878 <strtol+0xa8>
        p++;
    8020086c:	fd843783          	ld	a5,-40(s0)
    80200870:	00178793          	addi	a5,a5,1
    80200874:	fcf43c23          	sd	a5,-40(s0)
    }

    if (base == 0) {
    80200878:	fbc42783          	lw	a5,-68(s0)
    8020087c:	0007879b          	sext.w	a5,a5
    80200880:	06079c63          	bnez	a5,802008f8 <strtol+0x128>
        if (*p == '0') {
    80200884:	fd843783          	ld	a5,-40(s0)
    80200888:	0007c783          	lbu	a5,0(a5)
    8020088c:	00078713          	mv	a4,a5
    80200890:	03000793          	li	a5,48
    80200894:	04f71e63          	bne	a4,a5,802008f0 <strtol+0x120>
            p++;
    80200898:	fd843783          	ld	a5,-40(s0)
    8020089c:	00178793          	addi	a5,a5,1
    802008a0:	fcf43c23          	sd	a5,-40(s0)
            if (*p == 'x' || *p == 'X') {
    802008a4:	fd843783          	ld	a5,-40(s0)
    802008a8:	0007c783          	lbu	a5,0(a5)
    802008ac:	00078713          	mv	a4,a5
    802008b0:	07800793          	li	a5,120
    802008b4:	00f70c63          	beq	a4,a5,802008cc <strtol+0xfc>
    802008b8:	fd843783          	ld	a5,-40(s0)
    802008bc:	0007c783          	lbu	a5,0(a5)
    802008c0:	00078713          	mv	a4,a5
    802008c4:	05800793          	li	a5,88
    802008c8:	00f71e63          	bne	a4,a5,802008e4 <strtol+0x114>
                base = 16;
    802008cc:	01000793          	li	a5,16
    802008d0:	faf42e23          	sw	a5,-68(s0)
                p++;
    802008d4:	fd843783          	ld	a5,-40(s0)
    802008d8:	00178793          	addi	a5,a5,1
    802008dc:	fcf43c23          	sd	a5,-40(s0)
    802008e0:	0180006f          	j	802008f8 <strtol+0x128>
            } else {
                base = 8;
    802008e4:	00800793          	li	a5,8
    802008e8:	faf42e23          	sw	a5,-68(s0)
    802008ec:	00c0006f          	j	802008f8 <strtol+0x128>
            }
        } else {
            base = 10;
    802008f0:	00a00793          	li	a5,10
    802008f4:	faf42e23          	sw	a5,-68(s0)
        }
    }

    while (1) {
        int digit;
        if (*p >= '0' && *p <= '9') {
    802008f8:	fd843783          	ld	a5,-40(s0)
    802008fc:	0007c783          	lbu	a5,0(a5)
    80200900:	00078713          	mv	a4,a5
    80200904:	02f00793          	li	a5,47
    80200908:	02e7f863          	bgeu	a5,a4,80200938 <strtol+0x168>
    8020090c:	fd843783          	ld	a5,-40(s0)
    80200910:	0007c783          	lbu	a5,0(a5)
    80200914:	00078713          	mv	a4,a5
    80200918:	03900793          	li	a5,57
    8020091c:	00e7ee63          	bltu	a5,a4,80200938 <strtol+0x168>
            digit = *p - '0';
    80200920:	fd843783          	ld	a5,-40(s0)
    80200924:	0007c783          	lbu	a5,0(a5)
    80200928:	0007879b          	sext.w	a5,a5
    8020092c:	fd07879b          	addiw	a5,a5,-48
    80200930:	fcf42a23          	sw	a5,-44(s0)
    80200934:	0800006f          	j	802009b4 <strtol+0x1e4>
        } else if (*p >= 'a' && *p <= 'z') {
    80200938:	fd843783          	ld	a5,-40(s0)
    8020093c:	0007c783          	lbu	a5,0(a5)
    80200940:	00078713          	mv	a4,a5
    80200944:	06000793          	li	a5,96
    80200948:	02e7f863          	bgeu	a5,a4,80200978 <strtol+0x1a8>
    8020094c:	fd843783          	ld	a5,-40(s0)
    80200950:	0007c783          	lbu	a5,0(a5)
    80200954:	00078713          	mv	a4,a5
    80200958:	07a00793          	li	a5,122
    8020095c:	00e7ee63          	bltu	a5,a4,80200978 <strtol+0x1a8>
            digit = *p - ('a' - 10);
    80200960:	fd843783          	ld	a5,-40(s0)
    80200964:	0007c783          	lbu	a5,0(a5)
    80200968:	0007879b          	sext.w	a5,a5
    8020096c:	fa97879b          	addiw	a5,a5,-87
    80200970:	fcf42a23          	sw	a5,-44(s0)
    80200974:	0400006f          	j	802009b4 <strtol+0x1e4>
        } else if (*p >= 'A' && *p <= 'Z') {
    80200978:	fd843783          	ld	a5,-40(s0)
    8020097c:	0007c783          	lbu	a5,0(a5)
    80200980:	00078713          	mv	a4,a5
    80200984:	04000793          	li	a5,64
    80200988:	06e7f863          	bgeu	a5,a4,802009f8 <strtol+0x228>
    8020098c:	fd843783          	ld	a5,-40(s0)
    80200990:	0007c783          	lbu	a5,0(a5)
    80200994:	00078713          	mv	a4,a5
    80200998:	05a00793          	li	a5,90
    8020099c:	04e7ee63          	bltu	a5,a4,802009f8 <strtol+0x228>
            digit = *p - ('A' - 10);
    802009a0:	fd843783          	ld	a5,-40(s0)
    802009a4:	0007c783          	lbu	a5,0(a5)
    802009a8:	0007879b          	sext.w	a5,a5
    802009ac:	fc97879b          	addiw	a5,a5,-55
    802009b0:	fcf42a23          	sw	a5,-44(s0)
        } else {
            break;
        }

        if (digit >= base) {
    802009b4:	fd442783          	lw	a5,-44(s0)
    802009b8:	00078713          	mv	a4,a5
    802009bc:	fbc42783          	lw	a5,-68(s0)
    802009c0:	0007071b          	sext.w	a4,a4
    802009c4:	0007879b          	sext.w	a5,a5
    802009c8:	02f75663          	bge	a4,a5,802009f4 <strtol+0x224>
            break;
        }

        ret = ret * base + digit;
    802009cc:	fbc42703          	lw	a4,-68(s0)
    802009d0:	fe843783          	ld	a5,-24(s0)
    802009d4:	02f70733          	mul	a4,a4,a5
    802009d8:	fd442783          	lw	a5,-44(s0)
    802009dc:	00f707b3          	add	a5,a4,a5
    802009e0:	fef43423          	sd	a5,-24(s0)
        p++;
    802009e4:	fd843783          	ld	a5,-40(s0)
    802009e8:	00178793          	addi	a5,a5,1
    802009ec:	fcf43c23          	sd	a5,-40(s0)
    while (1) {
    802009f0:	f09ff06f          	j	802008f8 <strtol+0x128>
            break;
    802009f4:	00000013          	nop
    }

    if (endptr) {
    802009f8:	fc043783          	ld	a5,-64(s0)
    802009fc:	00078863          	beqz	a5,80200a0c <strtol+0x23c>
        *endptr = (char *)p;
    80200a00:	fc043783          	ld	a5,-64(s0)
    80200a04:	fd843703          	ld	a4,-40(s0)
    80200a08:	00e7b023          	sd	a4,0(a5)
    }

    return neg ? -ret : ret;
    80200a0c:	fe744783          	lbu	a5,-25(s0)
    80200a10:	0ff7f793          	zext.b	a5,a5
    80200a14:	00078863          	beqz	a5,80200a24 <strtol+0x254>
    80200a18:	fe843783          	ld	a5,-24(s0)
    80200a1c:	40f007b3          	neg	a5,a5
    80200a20:	0080006f          	j	80200a28 <strtol+0x258>
    80200a24:	fe843783          	ld	a5,-24(s0)
}
    80200a28:	00078513          	mv	a0,a5
    80200a2c:	04813083          	ld	ra,72(sp)
    80200a30:	04013403          	ld	s0,64(sp)
    80200a34:	05010113          	addi	sp,sp,80
    80200a38:	00008067          	ret

0000000080200a3c <puts_wo_nl>:

// puts without newline
static int puts_wo_nl(int (*putch)(int), const char *s) {
    80200a3c:	fd010113          	addi	sp,sp,-48
    80200a40:	02113423          	sd	ra,40(sp)
    80200a44:	02813023          	sd	s0,32(sp)
    80200a48:	03010413          	addi	s0,sp,48
    80200a4c:	fca43c23          	sd	a0,-40(s0)
    80200a50:	fcb43823          	sd	a1,-48(s0)
    if (!s) {
    80200a54:	fd043783          	ld	a5,-48(s0)
    80200a58:	00079863          	bnez	a5,80200a68 <puts_wo_nl+0x2c>
        s = "(null)";
    80200a5c:	00001797          	auipc	a5,0x1
    80200a60:	73478793          	addi	a5,a5,1844 # 80202190 <_srodata+0x190>
    80200a64:	fcf43823          	sd	a5,-48(s0)
    }
    const char *p = s;
    80200a68:	fd043783          	ld	a5,-48(s0)
    80200a6c:	fef43423          	sd	a5,-24(s0)
    while (*p) {
    80200a70:	0240006f          	j	80200a94 <puts_wo_nl+0x58>
        putch(*p++);
    80200a74:	fe843783          	ld	a5,-24(s0)
    80200a78:	00178713          	addi	a4,a5,1
    80200a7c:	fee43423          	sd	a4,-24(s0)
    80200a80:	0007c783          	lbu	a5,0(a5)
    80200a84:	0007871b          	sext.w	a4,a5
    80200a88:	fd843783          	ld	a5,-40(s0)
    80200a8c:	00070513          	mv	a0,a4
    80200a90:	000780e7          	jalr	a5
    while (*p) {
    80200a94:	fe843783          	ld	a5,-24(s0)
    80200a98:	0007c783          	lbu	a5,0(a5)
    80200a9c:	fc079ce3          	bnez	a5,80200a74 <puts_wo_nl+0x38>
    }
    return p - s;
    80200aa0:	fe843703          	ld	a4,-24(s0)
    80200aa4:	fd043783          	ld	a5,-48(s0)
    80200aa8:	40f707b3          	sub	a5,a4,a5
    80200aac:	0007879b          	sext.w	a5,a5
}
    80200ab0:	00078513          	mv	a0,a5
    80200ab4:	02813083          	ld	ra,40(sp)
    80200ab8:	02013403          	ld	s0,32(sp)
    80200abc:	03010113          	addi	sp,sp,48
    80200ac0:	00008067          	ret

0000000080200ac4 <print_dec_int>:

static int print_dec_int(int (*putch)(int), unsigned long num, bool is_signed, struct fmt_flags *flags) {
    80200ac4:	f9010113          	addi	sp,sp,-112
    80200ac8:	06113423          	sd	ra,104(sp)
    80200acc:	06813023          	sd	s0,96(sp)
    80200ad0:	07010413          	addi	s0,sp,112
    80200ad4:	faa43423          	sd	a0,-88(s0)
    80200ad8:	fab43023          	sd	a1,-96(s0)
    80200adc:	00060793          	mv	a5,a2
    80200ae0:	f8d43823          	sd	a3,-112(s0)
    80200ae4:	f8f40fa3          	sb	a5,-97(s0)
    if (is_signed && num == 0x8000000000000000UL) {
    80200ae8:	f9f44783          	lbu	a5,-97(s0)
    80200aec:	0ff7f793          	zext.b	a5,a5
    80200af0:	02078663          	beqz	a5,80200b1c <print_dec_int+0x58>
    80200af4:	fa043703          	ld	a4,-96(s0)
    80200af8:	fff00793          	li	a5,-1
    80200afc:	03f79793          	slli	a5,a5,0x3f
    80200b00:	00f71e63          	bne	a4,a5,80200b1c <print_dec_int+0x58>
        // special case for 0x8000000000000000
        return puts_wo_nl(putch, "-9223372036854775808");
    80200b04:	00001597          	auipc	a1,0x1
    80200b08:	69458593          	addi	a1,a1,1684 # 80202198 <_srodata+0x198>
    80200b0c:	fa843503          	ld	a0,-88(s0)
    80200b10:	f2dff0ef          	jal	80200a3c <puts_wo_nl>
    80200b14:	00050793          	mv	a5,a0
    80200b18:	2a00006f          	j	80200db8 <print_dec_int+0x2f4>
    }

    if (flags->prec == 0 && num == 0) {
    80200b1c:	f9043783          	ld	a5,-112(s0)
    80200b20:	00c7a783          	lw	a5,12(a5)
    80200b24:	00079a63          	bnez	a5,80200b38 <print_dec_int+0x74>
    80200b28:	fa043783          	ld	a5,-96(s0)
    80200b2c:	00079663          	bnez	a5,80200b38 <print_dec_int+0x74>
        return 0;
    80200b30:	00000793          	li	a5,0
    80200b34:	2840006f          	j	80200db8 <print_dec_int+0x2f4>
    }

    bool neg = false;
    80200b38:	fe0407a3          	sb	zero,-17(s0)

    if (is_signed && (long)num < 0) {
    80200b3c:	f9f44783          	lbu	a5,-97(s0)
    80200b40:	0ff7f793          	zext.b	a5,a5
    80200b44:	02078063          	beqz	a5,80200b64 <print_dec_int+0xa0>
    80200b48:	fa043783          	ld	a5,-96(s0)
    80200b4c:	0007dc63          	bgez	a5,80200b64 <print_dec_int+0xa0>
        neg = true;
    80200b50:	00100793          	li	a5,1
    80200b54:	fef407a3          	sb	a5,-17(s0)
        num = -num;
    80200b58:	fa043783          	ld	a5,-96(s0)
    80200b5c:	40f007b3          	neg	a5,a5
    80200b60:	faf43023          	sd	a5,-96(s0)
    }

    char buf[20];
    int decdigits = 0;
    80200b64:	fe042423          	sw	zero,-24(s0)

    bool has_sign_char = is_signed && (neg || flags->sign || flags->spaceflag);
    80200b68:	f9f44783          	lbu	a5,-97(s0)
    80200b6c:	0ff7f793          	zext.b	a5,a5
    80200b70:	02078863          	beqz	a5,80200ba0 <print_dec_int+0xdc>
    80200b74:	fef44783          	lbu	a5,-17(s0)
    80200b78:	0ff7f793          	zext.b	a5,a5
    80200b7c:	00079e63          	bnez	a5,80200b98 <print_dec_int+0xd4>
    80200b80:	f9043783          	ld	a5,-112(s0)
    80200b84:	0057c783          	lbu	a5,5(a5)
    80200b88:	00079863          	bnez	a5,80200b98 <print_dec_int+0xd4>
    80200b8c:	f9043783          	ld	a5,-112(s0)
    80200b90:	0047c783          	lbu	a5,4(a5)
    80200b94:	00078663          	beqz	a5,80200ba0 <print_dec_int+0xdc>
    80200b98:	00100793          	li	a5,1
    80200b9c:	0080006f          	j	80200ba4 <print_dec_int+0xe0>
    80200ba0:	00000793          	li	a5,0
    80200ba4:	fcf40ba3          	sb	a5,-41(s0)
    80200ba8:	fd744783          	lbu	a5,-41(s0)
    80200bac:	0017f793          	andi	a5,a5,1
    80200bb0:	fcf40ba3          	sb	a5,-41(s0)

    do {
        buf[decdigits++] = num % 10 + '0';
    80200bb4:	fa043703          	ld	a4,-96(s0)
    80200bb8:	00a00793          	li	a5,10
    80200bbc:	02f777b3          	remu	a5,a4,a5
    80200bc0:	0ff7f713          	zext.b	a4,a5
    80200bc4:	fe842783          	lw	a5,-24(s0)
    80200bc8:	0017869b          	addiw	a3,a5,1
    80200bcc:	fed42423          	sw	a3,-24(s0)
    80200bd0:	0307071b          	addiw	a4,a4,48
    80200bd4:	0ff77713          	zext.b	a4,a4
    80200bd8:	ff078793          	addi	a5,a5,-16
    80200bdc:	008787b3          	add	a5,a5,s0
    80200be0:	fce78423          	sb	a4,-56(a5)
        num /= 10;
    80200be4:	fa043703          	ld	a4,-96(s0)
    80200be8:	00a00793          	li	a5,10
    80200bec:	02f757b3          	divu	a5,a4,a5
    80200bf0:	faf43023          	sd	a5,-96(s0)
    } while (num);
    80200bf4:	fa043783          	ld	a5,-96(s0)
    80200bf8:	fa079ee3          	bnez	a5,80200bb4 <print_dec_int+0xf0>

    if (flags->prec == -1 && flags->zeroflag) {
    80200bfc:	f9043783          	ld	a5,-112(s0)
    80200c00:	00c7a783          	lw	a5,12(a5)
    80200c04:	00078713          	mv	a4,a5
    80200c08:	fff00793          	li	a5,-1
    80200c0c:	02f71063          	bne	a4,a5,80200c2c <print_dec_int+0x168>
    80200c10:	f9043783          	ld	a5,-112(s0)
    80200c14:	0037c783          	lbu	a5,3(a5)
    80200c18:	00078a63          	beqz	a5,80200c2c <print_dec_int+0x168>
        flags->prec = flags->width;
    80200c1c:	f9043783          	ld	a5,-112(s0)
    80200c20:	0087a703          	lw	a4,8(a5)
    80200c24:	f9043783          	ld	a5,-112(s0)
    80200c28:	00e7a623          	sw	a4,12(a5)
    }

    int written = 0;
    80200c2c:	fe042223          	sw	zero,-28(s0)

    for (int i = flags->width - __MAX(decdigits, flags->prec) - has_sign_char; i > 0; i--) {
    80200c30:	f9043783          	ld	a5,-112(s0)
    80200c34:	0087a703          	lw	a4,8(a5)
    80200c38:	fe842783          	lw	a5,-24(s0)
    80200c3c:	fcf42823          	sw	a5,-48(s0)
    80200c40:	f9043783          	ld	a5,-112(s0)
    80200c44:	00c7a783          	lw	a5,12(a5)
    80200c48:	fcf42623          	sw	a5,-52(s0)
    80200c4c:	fd042783          	lw	a5,-48(s0)
    80200c50:	00078593          	mv	a1,a5
    80200c54:	fcc42783          	lw	a5,-52(s0)
    80200c58:	00078613          	mv	a2,a5
    80200c5c:	0006069b          	sext.w	a3,a2
    80200c60:	0005879b          	sext.w	a5,a1
    80200c64:	00f6d463          	bge	a3,a5,80200c6c <print_dec_int+0x1a8>
    80200c68:	00058613          	mv	a2,a1
    80200c6c:	0006079b          	sext.w	a5,a2
    80200c70:	40f707bb          	subw	a5,a4,a5
    80200c74:	0007871b          	sext.w	a4,a5
    80200c78:	fd744783          	lbu	a5,-41(s0)
    80200c7c:	0007879b          	sext.w	a5,a5
    80200c80:	40f707bb          	subw	a5,a4,a5
    80200c84:	fef42023          	sw	a5,-32(s0)
    80200c88:	0280006f          	j	80200cb0 <print_dec_int+0x1ec>
        putch(' ');
    80200c8c:	fa843783          	ld	a5,-88(s0)
    80200c90:	02000513          	li	a0,32
    80200c94:	000780e7          	jalr	a5
        ++written;
    80200c98:	fe442783          	lw	a5,-28(s0)
    80200c9c:	0017879b          	addiw	a5,a5,1
    80200ca0:	fef42223          	sw	a5,-28(s0)
    for (int i = flags->width - __MAX(decdigits, flags->prec) - has_sign_char; i > 0; i--) {
    80200ca4:	fe042783          	lw	a5,-32(s0)
    80200ca8:	fff7879b          	addiw	a5,a5,-1
    80200cac:	fef42023          	sw	a5,-32(s0)
    80200cb0:	fe042783          	lw	a5,-32(s0)
    80200cb4:	0007879b          	sext.w	a5,a5
    80200cb8:	fcf04ae3          	bgtz	a5,80200c8c <print_dec_int+0x1c8>
    }

    if (has_sign_char) {
    80200cbc:	fd744783          	lbu	a5,-41(s0)
    80200cc0:	0ff7f793          	zext.b	a5,a5
    80200cc4:	04078463          	beqz	a5,80200d0c <print_dec_int+0x248>
        putch(neg ? '-' : flags->sign ? '+' : ' ');
    80200cc8:	fef44783          	lbu	a5,-17(s0)
    80200ccc:	0ff7f793          	zext.b	a5,a5
    80200cd0:	00078663          	beqz	a5,80200cdc <print_dec_int+0x218>
    80200cd4:	02d00793          	li	a5,45
    80200cd8:	01c0006f          	j	80200cf4 <print_dec_int+0x230>
    80200cdc:	f9043783          	ld	a5,-112(s0)
    80200ce0:	0057c783          	lbu	a5,5(a5)
    80200ce4:	00078663          	beqz	a5,80200cf0 <print_dec_int+0x22c>
    80200ce8:	02b00793          	li	a5,43
    80200cec:	0080006f          	j	80200cf4 <print_dec_int+0x230>
    80200cf0:	02000793          	li	a5,32
    80200cf4:	fa843703          	ld	a4,-88(s0)
    80200cf8:	00078513          	mv	a0,a5
    80200cfc:	000700e7          	jalr	a4
        ++written;
    80200d00:	fe442783          	lw	a5,-28(s0)
    80200d04:	0017879b          	addiw	a5,a5,1
    80200d08:	fef42223          	sw	a5,-28(s0)
    }

    for (int i = decdigits; i < flags->prec - has_sign_char; i++) {
    80200d0c:	fe842783          	lw	a5,-24(s0)
    80200d10:	fcf42e23          	sw	a5,-36(s0)
    80200d14:	0280006f          	j	80200d3c <print_dec_int+0x278>
        putch('0');
    80200d18:	fa843783          	ld	a5,-88(s0)
    80200d1c:	03000513          	li	a0,48
    80200d20:	000780e7          	jalr	a5
        ++written;
    80200d24:	fe442783          	lw	a5,-28(s0)
    80200d28:	0017879b          	addiw	a5,a5,1
    80200d2c:	fef42223          	sw	a5,-28(s0)
    for (int i = decdigits; i < flags->prec - has_sign_char; i++) {
    80200d30:	fdc42783          	lw	a5,-36(s0)
    80200d34:	0017879b          	addiw	a5,a5,1
    80200d38:	fcf42e23          	sw	a5,-36(s0)
    80200d3c:	f9043783          	ld	a5,-112(s0)
    80200d40:	00c7a703          	lw	a4,12(a5)
    80200d44:	fd744783          	lbu	a5,-41(s0)
    80200d48:	0007879b          	sext.w	a5,a5
    80200d4c:	40f707bb          	subw	a5,a4,a5
    80200d50:	0007871b          	sext.w	a4,a5
    80200d54:	fdc42783          	lw	a5,-36(s0)
    80200d58:	0007879b          	sext.w	a5,a5
    80200d5c:	fae7cee3          	blt	a5,a4,80200d18 <print_dec_int+0x254>
    }

    for (int i = decdigits - 1; i >= 0; i--) {
    80200d60:	fe842783          	lw	a5,-24(s0)
    80200d64:	fff7879b          	addiw	a5,a5,-1
    80200d68:	fcf42c23          	sw	a5,-40(s0)
    80200d6c:	03c0006f          	j	80200da8 <print_dec_int+0x2e4>
        putch(buf[i]);
    80200d70:	fd842783          	lw	a5,-40(s0)
    80200d74:	ff078793          	addi	a5,a5,-16
    80200d78:	008787b3          	add	a5,a5,s0
    80200d7c:	fc87c783          	lbu	a5,-56(a5)
    80200d80:	0007871b          	sext.w	a4,a5
    80200d84:	fa843783          	ld	a5,-88(s0)
    80200d88:	00070513          	mv	a0,a4
    80200d8c:	000780e7          	jalr	a5
        ++written;
    80200d90:	fe442783          	lw	a5,-28(s0)
    80200d94:	0017879b          	addiw	a5,a5,1
    80200d98:	fef42223          	sw	a5,-28(s0)
    for (int i = decdigits - 1; i >= 0; i--) {
    80200d9c:	fd842783          	lw	a5,-40(s0)
    80200da0:	fff7879b          	addiw	a5,a5,-1
    80200da4:	fcf42c23          	sw	a5,-40(s0)
    80200da8:	fd842783          	lw	a5,-40(s0)
    80200dac:	0007879b          	sext.w	a5,a5
    80200db0:	fc07d0e3          	bgez	a5,80200d70 <print_dec_int+0x2ac>
    }

    return written;
    80200db4:	fe442783          	lw	a5,-28(s0)
}
    80200db8:	00078513          	mv	a0,a5
    80200dbc:	06813083          	ld	ra,104(sp)
    80200dc0:	06013403          	ld	s0,96(sp)
    80200dc4:	07010113          	addi	sp,sp,112
    80200dc8:	00008067          	ret

0000000080200dcc <vprintfmt>:

int vprintfmt(int (*putch)(int), const char *fmt, va_list vl) {
    80200dcc:	f4010113          	addi	sp,sp,-192
    80200dd0:	0a113c23          	sd	ra,184(sp)
    80200dd4:	0a813823          	sd	s0,176(sp)
    80200dd8:	0c010413          	addi	s0,sp,192
    80200ddc:	f4a43c23          	sd	a0,-168(s0)
    80200de0:	f4b43823          	sd	a1,-176(s0)
    80200de4:	f4c43423          	sd	a2,-184(s0)
    static const char lowerxdigits[] = "0123456789abcdef";
    static const char upperxdigits[] = "0123456789ABCDEF";

    struct fmt_flags flags = {};
    80200de8:	f8043023          	sd	zero,-128(s0)
    80200dec:	f8043423          	sd	zero,-120(s0)

    int written = 0;
    80200df0:	fe042623          	sw	zero,-20(s0)

    for (; *fmt; fmt++) {
    80200df4:	7a40006f          	j	80201598 <vprintfmt+0x7cc>
        if (flags.in_format) {
    80200df8:	f8044783          	lbu	a5,-128(s0)
    80200dfc:	72078e63          	beqz	a5,80201538 <vprintfmt+0x76c>
            if (*fmt == '#') {
    80200e00:	f5043783          	ld	a5,-176(s0)
    80200e04:	0007c783          	lbu	a5,0(a5)
    80200e08:	00078713          	mv	a4,a5
    80200e0c:	02300793          	li	a5,35
    80200e10:	00f71863          	bne	a4,a5,80200e20 <vprintfmt+0x54>
                flags.sharpflag = true;
    80200e14:	00100793          	li	a5,1
    80200e18:	f8f40123          	sb	a5,-126(s0)
    80200e1c:	7700006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == '0') {
    80200e20:	f5043783          	ld	a5,-176(s0)
    80200e24:	0007c783          	lbu	a5,0(a5)
    80200e28:	00078713          	mv	a4,a5
    80200e2c:	03000793          	li	a5,48
    80200e30:	00f71863          	bne	a4,a5,80200e40 <vprintfmt+0x74>
                flags.zeroflag = true;
    80200e34:	00100793          	li	a5,1
    80200e38:	f8f401a3          	sb	a5,-125(s0)
    80200e3c:	7500006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == 'l' || *fmt == 'z' || *fmt == 't' || *fmt == 'j') {
    80200e40:	f5043783          	ld	a5,-176(s0)
    80200e44:	0007c783          	lbu	a5,0(a5)
    80200e48:	00078713          	mv	a4,a5
    80200e4c:	06c00793          	li	a5,108
    80200e50:	04f70063          	beq	a4,a5,80200e90 <vprintfmt+0xc4>
    80200e54:	f5043783          	ld	a5,-176(s0)
    80200e58:	0007c783          	lbu	a5,0(a5)
    80200e5c:	00078713          	mv	a4,a5
    80200e60:	07a00793          	li	a5,122
    80200e64:	02f70663          	beq	a4,a5,80200e90 <vprintfmt+0xc4>
    80200e68:	f5043783          	ld	a5,-176(s0)
    80200e6c:	0007c783          	lbu	a5,0(a5)
    80200e70:	00078713          	mv	a4,a5
    80200e74:	07400793          	li	a5,116
    80200e78:	00f70c63          	beq	a4,a5,80200e90 <vprintfmt+0xc4>
    80200e7c:	f5043783          	ld	a5,-176(s0)
    80200e80:	0007c783          	lbu	a5,0(a5)
    80200e84:	00078713          	mv	a4,a5
    80200e88:	06a00793          	li	a5,106
    80200e8c:	00f71863          	bne	a4,a5,80200e9c <vprintfmt+0xd0>
                // l: long, z: size_t, t: ptrdiff_t, j: intmax_t
                flags.longflag = true;
    80200e90:	00100793          	li	a5,1
    80200e94:	f8f400a3          	sb	a5,-127(s0)
    80200e98:	6f40006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == '+') {
    80200e9c:	f5043783          	ld	a5,-176(s0)
    80200ea0:	0007c783          	lbu	a5,0(a5)
    80200ea4:	00078713          	mv	a4,a5
    80200ea8:	02b00793          	li	a5,43
    80200eac:	00f71863          	bne	a4,a5,80200ebc <vprintfmt+0xf0>
                flags.sign = true;
    80200eb0:	00100793          	li	a5,1
    80200eb4:	f8f402a3          	sb	a5,-123(s0)
    80200eb8:	6d40006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == ' ') {
    80200ebc:	f5043783          	ld	a5,-176(s0)
    80200ec0:	0007c783          	lbu	a5,0(a5)
    80200ec4:	00078713          	mv	a4,a5
    80200ec8:	02000793          	li	a5,32
    80200ecc:	00f71863          	bne	a4,a5,80200edc <vprintfmt+0x110>
                flags.spaceflag = true;
    80200ed0:	00100793          	li	a5,1
    80200ed4:	f8f40223          	sb	a5,-124(s0)
    80200ed8:	6b40006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == '*') {
    80200edc:	f5043783          	ld	a5,-176(s0)
    80200ee0:	0007c783          	lbu	a5,0(a5)
    80200ee4:	00078713          	mv	a4,a5
    80200ee8:	02a00793          	li	a5,42
    80200eec:	00f71e63          	bne	a4,a5,80200f08 <vprintfmt+0x13c>
                flags.width = va_arg(vl, int);
    80200ef0:	f4843783          	ld	a5,-184(s0)
    80200ef4:	00878713          	addi	a4,a5,8
    80200ef8:	f4e43423          	sd	a4,-184(s0)
    80200efc:	0007a783          	lw	a5,0(a5)
    80200f00:	f8f42423          	sw	a5,-120(s0)
    80200f04:	6880006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt >= '1' && *fmt <= '9') {
    80200f08:	f5043783          	ld	a5,-176(s0)
    80200f0c:	0007c783          	lbu	a5,0(a5)
    80200f10:	00078713          	mv	a4,a5
    80200f14:	03000793          	li	a5,48
    80200f18:	04e7f663          	bgeu	a5,a4,80200f64 <vprintfmt+0x198>
    80200f1c:	f5043783          	ld	a5,-176(s0)
    80200f20:	0007c783          	lbu	a5,0(a5)
    80200f24:	00078713          	mv	a4,a5
    80200f28:	03900793          	li	a5,57
    80200f2c:	02e7ec63          	bltu	a5,a4,80200f64 <vprintfmt+0x198>
                flags.width = strtol(fmt, (char **)&fmt, 10);
    80200f30:	f5043783          	ld	a5,-176(s0)
    80200f34:	f5040713          	addi	a4,s0,-176
    80200f38:	00a00613          	li	a2,10
    80200f3c:	00070593          	mv	a1,a4
    80200f40:	00078513          	mv	a0,a5
    80200f44:	88dff0ef          	jal	802007d0 <strtol>
    80200f48:	00050793          	mv	a5,a0
    80200f4c:	0007879b          	sext.w	a5,a5
    80200f50:	f8f42423          	sw	a5,-120(s0)
                fmt--;
    80200f54:	f5043783          	ld	a5,-176(s0)
    80200f58:	fff78793          	addi	a5,a5,-1
    80200f5c:	f4f43823          	sd	a5,-176(s0)
    80200f60:	62c0006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == '.') {
    80200f64:	f5043783          	ld	a5,-176(s0)
    80200f68:	0007c783          	lbu	a5,0(a5)
    80200f6c:	00078713          	mv	a4,a5
    80200f70:	02e00793          	li	a5,46
    80200f74:	06f71863          	bne	a4,a5,80200fe4 <vprintfmt+0x218>
                fmt++;
    80200f78:	f5043783          	ld	a5,-176(s0)
    80200f7c:	00178793          	addi	a5,a5,1
    80200f80:	f4f43823          	sd	a5,-176(s0)
                if (*fmt == '*') {
    80200f84:	f5043783          	ld	a5,-176(s0)
    80200f88:	0007c783          	lbu	a5,0(a5)
    80200f8c:	00078713          	mv	a4,a5
    80200f90:	02a00793          	li	a5,42
    80200f94:	00f71e63          	bne	a4,a5,80200fb0 <vprintfmt+0x1e4>
                    flags.prec = va_arg(vl, int);
    80200f98:	f4843783          	ld	a5,-184(s0)
    80200f9c:	00878713          	addi	a4,a5,8
    80200fa0:	f4e43423          	sd	a4,-184(s0)
    80200fa4:	0007a783          	lw	a5,0(a5)
    80200fa8:	f8f42623          	sw	a5,-116(s0)
    80200fac:	5e00006f          	j	8020158c <vprintfmt+0x7c0>
                } else {
                    flags.prec = strtol(fmt, (char **)&fmt, 10);
    80200fb0:	f5043783          	ld	a5,-176(s0)
    80200fb4:	f5040713          	addi	a4,s0,-176
    80200fb8:	00a00613          	li	a2,10
    80200fbc:	00070593          	mv	a1,a4
    80200fc0:	00078513          	mv	a0,a5
    80200fc4:	80dff0ef          	jal	802007d0 <strtol>
    80200fc8:	00050793          	mv	a5,a0
    80200fcc:	0007879b          	sext.w	a5,a5
    80200fd0:	f8f42623          	sw	a5,-116(s0)
                    fmt--;
    80200fd4:	f5043783          	ld	a5,-176(s0)
    80200fd8:	fff78793          	addi	a5,a5,-1
    80200fdc:	f4f43823          	sd	a5,-176(s0)
    80200fe0:	5ac0006f          	j	8020158c <vprintfmt+0x7c0>
                }
            } else if (*fmt == 'x' || *fmt == 'X' || *fmt == 'p') {
    80200fe4:	f5043783          	ld	a5,-176(s0)
    80200fe8:	0007c783          	lbu	a5,0(a5)
    80200fec:	00078713          	mv	a4,a5
    80200ff0:	07800793          	li	a5,120
    80200ff4:	02f70663          	beq	a4,a5,80201020 <vprintfmt+0x254>
    80200ff8:	f5043783          	ld	a5,-176(s0)
    80200ffc:	0007c783          	lbu	a5,0(a5)
    80201000:	00078713          	mv	a4,a5
    80201004:	05800793          	li	a5,88
    80201008:	00f70c63          	beq	a4,a5,80201020 <vprintfmt+0x254>
    8020100c:	f5043783          	ld	a5,-176(s0)
    80201010:	0007c783          	lbu	a5,0(a5)
    80201014:	00078713          	mv	a4,a5
    80201018:	07000793          	li	a5,112
    8020101c:	30f71263          	bne	a4,a5,80201320 <vprintfmt+0x554>
                bool is_long = *fmt == 'p' || flags.longflag;
    80201020:	f5043783          	ld	a5,-176(s0)
    80201024:	0007c783          	lbu	a5,0(a5)
    80201028:	00078713          	mv	a4,a5
    8020102c:	07000793          	li	a5,112
    80201030:	00f70663          	beq	a4,a5,8020103c <vprintfmt+0x270>
    80201034:	f8144783          	lbu	a5,-127(s0)
    80201038:	00078663          	beqz	a5,80201044 <vprintfmt+0x278>
    8020103c:	00100793          	li	a5,1
    80201040:	0080006f          	j	80201048 <vprintfmt+0x27c>
    80201044:	00000793          	li	a5,0
    80201048:	faf403a3          	sb	a5,-89(s0)
    8020104c:	fa744783          	lbu	a5,-89(s0)
    80201050:	0017f793          	andi	a5,a5,1
    80201054:	faf403a3          	sb	a5,-89(s0)

                unsigned long num = is_long ? va_arg(vl, unsigned long) : va_arg(vl, unsigned int);
    80201058:	fa744783          	lbu	a5,-89(s0)
    8020105c:	0ff7f793          	zext.b	a5,a5
    80201060:	00078c63          	beqz	a5,80201078 <vprintfmt+0x2ac>
    80201064:	f4843783          	ld	a5,-184(s0)
    80201068:	00878713          	addi	a4,a5,8
    8020106c:	f4e43423          	sd	a4,-184(s0)
    80201070:	0007b783          	ld	a5,0(a5)
    80201074:	01c0006f          	j	80201090 <vprintfmt+0x2c4>
    80201078:	f4843783          	ld	a5,-184(s0)
    8020107c:	00878713          	addi	a4,a5,8
    80201080:	f4e43423          	sd	a4,-184(s0)
    80201084:	0007a783          	lw	a5,0(a5)
    80201088:	02079793          	slli	a5,a5,0x20
    8020108c:	0207d793          	srli	a5,a5,0x20
    80201090:	fef43023          	sd	a5,-32(s0)

                if (flags.prec == 0 && num == 0 && *fmt != 'p') {
    80201094:	f8c42783          	lw	a5,-116(s0)
    80201098:	02079463          	bnez	a5,802010c0 <vprintfmt+0x2f4>
    8020109c:	fe043783          	ld	a5,-32(s0)
    802010a0:	02079063          	bnez	a5,802010c0 <vprintfmt+0x2f4>
    802010a4:	f5043783          	ld	a5,-176(s0)
    802010a8:	0007c783          	lbu	a5,0(a5)
    802010ac:	00078713          	mv	a4,a5
    802010b0:	07000793          	li	a5,112
    802010b4:	00f70663          	beq	a4,a5,802010c0 <vprintfmt+0x2f4>
                    flags.in_format = false;
    802010b8:	f8040023          	sb	zero,-128(s0)
    802010bc:	4d00006f          	j	8020158c <vprintfmt+0x7c0>
                    continue;
                }

                // 0x prefix for pointers, or, if # flag is set and non-zero
                bool prefix = *fmt == 'p' || (flags.sharpflag && num != 0);
    802010c0:	f5043783          	ld	a5,-176(s0)
    802010c4:	0007c783          	lbu	a5,0(a5)
    802010c8:	00078713          	mv	a4,a5
    802010cc:	07000793          	li	a5,112
    802010d0:	00f70a63          	beq	a4,a5,802010e4 <vprintfmt+0x318>
    802010d4:	f8244783          	lbu	a5,-126(s0)
    802010d8:	00078a63          	beqz	a5,802010ec <vprintfmt+0x320>
    802010dc:	fe043783          	ld	a5,-32(s0)
    802010e0:	00078663          	beqz	a5,802010ec <vprintfmt+0x320>
    802010e4:	00100793          	li	a5,1
    802010e8:	0080006f          	j	802010f0 <vprintfmt+0x324>
    802010ec:	00000793          	li	a5,0
    802010f0:	faf40323          	sb	a5,-90(s0)
    802010f4:	fa644783          	lbu	a5,-90(s0)
    802010f8:	0017f793          	andi	a5,a5,1
    802010fc:	faf40323          	sb	a5,-90(s0)

                int hexdigits = 0;
    80201100:	fc042e23          	sw	zero,-36(s0)
                const char *xdigits = *fmt == 'X' ? upperxdigits : lowerxdigits;
    80201104:	f5043783          	ld	a5,-176(s0)
    80201108:	0007c783          	lbu	a5,0(a5)
    8020110c:	00078713          	mv	a4,a5
    80201110:	05800793          	li	a5,88
    80201114:	00f71863          	bne	a4,a5,80201124 <vprintfmt+0x358>
    80201118:	00001797          	auipc	a5,0x1
    8020111c:	09878793          	addi	a5,a5,152 # 802021b0 <upperxdigits.1>
    80201120:	00c0006f          	j	8020112c <vprintfmt+0x360>
    80201124:	00001797          	auipc	a5,0x1
    80201128:	0a478793          	addi	a5,a5,164 # 802021c8 <lowerxdigits.0>
    8020112c:	f8f43c23          	sd	a5,-104(s0)
                char buf[2 * sizeof(unsigned long)];

                do {
                    buf[hexdigits++] = xdigits[num & 0xf];
    80201130:	fe043783          	ld	a5,-32(s0)
    80201134:	00f7f793          	andi	a5,a5,15
    80201138:	f9843703          	ld	a4,-104(s0)
    8020113c:	00f70733          	add	a4,a4,a5
    80201140:	fdc42783          	lw	a5,-36(s0)
    80201144:	0017869b          	addiw	a3,a5,1
    80201148:	fcd42e23          	sw	a3,-36(s0)
    8020114c:	00074703          	lbu	a4,0(a4)
    80201150:	ff078793          	addi	a5,a5,-16
    80201154:	008787b3          	add	a5,a5,s0
    80201158:	f8e78023          	sb	a4,-128(a5)
                    num >>= 4;
    8020115c:	fe043783          	ld	a5,-32(s0)
    80201160:	0047d793          	srli	a5,a5,0x4
    80201164:	fef43023          	sd	a5,-32(s0)
                } while (num);
    80201168:	fe043783          	ld	a5,-32(s0)
    8020116c:	fc0792e3          	bnez	a5,80201130 <vprintfmt+0x364>

                if (flags.prec == -1 && flags.zeroflag) {
    80201170:	f8c42783          	lw	a5,-116(s0)
    80201174:	00078713          	mv	a4,a5
    80201178:	fff00793          	li	a5,-1
    8020117c:	02f71663          	bne	a4,a5,802011a8 <vprintfmt+0x3dc>
    80201180:	f8344783          	lbu	a5,-125(s0)
    80201184:	02078263          	beqz	a5,802011a8 <vprintfmt+0x3dc>
                    flags.prec = flags.width - 2 * prefix;
    80201188:	f8842703          	lw	a4,-120(s0)
    8020118c:	fa644783          	lbu	a5,-90(s0)
    80201190:	0007879b          	sext.w	a5,a5
    80201194:	0017979b          	slliw	a5,a5,0x1
    80201198:	0007879b          	sext.w	a5,a5
    8020119c:	40f707bb          	subw	a5,a4,a5
    802011a0:	0007879b          	sext.w	a5,a5
    802011a4:	f8f42623          	sw	a5,-116(s0)
                }

                for (int i = flags.width - 2 * prefix - __MAX(hexdigits, flags.prec); i > 0; i--) {
    802011a8:	f8842703          	lw	a4,-120(s0)
    802011ac:	fa644783          	lbu	a5,-90(s0)
    802011b0:	0007879b          	sext.w	a5,a5
    802011b4:	0017979b          	slliw	a5,a5,0x1
    802011b8:	0007879b          	sext.w	a5,a5
    802011bc:	40f707bb          	subw	a5,a4,a5
    802011c0:	0007871b          	sext.w	a4,a5
    802011c4:	fdc42783          	lw	a5,-36(s0)
    802011c8:	f8f42a23          	sw	a5,-108(s0)
    802011cc:	f8c42783          	lw	a5,-116(s0)
    802011d0:	f8f42823          	sw	a5,-112(s0)
    802011d4:	f9442783          	lw	a5,-108(s0)
    802011d8:	00078593          	mv	a1,a5
    802011dc:	f9042783          	lw	a5,-112(s0)
    802011e0:	00078613          	mv	a2,a5
    802011e4:	0006069b          	sext.w	a3,a2
    802011e8:	0005879b          	sext.w	a5,a1
    802011ec:	00f6d463          	bge	a3,a5,802011f4 <vprintfmt+0x428>
    802011f0:	00058613          	mv	a2,a1
    802011f4:	0006079b          	sext.w	a5,a2
    802011f8:	40f707bb          	subw	a5,a4,a5
    802011fc:	fcf42c23          	sw	a5,-40(s0)
    80201200:	0280006f          	j	80201228 <vprintfmt+0x45c>
                    putch(' ');
    80201204:	f5843783          	ld	a5,-168(s0)
    80201208:	02000513          	li	a0,32
    8020120c:	000780e7          	jalr	a5
                    ++written;
    80201210:	fec42783          	lw	a5,-20(s0)
    80201214:	0017879b          	addiw	a5,a5,1
    80201218:	fef42623          	sw	a5,-20(s0)
                for (int i = flags.width - 2 * prefix - __MAX(hexdigits, flags.prec); i > 0; i--) {
    8020121c:	fd842783          	lw	a5,-40(s0)
    80201220:	fff7879b          	addiw	a5,a5,-1
    80201224:	fcf42c23          	sw	a5,-40(s0)
    80201228:	fd842783          	lw	a5,-40(s0)
    8020122c:	0007879b          	sext.w	a5,a5
    80201230:	fcf04ae3          	bgtz	a5,80201204 <vprintfmt+0x438>
                }

                if (prefix) {
    80201234:	fa644783          	lbu	a5,-90(s0)
    80201238:	0ff7f793          	zext.b	a5,a5
    8020123c:	04078463          	beqz	a5,80201284 <vprintfmt+0x4b8>
                    putch('0');
    80201240:	f5843783          	ld	a5,-168(s0)
    80201244:	03000513          	li	a0,48
    80201248:	000780e7          	jalr	a5
                    putch(*fmt == 'X' ? 'X' : 'x');
    8020124c:	f5043783          	ld	a5,-176(s0)
    80201250:	0007c783          	lbu	a5,0(a5)
    80201254:	00078713          	mv	a4,a5
    80201258:	05800793          	li	a5,88
    8020125c:	00f71663          	bne	a4,a5,80201268 <vprintfmt+0x49c>
    80201260:	05800793          	li	a5,88
    80201264:	0080006f          	j	8020126c <vprintfmt+0x4a0>
    80201268:	07800793          	li	a5,120
    8020126c:	f5843703          	ld	a4,-168(s0)
    80201270:	00078513          	mv	a0,a5
    80201274:	000700e7          	jalr	a4
                    written += 2;
    80201278:	fec42783          	lw	a5,-20(s0)
    8020127c:	0027879b          	addiw	a5,a5,2
    80201280:	fef42623          	sw	a5,-20(s0)
                }

                for (int i = hexdigits; i < flags.prec; i++) {
    80201284:	fdc42783          	lw	a5,-36(s0)
    80201288:	fcf42a23          	sw	a5,-44(s0)
    8020128c:	0280006f          	j	802012b4 <vprintfmt+0x4e8>
                    putch('0');
    80201290:	f5843783          	ld	a5,-168(s0)
    80201294:	03000513          	li	a0,48
    80201298:	000780e7          	jalr	a5
                    ++written;
    8020129c:	fec42783          	lw	a5,-20(s0)
    802012a0:	0017879b          	addiw	a5,a5,1
    802012a4:	fef42623          	sw	a5,-20(s0)
                for (int i = hexdigits; i < flags.prec; i++) {
    802012a8:	fd442783          	lw	a5,-44(s0)
    802012ac:	0017879b          	addiw	a5,a5,1
    802012b0:	fcf42a23          	sw	a5,-44(s0)
    802012b4:	f8c42703          	lw	a4,-116(s0)
    802012b8:	fd442783          	lw	a5,-44(s0)
    802012bc:	0007879b          	sext.w	a5,a5
    802012c0:	fce7c8e3          	blt	a5,a4,80201290 <vprintfmt+0x4c4>
                }

                for (int i = hexdigits - 1; i >= 0; i--) {
    802012c4:	fdc42783          	lw	a5,-36(s0)
    802012c8:	fff7879b          	addiw	a5,a5,-1
    802012cc:	fcf42823          	sw	a5,-48(s0)
    802012d0:	03c0006f          	j	8020130c <vprintfmt+0x540>
                    putch(buf[i]);
    802012d4:	fd042783          	lw	a5,-48(s0)
    802012d8:	ff078793          	addi	a5,a5,-16
    802012dc:	008787b3          	add	a5,a5,s0
    802012e0:	f807c783          	lbu	a5,-128(a5)
    802012e4:	0007871b          	sext.w	a4,a5
    802012e8:	f5843783          	ld	a5,-168(s0)
    802012ec:	00070513          	mv	a0,a4
    802012f0:	000780e7          	jalr	a5
                    ++written;
    802012f4:	fec42783          	lw	a5,-20(s0)
    802012f8:	0017879b          	addiw	a5,a5,1
    802012fc:	fef42623          	sw	a5,-20(s0)
                for (int i = hexdigits - 1; i >= 0; i--) {
    80201300:	fd042783          	lw	a5,-48(s0)
    80201304:	fff7879b          	addiw	a5,a5,-1
    80201308:	fcf42823          	sw	a5,-48(s0)
    8020130c:	fd042783          	lw	a5,-48(s0)
    80201310:	0007879b          	sext.w	a5,a5
    80201314:	fc07d0e3          	bgez	a5,802012d4 <vprintfmt+0x508>
                }

                flags.in_format = false;
    80201318:	f8040023          	sb	zero,-128(s0)
            } else if (*fmt == 'x' || *fmt == 'X' || *fmt == 'p') {
    8020131c:	2700006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == 'd' || *fmt == 'i' || *fmt == 'u') {
    80201320:	f5043783          	ld	a5,-176(s0)
    80201324:	0007c783          	lbu	a5,0(a5)
    80201328:	00078713          	mv	a4,a5
    8020132c:	06400793          	li	a5,100
    80201330:	02f70663          	beq	a4,a5,8020135c <vprintfmt+0x590>
    80201334:	f5043783          	ld	a5,-176(s0)
    80201338:	0007c783          	lbu	a5,0(a5)
    8020133c:	00078713          	mv	a4,a5
    80201340:	06900793          	li	a5,105
    80201344:	00f70c63          	beq	a4,a5,8020135c <vprintfmt+0x590>
    80201348:	f5043783          	ld	a5,-176(s0)
    8020134c:	0007c783          	lbu	a5,0(a5)
    80201350:	00078713          	mv	a4,a5
    80201354:	07500793          	li	a5,117
    80201358:	08f71063          	bne	a4,a5,802013d8 <vprintfmt+0x60c>
                long num = flags.longflag ? va_arg(vl, long) : va_arg(vl, int);
    8020135c:	f8144783          	lbu	a5,-127(s0)
    80201360:	00078c63          	beqz	a5,80201378 <vprintfmt+0x5ac>
    80201364:	f4843783          	ld	a5,-184(s0)
    80201368:	00878713          	addi	a4,a5,8
    8020136c:	f4e43423          	sd	a4,-184(s0)
    80201370:	0007b783          	ld	a5,0(a5)
    80201374:	0140006f          	j	80201388 <vprintfmt+0x5bc>
    80201378:	f4843783          	ld	a5,-184(s0)
    8020137c:	00878713          	addi	a4,a5,8
    80201380:	f4e43423          	sd	a4,-184(s0)
    80201384:	0007a783          	lw	a5,0(a5)
    80201388:	faf43423          	sd	a5,-88(s0)

                written += print_dec_int(putch, num, *fmt != 'u', &flags);
    8020138c:	fa843583          	ld	a1,-88(s0)
    80201390:	f5043783          	ld	a5,-176(s0)
    80201394:	0007c783          	lbu	a5,0(a5)
    80201398:	0007871b          	sext.w	a4,a5
    8020139c:	07500793          	li	a5,117
    802013a0:	40f707b3          	sub	a5,a4,a5
    802013a4:	00f037b3          	snez	a5,a5
    802013a8:	0ff7f793          	zext.b	a5,a5
    802013ac:	f8040713          	addi	a4,s0,-128
    802013b0:	00070693          	mv	a3,a4
    802013b4:	00078613          	mv	a2,a5
    802013b8:	f5843503          	ld	a0,-168(s0)
    802013bc:	f08ff0ef          	jal	80200ac4 <print_dec_int>
    802013c0:	00050793          	mv	a5,a0
    802013c4:	fec42703          	lw	a4,-20(s0)
    802013c8:	00f707bb          	addw	a5,a4,a5
    802013cc:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
    802013d0:	f8040023          	sb	zero,-128(s0)
            } else if (*fmt == 'd' || *fmt == 'i' || *fmt == 'u') {
    802013d4:	1b80006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == 'n') {
    802013d8:	f5043783          	ld	a5,-176(s0)
    802013dc:	0007c783          	lbu	a5,0(a5)
    802013e0:	00078713          	mv	a4,a5
    802013e4:	06e00793          	li	a5,110
    802013e8:	04f71c63          	bne	a4,a5,80201440 <vprintfmt+0x674>
                if (flags.longflag) {
    802013ec:	f8144783          	lbu	a5,-127(s0)
    802013f0:	02078463          	beqz	a5,80201418 <vprintfmt+0x64c>
                    long *n = va_arg(vl, long *);
    802013f4:	f4843783          	ld	a5,-184(s0)
    802013f8:	00878713          	addi	a4,a5,8
    802013fc:	f4e43423          	sd	a4,-184(s0)
    80201400:	0007b783          	ld	a5,0(a5)
    80201404:	faf43823          	sd	a5,-80(s0)
                    *n = written;
    80201408:	fec42703          	lw	a4,-20(s0)
    8020140c:	fb043783          	ld	a5,-80(s0)
    80201410:	00e7b023          	sd	a4,0(a5)
    80201414:	0240006f          	j	80201438 <vprintfmt+0x66c>
                } else {
                    int *n = va_arg(vl, int *);
    80201418:	f4843783          	ld	a5,-184(s0)
    8020141c:	00878713          	addi	a4,a5,8
    80201420:	f4e43423          	sd	a4,-184(s0)
    80201424:	0007b783          	ld	a5,0(a5)
    80201428:	faf43c23          	sd	a5,-72(s0)
                    *n = written;
    8020142c:	fb843783          	ld	a5,-72(s0)
    80201430:	fec42703          	lw	a4,-20(s0)
    80201434:	00e7a023          	sw	a4,0(a5)
                }
                flags.in_format = false;
    80201438:	f8040023          	sb	zero,-128(s0)
    8020143c:	1500006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == 's') {
    80201440:	f5043783          	ld	a5,-176(s0)
    80201444:	0007c783          	lbu	a5,0(a5)
    80201448:	00078713          	mv	a4,a5
    8020144c:	07300793          	li	a5,115
    80201450:	02f71e63          	bne	a4,a5,8020148c <vprintfmt+0x6c0>
                const char *s = va_arg(vl, const char *);
    80201454:	f4843783          	ld	a5,-184(s0)
    80201458:	00878713          	addi	a4,a5,8
    8020145c:	f4e43423          	sd	a4,-184(s0)
    80201460:	0007b783          	ld	a5,0(a5)
    80201464:	fcf43023          	sd	a5,-64(s0)
                written += puts_wo_nl(putch, s);
    80201468:	fc043583          	ld	a1,-64(s0)
    8020146c:	f5843503          	ld	a0,-168(s0)
    80201470:	dccff0ef          	jal	80200a3c <puts_wo_nl>
    80201474:	00050793          	mv	a5,a0
    80201478:	fec42703          	lw	a4,-20(s0)
    8020147c:	00f707bb          	addw	a5,a4,a5
    80201480:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
    80201484:	f8040023          	sb	zero,-128(s0)
    80201488:	1040006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == 'c') {
    8020148c:	f5043783          	ld	a5,-176(s0)
    80201490:	0007c783          	lbu	a5,0(a5)
    80201494:	00078713          	mv	a4,a5
    80201498:	06300793          	li	a5,99
    8020149c:	02f71e63          	bne	a4,a5,802014d8 <vprintfmt+0x70c>
                int ch = va_arg(vl, int);
    802014a0:	f4843783          	ld	a5,-184(s0)
    802014a4:	00878713          	addi	a4,a5,8
    802014a8:	f4e43423          	sd	a4,-184(s0)
    802014ac:	0007a783          	lw	a5,0(a5)
    802014b0:	fcf42623          	sw	a5,-52(s0)
                putch(ch);
    802014b4:	fcc42703          	lw	a4,-52(s0)
    802014b8:	f5843783          	ld	a5,-168(s0)
    802014bc:	00070513          	mv	a0,a4
    802014c0:	000780e7          	jalr	a5
                ++written;
    802014c4:	fec42783          	lw	a5,-20(s0)
    802014c8:	0017879b          	addiw	a5,a5,1
    802014cc:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
    802014d0:	f8040023          	sb	zero,-128(s0)
    802014d4:	0b80006f          	j	8020158c <vprintfmt+0x7c0>
            } else if (*fmt == '%') {
    802014d8:	f5043783          	ld	a5,-176(s0)
    802014dc:	0007c783          	lbu	a5,0(a5)
    802014e0:	00078713          	mv	a4,a5
    802014e4:	02500793          	li	a5,37
    802014e8:	02f71263          	bne	a4,a5,8020150c <vprintfmt+0x740>
                putch('%');
    802014ec:	f5843783          	ld	a5,-168(s0)
    802014f0:	02500513          	li	a0,37
    802014f4:	000780e7          	jalr	a5
                ++written;
    802014f8:	fec42783          	lw	a5,-20(s0)
    802014fc:	0017879b          	addiw	a5,a5,1
    80201500:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
    80201504:	f8040023          	sb	zero,-128(s0)
    80201508:	0840006f          	j	8020158c <vprintfmt+0x7c0>
            } else {
                putch(*fmt);
    8020150c:	f5043783          	ld	a5,-176(s0)
    80201510:	0007c783          	lbu	a5,0(a5)
    80201514:	0007871b          	sext.w	a4,a5
    80201518:	f5843783          	ld	a5,-168(s0)
    8020151c:	00070513          	mv	a0,a4
    80201520:	000780e7          	jalr	a5
                ++written;
    80201524:	fec42783          	lw	a5,-20(s0)
    80201528:	0017879b          	addiw	a5,a5,1
    8020152c:	fef42623          	sw	a5,-20(s0)
                flags.in_format = false;
    80201530:	f8040023          	sb	zero,-128(s0)
    80201534:	0580006f          	j	8020158c <vprintfmt+0x7c0>
            }
        } else if (*fmt == '%') {
    80201538:	f5043783          	ld	a5,-176(s0)
    8020153c:	0007c783          	lbu	a5,0(a5)
    80201540:	00078713          	mv	a4,a5
    80201544:	02500793          	li	a5,37
    80201548:	02f71063          	bne	a4,a5,80201568 <vprintfmt+0x79c>
            flags = (struct fmt_flags) {.in_format = true, .prec = -1};
    8020154c:	f8043023          	sd	zero,-128(s0)
    80201550:	f8043423          	sd	zero,-120(s0)
    80201554:	00100793          	li	a5,1
    80201558:	f8f40023          	sb	a5,-128(s0)
    8020155c:	fff00793          	li	a5,-1
    80201560:	f8f42623          	sw	a5,-116(s0)
    80201564:	0280006f          	j	8020158c <vprintfmt+0x7c0>
        } else {
            putch(*fmt);
    80201568:	f5043783          	ld	a5,-176(s0)
    8020156c:	0007c783          	lbu	a5,0(a5)
    80201570:	0007871b          	sext.w	a4,a5
    80201574:	f5843783          	ld	a5,-168(s0)
    80201578:	00070513          	mv	a0,a4
    8020157c:	000780e7          	jalr	a5
            ++written;
    80201580:	fec42783          	lw	a5,-20(s0)
    80201584:	0017879b          	addiw	a5,a5,1
    80201588:	fef42623          	sw	a5,-20(s0)
    for (; *fmt; fmt++) {
    8020158c:	f5043783          	ld	a5,-176(s0)
    80201590:	00178793          	addi	a5,a5,1
    80201594:	f4f43823          	sd	a5,-176(s0)
    80201598:	f5043783          	ld	a5,-176(s0)
    8020159c:	0007c783          	lbu	a5,0(a5)
    802015a0:	84079ce3          	bnez	a5,80200df8 <vprintfmt+0x2c>
        }
    }

    return written;
    802015a4:	fec42783          	lw	a5,-20(s0)
}
    802015a8:	00078513          	mv	a0,a5
    802015ac:	0b813083          	ld	ra,184(sp)
    802015b0:	0b013403          	ld	s0,176(sp)
    802015b4:	0c010113          	addi	sp,sp,192
    802015b8:	00008067          	ret

00000000802015bc <printk>:

int printk(const char* s, ...) {
    802015bc:	f9010113          	addi	sp,sp,-112
    802015c0:	02113423          	sd	ra,40(sp)
    802015c4:	02813023          	sd	s0,32(sp)
    802015c8:	03010413          	addi	s0,sp,48
    802015cc:	fca43c23          	sd	a0,-40(s0)
    802015d0:	00b43423          	sd	a1,8(s0)
    802015d4:	00c43823          	sd	a2,16(s0)
    802015d8:	00d43c23          	sd	a3,24(s0)
    802015dc:	02e43023          	sd	a4,32(s0)
    802015e0:	02f43423          	sd	a5,40(s0)
    802015e4:	03043823          	sd	a6,48(s0)
    802015e8:	03143c23          	sd	a7,56(s0)
    int res = 0;
    802015ec:	fe042623          	sw	zero,-20(s0)
    va_list vl;
    va_start(vl, s);
    802015f0:	04040793          	addi	a5,s0,64
    802015f4:	fcf43823          	sd	a5,-48(s0)
    802015f8:	fd043783          	ld	a5,-48(s0)
    802015fc:	fc878793          	addi	a5,a5,-56
    80201600:	fef43023          	sd	a5,-32(s0)
    res = vprintfmt(putc, s, vl);
    80201604:	fe043783          	ld	a5,-32(s0)
    80201608:	00078613          	mv	a2,a5
    8020160c:	fd843583          	ld	a1,-40(s0)
    80201610:	fffff517          	auipc	a0,0xfffff
    80201614:	11850513          	addi	a0,a0,280 # 80200728 <putc>
    80201618:	fb4ff0ef          	jal	80200dcc <vprintfmt>
    8020161c:	00050793          	mv	a5,a0
    80201620:	fef42623          	sw	a5,-20(s0)
    va_end(vl);
    return res;
    80201624:	fec42783          	lw	a5,-20(s0)
}
    80201628:	00078513          	mv	a0,a5
    8020162c:	02813083          	ld	ra,40(sp)
    80201630:	02013403          	ld	s0,32(sp)
    80201634:	07010113          	addi	sp,sp,112
    80201638:	00008067          	ret
