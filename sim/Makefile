# ============================================================
# Makefile - AXI4-Lite UVM Verification
# Engineer: plandge
# ============================================================

VLOG       = vlog
VSIM       = vsim

UVM_HOME   ?= $(shell echo $$UVM_HOME)

RTL_DIR    = ../rtl
TB_DIR     = ../tb

RTL_FILES  = $(RTL_DIR)/axil_reg_if_wr.v \
             $(RTL_DIR)/axil_reg_if_rd.v \
             $(RTL_DIR)/axi_lite_slave.v

TB_TOP     = $(TB_DIR)/top.sv

TOP_MODULE = top
UVM_TEST  ?= axi_lite_base_test
SEED ?= random
VLOG_FLAGS = -sv \
             +incdir+$(UVM_HOME)/src \
             $(UVM_HOME)/src/uvm_pkg.sv \
             +incdir+$(TB_DIR)

VSIM_FLAGS = -batch \
             -sv_lib $(HOME)/axi_lite_uvm_verif/sim/uvm_dpi/uvm_dpi \
             +UVM_TESTNAME=$(UVM_TEST) \
             +UVM_VERBOSITY=UVM_LOW \
             -sv_seed $(SEED)\
             -do "run -all; quit"

.PHONY: compile sim run clean help

all: run

compile:
	@echo "========================================"
	@echo " Compiling RTL + Testbench..."
	@echo "========================================"
	$(VLOG) $(VLOG_FLAGS) $(RTL_FILES) $(TB_TOP)
	@echo "========================================"
	@echo " Compilation done."
	@echo "========================================"

sim:
	@echo "========================================"
	@echo " Running simulation: $(UVM_TEST)"
	@echo "========================================"
	$(VSIM) $(VSIM_FLAGS) $(TOP_MODULE)
	@echo "========================================"
	@echo " Simulation done."
	@echo "========================================"

run: compile sim


gui: compile
	@echo "========================================"
	@echo " Launching QuestaSim GUI..."
	@echo "========================================"
	$(VSIM) -gui \
	         -sv_lib $(HOME)/axi_lite_uvm_verif/sim/uvm_dpi/uvm_dpi \
	         +UVM_TESTNAME=$(UVM_TEST) \
	         +UVM_VERBOSITY=UVM_LOW \
	         -do run.do \
	         $(TOP_MODULE) &

regression: compile
	@echo "========================================"
	@echo " Running Regression: 5 seeds"
	@echo "========================================"
	@for seed in 12345 99999 42 777 31415; do \
		echo "--- Seed: $$seed ---"; \
		$(VSIM) -batch \
			-sv_lib $(HOME)/axi_lite_uvm_verif/sim/uvm_dpi/uvm_dpi \
			+UVM_TESTNAME=$(UVM_TEST) \
			+UVM_VERBOSITY=UVM_LOW \
			-sv_seed $$seed \
			-do "run -all; quit" \
			$(TOP_MODULE) 2>&1 | \
			grep "FINAL REPORT\|RESULT\|UVM_ERROR"; \
	done
	@echo "========================================"
	@echo " Regression complete."
	@echo "========================================"

                   
clean:
	@echo " Cleaning up..."
	rm -rf work transcript vsim.wlf *.log *.ucdb
	@echo " Clean done."

help:
	@echo ""
	@echo "  make compile              compile RTL + TB"
	@echo "  make sim                  run default test"
	@echo "  make run                  compile + simulate"
	@echo "  make sim UVM_TEST=<name>  run specific test"
	@echo "  make clean                delete build files"
	@echo ""
