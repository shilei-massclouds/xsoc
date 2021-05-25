.text
.global _start
_start:

    la t0, stone
    ld t1, (t0)
    lw t2, (t0)
    lh t3, (t0)
    lb t4, (t0)
    nop
    wfi

.align 3
stone:
    .dword 0xA0B0C0D0E0F01020

