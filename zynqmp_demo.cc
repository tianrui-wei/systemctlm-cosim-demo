/*
 * Top level of the ZynqMP cosim example.
 *
 * Copyright (c) 2014 Xilinx Inc.
 * Written by Edgar E. Iglesias
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <inttypes.h>
#include <stdio.h>
#include <signal.h>
#include <unistd.h>

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;
#define HAVE_VERILOG
#define HAVE_VERILOG_VCS
#include "apb_slave_timer.h"
#include "iconnect.h"
#include "debugdev.h"
#include "demo-dma.h"
#include "xilinx-zynqmp.h"

#include "tlm2apb-bridge.h"

#ifdef HAVE_VERILOG_VERILATOR
#include "Vapb_timer.h"
#include "verilated.h"
#endif

#define NR_MASTERS	2
#define NR_DEVICES	4

#ifndef BASE_ADDR
#define BASE_ADDR 0x28000000ULL
#endif

SC_MODULE(Top)
{
	iconnect<NR_MASTERS, NR_DEVICES>	*bus;
	xilinx_zynqmp zynq;
	debugdev *debug;
	demodma *dma;

	sc_signal<bool> rst;

	sc_clock *clk;
	tlm2apb_bridge<bool, sc_bv, 16, sc_bv, 32> *tlm2apb_tmr;
#ifdef HAVE_VERILOG
#ifdef HAVE_VERILOG_VCS
	apb_slave_timer *apb_timer;
#endif
#ifdef HAVE_VERILOG_VERILATOR
	Vapb_timer *apb_timer;
#endif
	sc_signal<bool> irq_tmr;
#endif
	sc_signal<bool> apbsig_timer_psel;
	sc_signal<bool> apbsig_timer_penable;
	sc_signal<bool> apbsig_timer_pwrite;
	sc_signal<bool> apbsig_timer_pready;
	sc_signal<sc_bv<16> > apbsig_timer_paddr;
	sc_signal<sc_bv<32> > apbsig_timer_pwdata;
	sc_signal<sc_bv<32> > apbsig_timer_prdata;


	Top(sc_module_name name, const char *sk_descr, sc_time quantum) :
		zynq("zynq", sk_descr),
		rst("rst"),
#ifdef HAVE_VERILOG
		irq_tmr("irq_tmr"),
#endif
		apbsig_timer_psel("apbtimer_psel"),
		apbsig_timer_penable("apbtimer_penable"),
		apbsig_timer_pwrite("apbtimer_pwrite"),
		apbsig_timer_pready("apbtimer_pready"),
		apbsig_timer_paddr("apbtimer_paddr"),
		apbsig_timer_pwdata("apbtimer_pwdata"),
		apbsig_timer_prdata("apbtimer_prdata")
	{
        printf("initializing top design\n");
		m_qk.set_global_quantum(quantum);

		zynq.rst(rst);

		bus   = new iconnect<NR_MASTERS, NR_DEVICES> ("bus");
		debug = new debugdev("debug");
		dma = new demodma("demodma");

		bus->memmap(BASE_ADDR, 0x100 - 1,
				ADDRMODE_RELATIVE, -1, debug->socket);
		bus->memmap(BASE_ADDR + 0x10000ULL, 0x10 - 1,
				ADDRMODE_RELATIVE, -1, dma->tgt_socket);

		tlm2apb_tmr = new tlm2apb_bridge<bool, sc_bv, 16, sc_bv, 32> ("tlm2apb-tmr-bridge");
		bus->memmap(BASE_ADDR + 0x20000ULL, 0x10 - 1,
				ADDRMODE_RELATIVE, -1, tlm2apb_tmr->tgt_socket);

		bus->memmap(0x0LL, 0xffffffff - 1,
				ADDRMODE_RELATIVE, -1, *(zynq.s_axi_hpc_fpd[0]));

		zynq.s_axi_hpm_fpd[0]->bind(*(bus->t_sk[0]));

		dma->init_socket.bind(*(bus->t_sk[1]));

		debug->irq(zynq.pl2ps_irq[0]);
		dma->irq(zynq.pl2ps_irq[1]);

#ifdef HAVE_VERILOG
		/* Slow clock to keep simulation fast.  */
		clk = new sc_clock("clk", sc_time(10, SC_US));
#ifdef HAVE_VERILOG_VCS
		apb_timer = new apb_slave_timer("apb_timer");
#elif defined(HAVE_VERILOG_VERILATOR)
		apb_timer = new Vapb_timer("apb_timer");
#endif
                apb_timer->clk(*clk);
                apb_timer->rst(rst);
                apb_timer->irq(irq_tmr);
                apb_timer->psel(apbsig_timer_psel);
                apb_timer->penable(apbsig_timer_penable);
                apb_timer->pwrite(apbsig_timer_pwrite);
                apb_timer->paddr(apbsig_timer_paddr);
                apb_timer->pwdata(apbsig_timer_pwdata);
                apb_timer->prdata(apbsig_timer_prdata);
                apb_timer->pready(apbsig_timer_pready);

                tlm2apb_tmr->clk(*clk);
#else
		clk = new sc_clock("clk", sc_time(20, SC_US));
                apbsig_timer_prdata = 0xeddebeef;
                apbsig_timer_pready = true;
                tlm2apb_tmr->clk(*clk);
#endif

                tlm2apb_tmr->psel(apbsig_timer_psel);
                tlm2apb_tmr->penable(apbsig_timer_penable);
                tlm2apb_tmr->pwrite(apbsig_timer_pwrite);
                tlm2apb_tmr->paddr(apbsig_timer_paddr);
                tlm2apb_tmr->pwdata(apbsig_timer_pwdata);
                tlm2apb_tmr->prdata(apbsig_timer_prdata);
                tlm2apb_tmr->pready(apbsig_timer_pready);

		zynq.tie_off();
	}

private:
	tlm_utils::tlm_quantumkeeper m_qk;
};

void usage(void)
{
	cout << "tlm socket-path sync-quantum-ns" << endl;
}

int sc_main(int argc, char* argv[])
{
	Top *top;
    const char *socket_name;
	uint64_t sync_quantum;

//	if (argc < 3) {
		sync_quantum = 10000;
        	socket_name = "unix:/tmp/qemu/qemu-rport-_machine_cosim";
//	} else {
//		sync_quantum = strtoull(argv[2], NULL, 10);
 //       	socket_name = argv[1];
//	}

    printf("setting time resolution\n");
	sc_set_time_resolution(1, SC_PS);

    printf("instantiating top design\n");
	top = new Top("top", socket_name, sc_time((double) sync_quantum, SC_NS));

    printf("realy to pull the reset signal\n");
	/* Pull the reset signal.  */
	top->rst.write(true);
    printf("start sc_start for reset\n");
	sc_start(1, SC_US);
	top->rst.write(false);

    printf("formal starting the design\n");
	sc_start(10000000, SC_SEC);
    sc_stop();
	return -8;
}
