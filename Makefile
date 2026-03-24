# ==========================================
# RISC-V Pipeline - Verification Makefile (Vivado XSIM)
# ==========================================

# --- Toolchain definition ---
XVLOG   = xvlog
XELAB   = xelab
XSIM    = xsim
LINTER  = verilator
PYTHON  = python3

# --- RISC-V toolchain ---
RV_PREFIX = riscv32-unknown-elf
RV_AS     = $(RV_PREFIX)-as
RV_LD     = $(RV_PREFIX)-ld
RV_OBJCOPY = $(RV_PREFIX)-objcopy

# --- Project configuration ---
TEST_TYPE ?= system
TB_TOP    ?= tb_top
RTL_TOP   ?= soc_top
UNIT      ?= alu

# --- Directories ---
FILELIST_DIR = filelists
SIM_DIR      = sim
SIM_OUT      = $(SIM_DIR)/out

SIM_LOGS  = $(SIM_OUT)/logs
SIM_SNAPS = $(SIM_OUT)/snaps
SIM_WAVES = $(SIM_OUT)/waves

# --- Filelists ---
RTL_FILELIST = $(FILELIST_DIR)/rtl.f
TB_FILELIST  = $(FILELIST_DIR)/tb_$(TEST_TYPE).f

# --- Tool flags ---
LINT_FLAGS = --lint-only -Wall -sv --top-module $(RTL_TOP)

# Progress markers
LINT_MARKER    = $(SIM_OUT)/.lint.done
COMPILE_MARKER = $(SIM_OUT)/.compile.$(TEST_TYPE).done
ELAB_MARKER    = $(SIM_OUT)/.elab.$(TEST_TYPE).done

.PHONY: all lint compile elaborate sim sim-unit wave clean setup help hex synth

all: sim

# --- 0. Directory Setup ---
setup:
	@mkdir -p $(SIM_LOGS)
	@mkdir -p $(SIM_WAVES)

# --- 1. Linting ---
lint: $(LINT_MARKER)

$(LINT_MARKER): | setup
	@echo "=== 1. Linting module: $(RTL_TOP) ==="
	$(LINTER) $(LINT_FLAGS) -f $(RTL_FILELIST)
	@touch $@

# --- 2. Compilation ---
compile: $(COMPILE_MARKER)

$(COMPILE_MARKER): | setup
	@echo "=== 2. Compiling test type: $(TEST_TYPE) ==="
	$(XVLOG) -sv -f $(TB_FILELIST) -log $(SIM_LOGS)/xvlog.log
	@touch $@

# --- 3. Elaboration ---
elaborate: $(ELAB_MARKER)

$(ELAB_MARKER): compile
	@echo "=== 3. Elaborating top: $(TB_TOP) ==="
	$(XELAB) -debug typical -top $(TB_TOP) -snapshot $(TB_TOP)_snap -log $(SIM_LOGS)/xelab.log
	@touch $@

# --- 4. Simulation ---
sim: elaborate
	@echo "=== 4. Running Simulation ==="
	@echo "log_wave -recursive *; run all; exit" > $(SIM_WAVES)/xsim_cfg.tcl
	$(XSIM) $(TB_TOP)_snap -tclbatch $(SIM_WAVES)/xsim_cfg.tcl -wdb $(SIM_WAVES)/$(TB_TOP)_wave.wdb -log $(SIM_LOGS)/xsim_run.log | tee $(SIM_LOGS)/$(TB_TOP)_sim_stdout.log
	@echo "=== Analyzing log ==="
	@$(PYTHON) scripts/check_sim.py $(SIM_LOGS)/$(TB_TOP)_sim_stdout.log || true

# --- 4b. Unit test shortcut ---
sim-unit:
	$(MAKE) sim TEST_TYPE=unit TB_TOP=tb_$(UNIT)

# --- 5. Waveform Viewing ---
wave:
	@echo "=== Opening Vivado XSIM GUI ==="
	$(XSIM) $(SIM_WAVES)/$(TB_TOP)_wave.wdb -gui

# --- 6. Assembly → HEX ---
hex:
	@echo "=== Building test programs ==="
	$(MAKE) -C sw all

# --- 7. Synthesis ---
synth:
	@echo "=== Starting Synthesis ==="
	@mkdir -p syn/out
	vivado -mode batch -source scripts/synth.tcl -log syn/out/vivado_synth.log

# --- 8. Cleanup ---
clean:
	@echo "=== Cleaning Workspace ==="
	rm -rf $(SIM_OUT)
	rm -rf syn/out/*
	rm -rf xsim.dir .Xil
	rm -f *.jou *.log *.pb *.wdb
	$(MAKE) -C sw clean

# --- Help ---
help:
	@echo ""
	@echo "  rv32i-pipeline Makefile"
	@echo "  ======================"
	@echo ""
	@echo "  make lint               - Verilator lint on RTL"
	@echo "  make sim                - System simulation (full SoC)"
	@echo "  make sim-unit UNIT=alu  - Unit test for specific module"
	@echo "  make wave               - Open waveform viewer"
	@echo "  make hex                - Compile assembly tests to .hex"
	@echo "  make synth              - Vivado synthesis"
	@echo "  make clean              - Remove generated files"
	@echo ""
