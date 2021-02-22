#
# Cosim Makefiles
#
# Copyright (c) 2016 Xilinx Inc.
# Written by Edgar E. Iglesias
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

-include .config.mk

INSTALL ?= install

ifneq "$(VCS_HOME)" ""
SYSTEMC_INCLUDE =$(VCS_HOME)/include/systemc231/
SYSTEMC_LIBDIR = $(VCS_HOME)/linux/lib
TLM2 = $(VCS_HOME)/etc/systemc/tlm/

HAVE_VERILOG=y
HAVE_VERILOG_VERILATOR?=n
HAVE_VERILOG_VCS=y
else
#SYSTEMC ?= /usr/local/systemc-2.3.2/
#SYSTEMC_INCLUDE ?=$(SYSTEMC)/include/
#SYSTEMC_LIBDIR ?= $(SYSTEMC)/lib-linux64
# In case your TLM-2.0 installation is not bundled with
# with the SystemC one.
# TLM2 ?= /opt/systemc/TLM-2009-07-15
endif

CFLAGS += -fPIC
CXXFLAGS += -fPIC

SCML ?= /usr/local/scml-2.3/
SCML_INCLUDE ?= $(SCML)/include/
SCML_LIBDIR ?= $(SCML)/lib-linux64/

HAVE_VERILOG?=n
HAVE_VERILOG_VERILATOR?=n
HAVE_VERILOG_VCS?=n

CFLAGS += -Wall -O2 -g
CXXFLAGS += -Wall -O2 -g

ifneq "$(SYSTEMC_INCLUDE)" ""
CPPFLAGS += -I $(SYSTEMC_INCLUDE)
endif
ifneq "$(TLM2)" ""
CPPFLAGS += -I $(TLM2)/include/tlm
endif

CPPFLAGS += -I .
LDFLAGS  += -L $(SYSTEMC_LIBDIR)
LDLIBS   += -pthread -lsystemc

ZYNQ_TOP_C = zynq_demo.cc
ZYNQ_TOP_O = $(ZYNQ_TOP_C:.cc=.o)
ZYNQMP_TOP_C = zynqmp_demo.cc
ZYNQMP_TOP_O = $(ZYNQMP_TOP_C:.cc=.o)
ZYNQMP_LMAC2_TOP_C = zynqmp_lmac2_demo.cc
ZYNQMP_LMAC2_TOP_O = $(ZYNQMP_LMAC2_TOP_C:.cc=.o)
RISCV_VIRT_LMAC2_TOP_C = riscv_virt_lmac2_demo.cc
RISCV_VIRT_LMAC2_TOP_O = $(RISCV_VIRT_LMAC2_TOP_C:.cc=.o)
RISCV_VIRT_LMAC3_TOP_C = riscv_virt_lmac3_demo.cc
RISCV_VIRT_LMAC3_TOP_O = $(RISCV_VIRT_LMAC3_TOP_C:.cc=.o)
RISCV_VIRT_TRI_TOP_C = riscv_virt_tri_demo.cc
RISCV_VIRT_TRI_TOP_O = $(RISCV_VIRT_TRI_TOP_C:.cc=.o)
VERSAL_TOP_C = versal_demo.cc
VERSAL_TOP_O = $(VERSAL_TOP_C:.cc=.o)

ZYNQ_OBJS += $(ZYNQ_TOP_O)
ZYNQMP_OBJS += $(ZYNQMP_TOP_O)
ZYNQMP_LMAC2_OBJS += $(ZYNQMP_LMAC2_TOP_O)
RISCV_VIRT_LMAC2_OBJS += $(RISCV_VIRT_LMAC2_TOP_O)
RISCV_VIRT_LMAC3_OBJS += $(RISCV_VIRT_LMAC3_TOP_O)
RISCV_VIRT_TRI_OBJS += $(RISCV_VIRT_TRI_TOP_O)
VERSAL_OBJS += $(VERSAL_TOP_O)

# Uncomment to enable use of scml2
# CPPFLAGS += -I $(SCML_INCLUDE)
# LDFLAGS += -L $(SCML_LIBDIR)
# LDLIBS += -lscml2 -lscml2_logging

SC_OBJS += memory.o
SC_OBJS += trace.o
SC_OBJS += debugdev.o
SC_OBJS += demo-dma.o
SC_OBJS += xilinx-axidma.o

LIBSOC_PATH=../lib
CPPFLAGS += -I $(LIBSOC_PATH)

LIBSOC_ZYNQ_PATH=$(LIBSOC_PATH)/zynq
SC_OBJS += $(LIBSOC_ZYNQ_PATH)/xilinx-zynq.o
CPPFLAGS += -I $(LIBSOC_ZYNQ_PATH)

LIBSOC_ZYNQMP_PATH=$(LIBSOC_PATH)/zynqmp
SC_OBJS += $(LIBSOC_ZYNQMP_PATH)/xilinx-zynqmp.o
CPPFLAGS += -I $(LIBSOC_ZYNQMP_PATH)

CPPFLAGS += -I $(LIBSOC_PATH)/soc/xilinx/versal/
SC_OBJS += $(LIBSOC_PATH)/soc/xilinx/versal/xilinx-versal.o

LIBRP_PATH=$(LIBSOC_PATH)/libremote-port
C_OBJS += $(LIBRP_PATH)/safeio.o
C_OBJS += $(LIBRP_PATH)/remote-port-proto.o
C_OBJS += $(LIBRP_PATH)/remote-port-sk.o
SC_OBJS += $(LIBRP_PATH)/remote-port-tlm.o
SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-memory-master.o
SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-memory-slave.o
SC_OBJS += $(LIBRP_PATH)/remote-port-tlm-wires.o
CPPFLAGS += -I $(LIBRP_PATH)

VENV=SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR)
VOBJ_DIR=obj_dir
VFILES=apb_timer.v

ifeq "$(HAVE_VERILOG_VERILATOR)" "y"
VERILATOR ?=verilator
VERILATOR_ROOT?=$(shell $(VERILATOR) --getenv VERILATOR_ROOT 2>/dev/null || echo -n /usr/share/verilator)

VM_TRACE?=0
VM_COVERAGE?=0

# Gives some compatibility with vcs
VFLAGS += --pins-bv 2 -Wno-fatal
VFLAGS += --output-split-cfuncs 500

VFLAGS+=--sc --Mdir $(VOBJ_DIR)
VFLAGS += -CFLAGS "-DHAVE_VERILOG" -CFLAGS "-DHAVE_VERILOG_VERILATOR"
CPPFLAGS += -DHAVE_VERILOG
CPPFLAGS += -DHAVE_VERILOG_VERILATOR
CPPFLAGS += -I $(VOBJ_DIR)

ifeq "$(VM_TRACE)" "1"
VFLAGS += --trace
SC_OBJS += verilated_vcd_c.o
SC_OBJS += verilated_vcd_sc.o
CPPFLAGS += -DVM_TRACE=1
endif
endif

ifeq "$(HAVE_VERILOG_VCS)" "y"
VCS=vcs -full64
SYSCAN=syscan -full64
VLOGAN=vlogan -full64
VHDLAN=vhdlan -full64

VCS_SYSC_FLAGS = -cpp g++-6 -cc gcc-6 -cflags "-I $(LIBSOC_PATH) -I $(LIBRP_PATH)"

CSRC_DIR = csrc

VLOGAN_FLAGS += -sysc
VLOGAN_FLAGS += +v2k -sc_model apb_slave_timer
VLOGAN_FLAGS += $(VCS_SYSC_FLAGS)

VHDLAN_FLAGS += -sysc
VHDLAN_FLAGS += -sc_model apb_slave_dummy
VHDLAN_FLAGS += $(VCS_SYSC_FLAGS)

SYSCAN_ZYNQ_DEMO = zynq_demo.cc
SYSCAN_ZYNQMP_DEMO = zynqmp_demo.cc
SYSCAN_ZYNQMP_LMAC2_DEMO = zynqmp_lmac2_demo.cc
SYSCAN_RISCV_VIRT_LMAC2_DEMO = riscv_virt_lmac2_demo.cc
SYSCAN_SCFILES += demo-dma.cc debugdev.cc $(LIBRP_PATH)/remote-port-tlm.cc
# VCS_CFILES += remote-port-proto.c remote-port-sk.c safeio.c

SYSCAN_FLAGS += -tlm2 -sysc=opt_if
SYSCAN_FLAGS += -cflags -DHAVE_VERILOG -cflags -DHAVE_VERILOG_VCS
SYSCAN_FLAGS += $(VCS_SYSC_FLAGS)

VCS_FLAGS += -sysc sc_main -sysc=adjust_timeres $(VCS_SYSC_FLAGS) -lca -timescale=1ps/1ps -LDFLAGS -Wl,--no-as-needed
VFLAGS += -CFLAGS "-DHAVE_VERILOG" -CFLAGS "-DHAVE_VERILOG_VCS"
endif

OBJS = $(C_OBJS) $(SC_OBJS)

ZYNQ_OBJS += $(OBJS)
ZYNQMP_OBJS += $(OBJS)
ZYNQMP_LMAC2_OBJS += $(OBJS)
RISCV_VIRT_LMAC2_OBJS += $(OBJS)
RISCV_VIRT_LMAC3_OBJS += $(OBJS)
RISCV_VIRT_TRI_OBJS += $(OBJS)
VERSAL_OBJS += $(OBJS)

TARGET_ZYNQ_DEMO = zynq_demo
TARGET_ZYNQMP_DEMO = zynqmp_demo
TARGET_ZYNQMP_LMAC2_DEMO = zynqmp_lmac2_demo
TARGET_RISCV_VIRT_LMAC2_DEMO = riscv_virt_lmac2_demo
TARGET_RISCV_VIRT_LMAC3_DEMO = riscv_virt_lmac3_demo
TARGET_RISCV_VIRT_TRI_DEMO = riscv_virt_tri_demo
TARGET_VERSAL_DEMO = versal_demo

IPXACT_LIBS = packages/ipxact
DEMOS_IPXACT_LIB = $(IPXACT_LIBS)/xilinx.com/demos
ZL_IPXACT_DEMO_DIR = $(DEMOS_IPXACT_LIB)/zynqmp_lmac2_demo/1.0
ZL_IPXACT_DEMO = $(ZL_IPXACT_DEMO_DIR)/zynqmp_lmac2_demo.1.0.xml
ZL_IPXACT_DEMO_OUTDIR = zynqmp_lmac2_ipxact_demo
TARGET_ZYNQMP_LMAC2_IPXACT_DEMO = $(ZL_IPXACT_DEMO_OUTDIR)/sc_sim

PYSIMGEN = $(LIBSOC_PATH)/tools/pysimgen/pysimgen
PYSIMGEN_ARGS = -p $(ZL_IPXACT_DEMO)
PYSIMGEN_ARGS += -l $(IPXACT_LIBS) $(LIBSOC_PATH)/$(IPXACT_LIBS)
PYSIMGEN_ARGS += -o $(ZL_IPXACT_DEMO_OUTDIR)
PYSIMGEN_ARGS += --build --quiet

TARGETS = $(TARGET_ZYNQ_DEMO) $(TARGET_ZYNQMP_DEMO) $(TARGET_VERSAL_DEMO)
TARGETS += $(TARGET_RISCV_VIRT_TRI_DEMO)

#
# LMAC2
#
LM2_DIR=LMAC_CORE2/LMAC2_INFO/

LM_CORE = 
include files-lmac2.mk
ifneq ($(wildcard $(LM2_DIR)/.),)
TARGETS += $(TARGET_ZYNQMP_LMAC2_DEMO)
TARGETS += $(TARGET_RISCV_VIRT_LMAC2_DEMO)
ifneq ($(wildcard $(PYSIMGEN)),)
TARGETS += $(TARGET_ZYNQMP_LMAC2_IPXACT_DEMO)
endif
endif

all: $(TARGETS)

-include $(ZYNQ_OBJS:.o=.d)
-include $(ZYNQMP_OBJS:.o=.d)
-include $(ZYNQMP_LMAC2_OBJS:.o=.d)
-include $(RISCV_VIRT_LMAC2_OBJS:.o=.d)
-include $(RISCV_VIRT_LMAC3_OBJS:.o=.d)
-include $(RISCV_VIRT_TRI_OBJS:.o=.d)
-include $(VERSAL_OBJS:.o=.d)
CFLAGS += -MMD
CXXFLAGS += -MMD

CPPFLAGS += -I $(LIBSOC_PATH)/tests
ifeq "$(HAVE_VERILOG_VCS)" "y"
$(TARGET_RISCV_VIRT_LMAC2_DEMO): $(VFILES)  $(SYSCAN_RISCV_VIRT_LMAC2_DEMO) $(OBJS)
	$(VLOGAN) $(VLOGAN_FLAGS) $(VFILES)
	vlogan -full64 -cpp g++-6 -sysc=gen_portmap lmac_wrapper_top.v -sc_model vlmac
	$(SYSCAN) $(SYSCAN_FLAGS) $(SYSCAN_RISCV_VIRT_LMAC2_DEMO) $(SYSCAN_SCFILES)
	g++-6 -g -fPIC -shared -o library.so $(OBJS)
	$(VCS) $(VCS_FLAGS) $(VFLAGS) library.so $(VCS_CFILES) $(LM_CORE) -o $@
else


$(TARGET_ZYNQMP_LMAC2_IPXACT_DEMO):
	$(INSTALL) -d $(ZL_IPXACT_DEMO_OUTDIR)
	[ ! -e .config.mk ] || $(INSTALL) .config.mk $(ZL_IPXACT_DEMO_OUTDIR)
	$(PYSIMGEN) $(PYSIMGEN_ARGS)

$(TARGET_RISCV_VIRT_LMAC3_DEMO): $(RISCV_VIRT_LMAC3_OBJS) $(VTOP_LIB) $(VERILATED_O)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

endif

clean:
	$(RM) $(OBJS) $(OBJS:.o=.d) $(TARGETS)
	$(RM) $(ZYNQ_OBJS) $(ZYNQ_OBJS:.o=.d)
	$(RM) $(ZYNQMP_OBJS) $(ZYNQMP_OBJS:.o=.d)
	$(RM) $(ZYNQMP_LMAC2_OBJS) $(ZYNQMP_LMAC2_OBJS:.o=.d)
	$(RM) $(RISCV_VIRT_LMAC2_OBJS) $(RISCV_VIRT_LMAC2_OBJS:.o=.d)
	$(RM) $(RISCV_VIRT_LMAC3_OBJS) $(RISCV_VIRT_LMAC3_OBJS:.o=.d)
	$(RM) $(RISCV_VIRT_TRI_OBJS) $(RISCV_VIRT_TRI_OBJS:.o=.d)
	$(RM) -r $(VOBJ_DIR) $(CSRC_DIR) *.daidir
	$(RM) -r $(ZL_IPXACT_DEMO_OUTDIR)
