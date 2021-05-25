.text
.global _start
_start:

li t0, 0x5
li t1, 0x3
add t2, t0, t1

li t0, 0x5
li t1, 0x3
addw t2, t0, t1

wfi
