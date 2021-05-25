TOP_DIR = ..
COMMON_DIR = ${TOP_DIR}/common

BASE = decode

SRC = ./tb_decode.sv ./decode.sv ./stage_id_ex.sv \
	  ./dec32.sv ./dec16.sv ./dec_sel.sv \
	  ${COMMON_DIR}/dff.sv ${COMMON_DIR}/clk_rst.sv \
	  ${COMMON_DIR}/regfile.sv \
	  ${COMMON_DIR}/alu_ops.sv ${COMMON_DIR}/io_ops.sv \
	  ${COMMON_DIR}/bj_ops.sv ${COMMON_DIR}/sys_ops.sv

include ${TOP_DIR}/makefile.common
