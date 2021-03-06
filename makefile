# flags for synopsys tools
SNPS_FLAGS = -full64 -cpp g++-6 -cc gcc-6
CC = gcc-6
CXX = g++-6
SNPS_CFLAGS = -I${PWD}/csrc/sysc/include -I${VCS_HOME}/etc/systemc/tlm/tli -DTLI_BYTE_VIEW_DEBUG  -DVCS  -I${VCS_HOME}/include/systemc231 -I${VCS_HOME}/etc/systemc/tlm/include/tlm -I${VCS_HOME}/include -I${VCS_HOME}/include/cosim/bf -fPIC -g -Og -m64
SNPS_CXXFLAGS = -I${PWD}/csrc/sysc/include -I${VCS_HOME}/etc/systemc/tlm/tli -DTLI_BYTE_VIEW_DEBUG  -DVCS  -I${VCS_HOME}/include/systemc231 -I${VCS_HOME}/etc/systemc/tlm/include/tlm -I${VCS_HOME}/include -I${VCS_HOME}/include/cosim/bf -fPIC -g -Og -m64

# path for libremote port
LIBSOC_PATH=libsystemctlm-soc
LIBSOC_ZYNQMP_PATH=$(LIBSOC_PATH)/soc/xilinx/zynqmp
LIBRP_PATH=$(LIBSOC_PATH)/libremote-port

# include files for lib remote port
SNPS_CXXFLAGS += -I $(LIBRP_PATH) -I $(LIBSOC_PATH)
SNPS_CFLAGS += -I $(LIBRP_PATH) -I $(LIBSOC_PATH)


#include header files in this directory
SNPS_CXXFLAGS += -I . -I $(LIBSOC_ZYNQMP_PATH) -I $(LIBSOC_PATH)
SNPS_CFLAGS += -I . -I $(LIBSOC_ZYNQMP_PATH) -I $(LIBSOC_PATH)



RP_C_FILES = $(LIBRP_PATH)/safeio.c \
	     $(LIBRP_PATH)/remote-port-proto.c \
	     $(LIBRP_PATH)/remote-port-sk.c

RP_CXX_FILES = $(LIBRP_PATH)/remote-port-tlm.cc \
	       $(LIBRP_PATH)/remote-port-tlm-memory-master.cc \
	       $(LIBRP_PATH)/remote-port-tlm-memory-slave.cc \
	       $(LIBRP_PATH)/remote-port-tlm-wires.cc

COSIM_SYSC_FILES = debugdev.cc \
		   demo-dma.cc \
		   memory.cc \
		   trace.cc \
		   zynqmp_demo.cc \
		   $(LIBSOC_ZYNQMP_PATH)/xilinx-zynqmp.cc

CXX_FILES = $(RP_CXX_FILES) $(COSIM_SYSC_FILES)
C_FILES = $(RP_C_FILES)

comp: comp_verilog comp_c libsc_hier.so
	mkdir work -p
	echo "compiling c++ files"
	vcs -sysc $(SNPS_FLAGS) -ntb_opts uvm -debug_access+all libsc_hier.so sc_main -timescale=1ps/1fs -lca -o simv2


comp_verilog: axi_ram.v
	vlogan $(SNPS_FLAGS) -sysc -sysc=opt_if -sysc=gen_portmap axi_ram.v -sc_model axi_ram
	vlogan $(SNPS_FLAGS) -sysc axi_ram.v -sc_model axi_ram -sc_portmap axi_ram.portmap

# TODO: finer grain control
comp_c: $(CXX_FILES) $(C_FILES)
	syscan $(SNPS_FLAGS) -cflags "$(SNPS_CXXFLAGS)" $(CXX_FILES)
	$(CC) -c $(SNPS_CFLAGS) $(C_FILES)
	$(CC) -g -fPIC -shared -o libsc_hier.so *.o

uvm:
	vlogan $(SNPS_FLAGS) -sverilog -ntb_opts uvm



clean:
	rm -rf AN.DB csrc simv2.daidir simv2 work ucli.key vc_hdrs.h DVEfiles *.vpd dir1 *.o *.d *.so  tli_uvm_mem_data.sv *.log *.portmap *.error 64 verdiLog novas.conf
