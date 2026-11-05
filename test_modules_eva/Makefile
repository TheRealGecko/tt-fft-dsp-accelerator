DUT ?= bus_interface

SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(PWD)/$(DUT).v
SIM_BUILD = sim_build_$(DUT)

TOPLEVEL = $(DUT)
MODULE = $(DUT)_tb
COCOTB_TOPLEVEL = $(DUT)
COCOTB_TEST_MODULES = $(DUT)_tb

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Verilator is strict: don't let lint warnings abort the build
EXTRA_ARGS += -Wno-fatal --timing
ifeq ($(WAVES),1)
EXTRA_ARGS += --trace-fst --trace-structs
endif

include $(shell cocotb-config --makefiles)/Makefile.sim