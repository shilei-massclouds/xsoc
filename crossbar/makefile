TOP_DIR = ..
COMMON_DIR = ${TOP_DIR}/common

BASE = crossbar

SRC = ./tb_crossbar.sv ./stimulator.sv ./crossbar.sv \
	  ./arbiter.sv ./crossbar_ctl.sv ./crossbar_dp.sv ./pma.sv \
	  ../rom/stub/rom_stub.sv ../ram/ram.sv \
	  ${COMMON_DIR}/zero_page.sv ${COMMON_DIR}/uart.sv ${COMMON_DIR}/load.c \
	  ${COMMON_DIR}/clk_rst.sv ${COMMON_DIR}/tilelink.sv ${COMMON_DIR}/dff.sv

include ${TOP_DIR}/makefile.common

