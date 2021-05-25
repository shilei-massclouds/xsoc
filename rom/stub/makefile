TOP_DIR = ../..
COMMON_DIR = ${TOP_DIR}/common

BASE = rom

SRC = ./tb_rom.sv ../stimulator.sv ./rom_stub.sv ./dbg_rom.sv ./assert_rom.sv \
	  ${COMMON_DIR}/clk_rst.sv ${COMMON_DIR}/dff.sv ${COMMON_DIR}/tilelink.sv \
	  ${COMMON_DIR}/load.c

include ${TOP_DIR}/makefile.common
