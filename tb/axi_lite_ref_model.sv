//DUT reference model
//lets say monitor observed A, scoreboard now wants to check if observed A is correct and expected? SOLUTION - scoreboard will refer the observed vs expected from reference model
//hence, reference model is a pure software implementation of register bank (in my case).NO RTL, NO TIMING. just a SV class with memory array & RW logic

//think of a ref model as an answer key for exam


`ifndef AXI_LITE_REF_MODEL 
`define AXI_LITE_REF_MODEL
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_transaction.sv";

class axi_lite_ref_model extends uvm_component;
`uvm_component_utils(axi_lite_ref_model)

//REGISTER MEMORY ARRAY
//local->used for private array. only ref model can R/W
//predict_read() -> scoreboard calls it in order to access registers[]
//indices 0 to 7 maps to addresses 0x00 to 0x1C
local logic [31:0] registers [0:7]; //8 registers-32 bits each


//CONSTRUCTOR AND BUILD_PHASE
function new(string name="axi_lite_ref_model", uvm_component parent = null);
super.new(name,parent);
endfunction


function void build_phase (uvm_phase phase);
super.build_phase(phase);

//LETS MIRROR THE HARDWARE RESET PATTERN - initialize all registers to 0
foreach(registers[i])
registers[i]=32'h0;//set each register to 0
`uvm_info("REF_MODEL", "ref active-all registers in reset", UVM_LOW)
endfunction


//reference model for a WRITE function
function void write_register(
input logic [31:0] addr,
input logic [31:0] data,
input logic [3:0]  wstrb
);
// Convert byte address to register index
// addr[4:2] gives bits 4,3,2 — the register index
// addr[1:0] should always be 00 (word-aligned)
int idx = addr[4:2];

// Apply WSTRB — update only the enabled byte lanes
// This is the most critical logic in the reference model
if (wstrb[0]) registers[idx][7:0]   = data[7:0];
if (wstrb[1]) registers[idx][15:8]  = data[15:8];
if (wstrb[2]) registers[idx][23:16] = data[23:16];
if (wstrb[3]) registers[idx][31:24] = data[31:24];

`uvm_info("REF_MODEL", $sformatf("  REG WRITE  reg[%0d]  addr=0x%08h  new_val=0x%08h  wstrb=4'b%04b", idx, addr, registers[idx], wstrb), UVM_LOW)
endfunction


//reference model for a READ function
function logic [31:0] read_register(
input logic [31:0] addr
);
int idx = addr[4:2];
`uvm_info("REF_MODEL", $sformatf("  REG READ   reg[%0d]  addr=0x%08h  expected=0x%08h", idx, addr, registers[idx]), UVM_LOW)
return registers[idx];
endfunction
endclass
`endif
 