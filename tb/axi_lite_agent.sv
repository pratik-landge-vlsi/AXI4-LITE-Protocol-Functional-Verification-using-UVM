//packing everything into one reusable box - AGENT 
//AGENT = MONITOR + DRIVER + SEQUENCER
//ACTIVE MODE - MONITOR + DRIVER + SEQUENCER
//PASSIVE MODE - ONLY MONITOR
//problem that agent solves - if there is a SOC verification project which has many axi slaves and everybody needs monitor, driver and a sequencer, so rather than creating 10 different each M,D,S for 10 different axi needs, which equals to 30 creations for 10 needs. Instead we design a AGENT, so for 10 needs, we create and pass 10 agents

`ifndef AXI_LITE_AGENT_SV
`define AXI_LITE_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_driver.sv"
`include "axi_lite_monitor.sv"
`include "axi_lite_sequence_lib.sv"

class axi_lite_agent extends uvm_agent;
`uvm_component_utils(axi_lite_agent)

axi_lite_driver drv;
axi_lite_monitor mon;
axi_lite_sequencer sqr;

uvm_analysis_port #(axi_lite_transaction)ap;//connects mon broadcast to outer world

function new (string name = "axi_lite_agent", uvm_component parent = null);
super.new(name, parent);
endfunction

//BUILD PHASE
function void build_phase(uvm_phase phase);
super.build_phase(phase);

ap=new("ap",this);//analysis port - environment will connect to this

mon = axi_lite_monitor::type_id::create("mon", this); //monitor always present

if (get_is_active()==UVM_ACTIVE) begin //get_is_active() is a built in uvm method from uvm_agent, it returns whether the agent is active or passive
drv = axi_lite_driver::type_id::create("drv", this);
sqr = axi_lite_sequencer::type_id::create("sqr", this);
end
endfunction



//CONNECT PHASE
function void connect_phase(uvm_phase phase);
mon.ap.connect(ap);//connect monitors port to agents port for analysis

//connect driver to sequencer (for ACTIVE mode only)
if(get_is_active()==UVM_ACTIVE) begin
drv.seq_item_port.connect(sqr.seq_item_export);//agent wires drv and sqr together
end
endfunction
endclass
`endif


