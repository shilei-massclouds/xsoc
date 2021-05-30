TOP_DIR = .
COMMON_DIR = ${TOP_DIR}/common

BASE = soc

SRC = ./soc.sv ./cpu.sv \
	  ./fetch/fetch.sv ./fetch/pc_ctl.sv ./fetch/stage_if_id.sv ./fetch/dbg_fetch.sv \
	  ./decode/decode.sv ./decode/dbg_decode.sv ./decode/stage_id_ex.sv \
	  ./decode/dec32.sv ./decode/dec16.sv ./decode/dec_sel.sv \
	  ./execute/execute.sv ./execute/stage_ex_ma.sv ./execute/alu.sv \
	  ./execute/jmp_br.sv ./execute/csr_ecall.sv ./execute/dbg_execute.sv \
	  ./access/access.sv ./access/stage_ma_wb.sv ./access/dataagent.sv \
	  ./access/dbg_access.sv \
	  ./instcache/instcache.sv ./instcache/dbg_instcache.sv \
	  ./datacache/datacache.sv ./datacache/dbg_datacache.sv \
	  ./rom/stub/rom_stub.sv ./rom/stub/dbg_rom.sv \
	  ./ram/ram.sv ./ram/dbg_ram.sv \
	  ./uart/stub/uart_stub.sv ./uart/stub/uart.c \
	  ./crossbar/crossbar.sv ./crossbar/arbiter.sv ./crossbar/pma.sv \
	  ./crossbar/crossbar_ctl.sv ./crossbar/crossbar_dp.sv \
	  ./crossbar/dbg_crossbar_dp.sv \
	  ${COMMON_DIR}/regfile.sv ${COMMON_DIR}/dbg_regfile.sv \
	  ${COMMON_DIR}/clk_rst.sv ${COMMON_DIR}/dff.sv ${COMMON_DIR}/tilelink.sv \
	  ${COMMON_DIR}/zero_page.sv \
	  ${COMMON_DIR}/forward.sv \
	  ${COMMON_DIR}/csr.sv \
	  ${COMMON_DIR}/mmu.sv \
	  ${COMMON_DIR}/alu_ops.sv ${COMMON_DIR}/io_ops.sv \
	  ${COMMON_DIR}/bj_ops.sv ${COMMON_DIR}/sys_ops.sv \
	  ${COMMON_DIR}/load.c ${COMMON_DIR}/debug.c

include ${TOP_DIR}/makefile.common

head:
	make -C data

build: head

test: build
	make -C tests
	TEST=tests/calc_add ${SIM}
	TEST=tests/mem_sw_lw ${SIM}
	TEST=tests/bj_ge ${SIM}
	TEST=tests/j ${SIM}
	TEST=tests/rom_load ${SIM}
	TEST=tests/uart_wr ${SIM}
	TEST=tests/paging ${SIM}
