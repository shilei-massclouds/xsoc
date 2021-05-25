.text
.global _start
_start:

    li tp, 0x10000000
    la t1, msg

_loop:
    lb t0, (t1)
    beqz t0, _end
    sb t0, 0(tp)
    addi t1, t1, 1
    j _loop

_end:
    wfi

.word 1
msg:
    .string "Hello! World!\n"

