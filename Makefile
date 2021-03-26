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

ifneq "$(VCS_HOME)" ""
SYSTEMC_INCLUDE ?=$(VCS_HOME)/include/systemc231/
SYSTEMC_LIBDIR ?= $(VCS_HOME)/linux/lib
TLM2 ?= $(VCS_HOME)/etc/systemc/tlm/

HAVE_VERILOG=y
HAVE_VERILOG_VERILATOR?=n
HAVE_VERILOG_VCS=y
else
SYSTEMC ?= /usr/local/systemc-2.3.1/
SYSTEMC_INCLUDE ?=$(SYSTEMC)/include/
SYSTEMC_LIBDIR ?= $(SYSTEMC)/lib-linux64
# In case your TLM-2.0 installation is not bundled with
# with the SystemC one.
# TLM2 ?= /opt/systemc/TLM-2009-07-15
endif

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
LDFLAGS = -L $(SYSTEMC_LIBDIR)
LDLIBS   += -lsystemc

ZYNQ_TOP_C = zynq_demo.cc
ZYNQ_TOP_O = $(ZYNQ_TOP_C:.cc=.o)
ZYNQMP_TOP_C = zynqmp_demo.cc
ZYNQMP_TOP_O = $(ZYNQMP_TOP_C:.cc=.o)

ZYNQ_OBJS += $(ZYNQ_TOP_O)
ZYNQMP_OBJS += $(ZYNQMP_TOP_O)

# Uncomment to enable use of scml2
# CPPFLAGS += -I $(SCML_INCLUDE)
# LDFLAGS += -L $(SCML_LIBDIR)
# LDLIBS += -lscml2 -lscml2_logging

SC_OBJS += memory.o
SC_OBJS += trace.o
SC_OBJS += debugdev.o
SC_OBJS += demo-dma.o

LIBSOC_PATH=libsystemctlm-soc
LIBSOC_ZYNQ_PATH=$(LIBSOC_PATH)/zynq
LIBSOC_ZYNQMP_PATH=$(LIBSOC_PATH)/zynqmp
SC_OBJS += $(LIBSOC_ZYNQ_PATH)/xilinx-zynq.o
CPPFLAGS += -I $(LIBSOC_ZYNQ_PATH)

SC_OBJS += $(LIBSOC_ZYNQMP_PATH)/xilinx-zynqmp.o
CPPFLAGS += -I $(LIBSOC_ZYNQMP_PATH)

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
VERILATOR_ROOT?=/usr/share/verilator
VERILATOR=verilator

VM_TRACE?=0
VM_COVERAGE?=0
VFILES_CPP=$(addprefix $(VOBJ_DIR)/V, $(VFILES:.v=.cpp))
VFILES_OBJS=$(VFILES_CPP:.cpp=.o)
VTOP_LIB=$(VOBJ_DIR)/Vapb_timer__ALL.a
VERILATED_O=$(VOBJ_DIR)/verilated.o
VTOP_MK=Vapb_timer.mk

# Gives some compatibility with vcs
VFLAGS += --pins-bv 2

VFLAGS+=--sc --Mdir $(VOBJ_DIR)
VFLAGS += -CFLAGS "-DHAVE_VERILOG" -CFLAGS "-DHAVE_VERILOG_VERILATOR"
CPPFLAGS += -DHAVE_VERILOG
CPPFLAGS += -DHAVE_VERILOG_VERILATOR
CPPFLAGS += -I $(VOBJ_DIR)
endif

ifeq "$(HAVE_VERILOG_VCS)" "y"
VCS=vcs -full64
SYSCAN=syscan -full64
VLOGAN=vlogan -full64
VHDLAN=vhdlan -full64

VCS_CXX_FLAGS = -cpp g++-6 -cc gcc-6 -cflags "-I $(LIBSOC_PATH) -I $(LIBRP_PATH) $(CPPFLAGS)"

CSRC_DIR = csrc

VLOGAN_FLAGS += -sysc $(VCS_CXX_FLAGS) -sysc=opt_if -sysc=gen_portmap
VLOGAN_FLAGS += +v2k -sc_model apb_slave_timer

VHDLAN_FLAGS += -sysc $(VCS_CXX_FLAGS) -sysc=opt_if -sysc=gen_portmap
VHDLAN_FLAGS += -sc_model apb_slave_dummy

SYSCAN_ZYNQ_DEMO = zynq_demo.cc
SYSCAN_ZYNQMP_DEMO = zynqmp_demo.cc
SYSCAN_SCFILES += demo-dma.cc debugdev.cc $(LIBRP_PATH)/remote-port-tlm.cc $(LIBRP_PATH)/remote-port-tlm-wires.cc $(LIBRP_PATH)/remote-port-tlm-memory-slave.cc $(LIBRP_PATH)/remote-port-tlm-memory-master.cc $(LIBSOC_ZYNQMP_PATH)/xilinx-zynqmp.cc

VCS_CFILES += $(LIBRP_PATH)/remote-port-proto.c $(LIBRP_PATH)/remote-port-sk.c $(LIBRP_PATH)/safeio.c

SYSCAN_FLAGS += -tlm2 -sysc=opt_if $(VCS_CXX_FLAGS)
SYSCAN_FLAGS += -cflags -DHAVE_VERILOG -cflags -DHAVE_VERILOG_VCS
VCS_FLAGS += -sysc sc_main -sysc=adjust_timeres $(VCS_CXX_FLAGS) -lca -LDFLAGS -Wl,--no-as-needed
VFLAGS += -CFLAGS "-DHAVE_VERILOG" -CFLAGS "-DHAVE_VERILOG_VCS"
endif

OBJS = $(C_OBJS) $(SC_OBJS)

ZYNQ_OBJS += $(OBJS)
ZYNQMP_OBJS += $(OBJS)

TARGET_ZYNQ_DEMO = zynq_demo
TARGET_ZYNQMP_DEMO = zynqmp_demo

TARGETS = $(TARGET_ZYNQ_DEMO) $(TARGET_ZYNQMP_DEMO)

all: $(TARGETS)

-include $(ZYNQ_OBJS:.o=.d)
-include $(ZYNQMP_OBJS:.o=.d)
CFLAGS += -MMD
CXXFLAGS += -MMD

ifeq "$(HAVE_VERILOG_VERILATOR)" "y"
include $(VERILATOR_ROOT)/include/verilated.mk
endif

obj_dir/V%.cpp: %.v
	$(VENV) $(VERILATOR) $(VFLAGS) $(VFILES)

$(VTOP_LIB): $(VFILES_CPP)
	$(MAKE) -C $(VOBJ_DIR) -f $(VTOP_MK)

$(VERILATED_O): $(VFILES_CPP)
	$(MAKE) -C $(VOBJ_DIR) -f $(VTOP_MK) verilated.o

ifeq "$(HAVE_VERILOG_VERILATOR)" "y"
$(TOP_O): $(VFILES_CPP) $(TOP_C)
	$(MAKE) -C $(VOBJ_DIR) -f $(VTOP_MK) ../$(TOP_O)
endif

ifeq "$(HAVE_VERILOG_VCS)" "y"
$(TARGET_ZYNQMP_DEMO): $(VFILES) $(SYSCAN_ZYNQMP_DEMO)
	$(VLOGAN) $(VLOGAN_FLAGS) $(VFILES)
	$(SYSCAN) $(SYSCAN_FLAGS) $(SYSCAN_ZYNQMP_DEMO) $(SYSCAN_SCFILES)
	$(VCS) $(VCS_FLAGS) $(VFLAGS) $(VCS_CFILES) -o $@
else
$(ZYNQMP_OBJS): $(VTOP_LIB) $(VERILATED_O)

$(TARGET_ZYNQMP_DEMO): $(ZYNQMP_OBJS) $(VTOP_LIB) $(VERILATED_O)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

endif

$(TARGET_ZYNQ_DEMO): $(ZYNQ_OBJS) $(VTOP_LIB) $(VERILATED_O)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(RM) $(OBJS) $(OBJS:.o=.d) $(TARGETS)
	$(RM) $(ZYNQ_OBJS) $(ZYNQ_OBJS:.o=.d)
	$(RM) $(ZYNQMP_OBJS) $(ZYNQMP_OBJS:.o=.d)
	$(RM) -r $(VOBJ_DIR) $(CSRC_DIR) *.daidir
