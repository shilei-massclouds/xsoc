.text
.global _start
_start:

    li t0, 2
    li t1, 1
    j _end
    mv t2, t1

_end:
    mv t2, t0
    wfi
