.text
.global _start
_start:

    li t0, 2
    li t1, 1
    bge t0, t1, _else
    mv t2, t1
    j _end

_else:
    mv t2, t0

_end:
    wfi
    nop
    nop
