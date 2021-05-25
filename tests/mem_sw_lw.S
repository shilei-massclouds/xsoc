.text
.global _start
_start:

li a0, 0x0A0B0C0D01020304
li tp, 0x80000000
sw a0, 0x12(tp)
lw a1, 0x12(tp)
lb a2, 0x12(tp)
sd a0, 0x18(tp)
ld a1, 0x18(tp)
lh a2, 0x18(tp)
ld a1, 0x18(tp)
lh a2, 0x18(tp)
nop
wfi
