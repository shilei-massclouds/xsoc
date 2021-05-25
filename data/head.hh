#ifndef _MCPU_HEAD_H_
#define _MCPU_HEAD_H_

/*
 * ZERO-PAGE is the first page.
 * ROM starts from the second page.
 */
#define ROM_BASE 0x1000

/*
 * Head(0x0 ~ 0x100): Relocate dtb, sbi and payload and jump to fw_jump.
 * DTB(0x100 ~ 0x2000): FDT for this platform.
 * SBI(0x2000 ~ 0x20000): SBI fw_jump.
 * Payload(0x20000 ~ ): U-boot spl or test.bin.
 */
#define DTB_LOAD_ADDR       (ROM_BASE + 0x100)
#define SBI_LOAD_ADDR       (ROM_BASE + 0x2000)
#define PAYLOAD_LOAD_ADDR   (ROM_BASE + 0x20000)

#define SBI_LINK_ADDR       0x80000000
#define PAYLOAD_LINK_ADDR   0x80200000

#endif /* _MCPU_HEAD_H_ */
