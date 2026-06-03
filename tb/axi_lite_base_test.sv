`ifndef AXI_LITE_BASE_TEST_SV
`define AXI_LITE_BASE_TEST_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_env.sv"

class axi_lite_base_test extends uvm_test;
`uvm_component_utils(axi_lite_base_test)

//axi_lite_sequencer sqr; //sequencer handle/pointer
//axi_lite_driver drv; //driver module
//axi_lite_monitor mon; //monitor
//axi_lite_agent agt;
axi_lite_env env;
function new(string name = "axi_lite_base_test", uvm_component parent = null);
super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase (phase);
//sqr = axi_lite_sequencer::type_id::create("sqr", this);
//drv = axi_lite_driver::type_id::create("drv", this);
//agt = axi_lite_agent::type_id::create("agt", this);
env = axi_lite_env::type_id::create("env", this);
endfunction

function void connect_phase (uvm_phase phase);
//drv.seq_item_port.connect(sqr.seq_item_export);// Connect driver's seq_item_port to sequencer's seq_item_export
//nothing to connect explicitly, agent will handle its own wiring
//nothing to connect explicitly, environment will handle its own wiring
endfunction

task run_phase(uvm_phase phase);
//axi_lite_rand_regression_seq seq;
axi_lite_addr_sweep_seq addr_sweep;
axi_lite_burst_write_seq burst_wr;
axi_lite_wstrb_sweep_seq wstrb_sweep;
axi_lite_rand_regression_seq rand_reg;

phase.raise_objection(this);

//seq = axi_lite_rand_regression_seq::type_id::create("seq"); //creating sequence through factory
//seq.num_transactions = 100; // i will probably change it to 100 later
//seq.start(env.agt.sqr);
`uvm_info("TEST", "=== ADDR SWEEP ===", UVM_LOW)
addr_sweep = axi_lite_addr_sweep_seq::type_id::create("addr_sweep");
addr_sweep.start(env.agt.sqr);

`uvm_info("TEST", "=== BURST WRITE ===", UVM_LOW)
burst_wr = axi_lite_burst_write_seq::type_id::create("burst_wr");
burst_wr.start(env.agt.sqr);

`uvm_info("TEST", "=== WSTRB SWEEP ===", UVM_LOW)
wstrb_sweep = axi_lite_wstrb_sweep_seq::type_id::create("wstrb_sweep");
wstrb_sweep.start(env.agt.sqr);

`uvm_info("TEST", "=== RANDOM REGRESSION ===", UVM_LOW)
rand_reg = axi_lite_rand_regression_seq::type_id::create("rand_reg");
rand_reg.num_transactions = 50;
rand_reg.start(env.agt.sqr);



phase.drop_objection(this);
endtask

endclass
`endif