`ifndef __ADDR_SPACE__
    `define __ADDR_SPACE__

typedef enum {
    CHIP_ZERO = 0,
    CHIP_ROM,
    CHIP_UART,
    CHIP_RAM,
    CHIP_LAST
} chip_index;

typedef enum {
    MASTER_IF = 0,
    MASTER_MA,
    MASTER_TEST,
    MASTER_LAST
} master_index;

`endif
