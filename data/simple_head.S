#include "head.hh"

.global _start
_start:

    csrr    a0, mhartid
    li      a1, DTB_LOAD_ADDR
    li      t0, SBI_LINK_ADDR
    jr      t0

