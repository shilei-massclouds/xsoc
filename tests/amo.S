.text
.global _start
_start:

li a0, 0x0A0B0C0D01020304
li tp, 0x80000000
sd a0, (tp)
ld a1, (tp)
li a0, 0xAAAAAAAA
sw a0, 4(tp)

li a2, -1
amoadd.w a3, a2, (tp)
ld a3, (tp)
amoxor.w a4, a2, (tp)
ld a4, (tp)
amoor.w a5, a2, (tp)
ld a5, (tp)
li a2, 0xAAAAAAAA
amoand.w a6, a2, (tp)
ld a6, (tp)

nop
nop
nop
nop

wfi
