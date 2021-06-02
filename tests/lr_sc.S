.text
.global _start
_start:

    li tp, 0x80000000
    mv a0, zero
    sd a0, (tp)

    li a1, 0x1
    li t1, 0x1
    nop
    nop

0:  lr.d t0, (tp)
    bne t0, a0, 1f
    sc.d.rl t1, a1, (tp)
    bnez t1, 0b
    fence rw, rw

1:  nop
    nop
    nop
    nop
    wfi

