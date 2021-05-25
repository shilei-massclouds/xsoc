TOP_DIR = ..
COMMON_DIR = ${TOP_DIR}/common

BASE = instcache

SRC = ./tb_instcache.sv ./stimulator.sv ./instcache.sv ./dbg_instcache.sv \
	  ../rom/stub/rom_stub.sv ../rom/stub/dbg_rom.sv \
	  ${COMMON_DIR}/clk_rst.sv ${COMMON_DIR}/dff.sv ${COMMON_DIR}/tilelink.sv \
	  ${COMMON_DIR}/load.c ${COMMON_DIR}/debug.c

include ${TOP_DIR}/makefile.common

test: build
	TEST=tests/bj_ge ${SIM}
