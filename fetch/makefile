TOP_DIR = ..
COMMON_DIR = ${TOP_DIR}/common

BASE = fetch

SRC = ./tb_fetch.sv ./fetch.sv ./pc_ctl.sv ./stage_if_id.sv \
	  ../instcache/instcache.sv ../rom/stub/rom_stub.sv \
	  ${COMMON_DIR}/clk_rst.sv ${COMMON_DIR}/dff.sv ${COMMON_DIR}/tilelink.sv \
	  ${COMMON_DIR}/load.c

include ${TOP_DIR}/makefile.common
