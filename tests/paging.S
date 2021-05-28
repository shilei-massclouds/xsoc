/* Paging test */

#include "test.h"

.text
.global _start
_start:

    /* Zero pgd, pmd and pt area */
    li t0, PG_DIR
    li t1, PT + 0x1000
1:
    sd zero, (t0)
    addi t0, t0, 8
    blt t0, t1, 1b

    /* Set tempory trap vector */
    la a0, 2f
    csrw CSR_MTVEC, a0

    /* a6 <= _lottery(phy) */
    la a6, _lottery

    /* a5 <= _lottery(virt) */
    li a1, TEST_VIRT_ADDR
    li a2, TEST_PHY_ADDR
    sub a1, a1, a2
    add a5, a6, a1

    /* vpn1 * pte_size */
    mv t0, a5
    srl t0, t0, 12
    andi t0, t0, 0x1FF
    sll t0, t0, 3

    /* pte of pt */
    srl t2, a6, 12
    sll t2, t2, 10
    ori t2, t2, 0x7

    /* Setup pt */
    li t1, PT
    add t1, t1, t0
    sd t2, (t1)

    /* vpn2 * pte_size */
    mv t0, a5
    srl t0, t0, 21
    andi t0, t0, 0x1FF
    sll t0, t0, 3

    /* pte of pmd */
    li t2, PT
    srl t2, t2, 12
    sll t2, t2, 10
    ori t2, t2, 0x1

    /* Setup pmd */
    li t1, PM_DIR
    add t1, t1, t0
    sd t2, (t1)

    /* vpn3 * pte_size */
    mv t0, a5
    srl t0, t0, 30
    andi t0, t0, 0x1FF
    sll t0, t0, 3

    /* pte of pgd */
    li t2, PM_DIR
    srl t2, t2, 12
    sll t2, t2, 10
    ori t2, t2, 0x1

    /* Setup pgd */
    li t1, PG_DIR
    add t1, t1, t0
    sd t2, (t1)

    /* Setup satp */
    li t1, PG_DIR
    srl t1, t1, PAGE_SHIFT
    li t0, SATP_MODE
    or t1, t0, t1
    sfence.vma
    csrw CSR_SATP, t1

2:
    ld a5, (a5)
    xor a0, a0, a0

_end:
    wfi
    nop
    nop

.align 3
_lottery:
    .dword 0x1234
