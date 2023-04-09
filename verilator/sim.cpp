#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vaxi_iops.h"
#include "axi4.hpp"
#include "axi4_mem.hpp"

#include <iostream>
#include <termios.h>
#include <unistd.h>
#include <thread>

void connect_wire(axi4_ptr <32,64,6> &mem_ptr, Vaxi_iops *top) {
    // connect
    // mem
    // aw
    mem_ptr.awaddr  = &(top->axi_awaddr);
    mem_ptr.awburst = &(top->axi_awburst);
    mem_ptr.awid    = &(top->axi_awid);
    mem_ptr.awlen   = &(top->axi_awlen);
    mem_ptr.awready = &(top->axi_awready);
    mem_ptr.awsize  = &(top->axi_awsize);
    mem_ptr.awvalid = &(top->axi_awvalid);
    // w
    mem_ptr.wdata   = &(top->axi_wdata);
    mem_ptr.wlast   = &(top->axi_wlast);
    mem_ptr.wready  = &(top->axi_wready);
    mem_ptr.wstrb   = &(top->axi_wstrb);
    mem_ptr.wvalid  = &(top->axi_wvalid);
    // b
    mem_ptr.bid     = &(top->axi_bid);
    mem_ptr.bready  = &(top->axi_bready);
    mem_ptr.bresp   = &(top->axi_bresp);
    mem_ptr.bvalid  = &(top->axi_bvalid);
    // ar
    mem_ptr.araddr  = &(top->axi_araddr);
    mem_ptr.arburst = &(top->axi_arburst);
    mem_ptr.arid    = &(top->axi_arid);
    mem_ptr.arlen   = &(top->axi_arlen);
    mem_ptr.arready = &(top->axi_arready);
    mem_ptr.arsize  = &(top->axi_arsize);
    mem_ptr.arvalid = &(top->axi_arvalid);
    // r
    mem_ptr.rdata   = &(top->axi_rdata);
    mem_ptr.rid     = &(top->axi_rid);
    mem_ptr.rlast   = &(top->axi_rlast);
    mem_ptr.rready  = &(top->axi_rready);
    mem_ptr.rresp   = &(top->axi_rresp);
    mem_ptr.rvalid  = &(top->axi_rvalid);
}

bool trace_on = true;

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vaxi_iops *top = new Vaxi_iops;
    axi4_ptr <32,64,6> mem_ptr;

    connect_wire(mem_ptr,top);
    assert(mem_ptr.check());

    axi4_ref <32,64,6> mem_ref(mem_ptr);
    axi4     <32,64,6> mem_sigs;
    axi4_ref <32,64,6> mem_sigs_ref(mem_sigs);
    axi4_mem <32,64,6> mem(4096l*1024*1024);

    mem.set_delay(10);

    // connect Vcd for trace
    VerilatedVcdC vcd;
    if (trace_on) {
        top->trace(&vcd,0);
        vcd.open("trace.vcd");
    }

    top->reset = 1;
    uint64_t ticks = 0;
    long max_trace_ticks = 1000;
    uint64_t uart_tx_bytes = 0;
    while (!Verilated::gotFinish() && max_trace_ticks > 0) {
        top->eval();
        if (trace_on) {
            vcd.dump(ticks);
            max_trace_ticks --;
        }
        ticks ++;
        if (ticks == 9) top->reset = 0;
        top->clock = 1;
        // posedge
        mem_sigs.update_input(mem_ref);
        top->eval();
        if (!top->reset) {
            mem.beat(mem_sigs_ref);
        }
        mem_sigs.update_output(mem_ref);
        top->eval();
        if (trace_on) {
            vcd.dump(ticks);
            max_trace_ticks --;
        }
        ticks ++;
        top->clock = 0;
        if (ticks == 100) {
            top->debug_pause = 1;
        }
        if (ticks == 150) {
            top->debug_pause = 0;
        }
        if (ticks == 200) {
            top->debug_arsize = 3;
        }
        if (ticks == 500) {
            top->debug_arlen = 15;
        }
    }
    top->final();
    return 0;
}
