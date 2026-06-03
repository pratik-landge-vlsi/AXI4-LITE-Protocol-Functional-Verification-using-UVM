//environment is the container above the agent block
//envrionment is the hourse of scoreboard and coverage collector
//env solves the problem of instantiation.
//env is a one stop place for all verification infrastructure, all wired together

`ifndef AXI_LITE_ENV_SV 
`define AXI_LITE_ENV_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_agent.sv"
`include "axi_lite_ref_model.sv"
`include "axi_lite_scoreboard.sv"
class axi_lite_env extends uvm_env;
`uvm_component_utils (axi_lite_env)

axi_lite_agent agt;
axi_lite_ref_model ref_model;

//space for covg and scoreboard here
axi_lite_scoreboard scb;
//axi_lite_coverage cov;

function new(string name = "axi_lite_env", uvm_component parent = null);
super.new(name, parent);
endfunction

//BUILD_PHASE
function void build_phase(uvm_phase phase);
super.build_phase(phase);

agt = axi_lite_agent::type_id::create("agt",this);
ref_model = axi_lite_ref_model::type_id::create("ref_model",this);

scb = axi_lite_scoreboard::type_id::create("scb",this);
//cov = axi_lite_coverage::type_id::create("cov",this);

endfunction

//CONNECT PHASE
function void connect_phase (uvm_phase phase);
agt.ap.connect(scb.analysis_export); //monitor to scrbrd connection
scb.ref_model = ref_model;
endfunction
endclass 
`endif


