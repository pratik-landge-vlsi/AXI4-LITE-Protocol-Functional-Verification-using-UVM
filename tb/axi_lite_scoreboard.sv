`ifndef AXI_LITE_SCOREBOARD_SV 
`define AXI_LITE_SCOREBOARD_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_transaction.sv"
`include "axi_lite_ref_model.sv"


class axi_lite_scoreboard extends uvm_scoreboard;
`uvm_component_utils(axi_lite_scoreboard)


//analysis export - this is exactly where monitor transactions arrive
uvm_analysis_imp #(axi_lite_transaction, axi_lite_scoreboard) analysis_export;


axi_lite_ref_model ref_model;

//pass and fail count
int pass_count;
int fail_count;


//CONSTRUCTOR AND BUILD_PHASE (INITIALIZE COUNTERS AND CREATE ANALYSIS EXPORT)

function new (string name = "axi_lite_scoreboard", uvm_component parent = null);
super.new(name, parent);
pass_count=0;//INITIALIZING COUNTERS IN CONSTRUCT., NEVER DEPEND ON sv INITIALIZE
fail_count=0; //INITIALIZING COUNTERS IN CONSTRUCT., NEVER DEPEND ON sv INITIALIZE
endfunction


function void build_phase (uvm_phase phase);
super.build_phase(phase);
analysis_export = new("analysis_export", this);
endfunction


//WRITE FUNCTION - CORE OF SCOREBARD METHOD
//this function is called by UVM everytime, monitor broadcasts a transaction
function void write(axi_lite_transaction txn);
if(txn.rw==WRITE)
check_write(txn);
else
check_read(txn);
endfunction


//CHECK_WRITE TASK
function void check_write(axi_lite_transaction txn);
ref_model.write_register(txn.addr, txn.data, txn.wstrb);//lets tell ref mode about this write (syncing ref model with DUT txn)

//SINCE DUT IS HARDWIRED TO RETURN OKAY, LETS VERIFY FOR WRITE
if (txn.resp==2'b00) begin
`uvm_info("SCB", $sformatf("SCOREBOARD PASSED: AXI_WRITE addr=0x%08h data=0x%08h wstrb=4'b%04b BRESP=OKAY", txn.addr, txn.data, txn.wstrb), UVM_LOW) pass_count++;//PASS
end
else begin
`uvm_error("SCB", $sformatf("SCOREBOARD FAILED: AXI_WRITE addr=0x%08h BRESP=2'b%02b(expected OKAY)", txn.addr, txn.resp)) fail_count++;//FAIL
end 
endfunction


//CHECK_READ FUNCTION
function void check_read(axi_lite_transaction txn);
logic[31:0] expected_data;

//STEP1 - lets ask  ref model what should be here
expected_data=ref_model.read_register(txn.addr);

//STEP2-COMPARE ACTUAL RDATA AGAINST EXPECTED
if(txn.data===expected_data) begin
`uvm_info("SCB",$sformatf("SCOREBOARD PASSED: AXI_READ addr=0x%08h RDATA=0x%08h (Matches Expected)", txn.addr, txn.data), UVM_LOW)pass_count++;
end
else begin
`uvm_error("SCB",$sformatf("SCOREBOARD READ: AXI_READ addr=0x%08h actual=0x%08h expected=0x%08h", txn.addr, txn.data, expected_data)) fail_count++;
end


//STEP3: CHECK BRESP
if (txn.resp!==2'b00) begin
`uvm_error("SCB", $sformatf("SCOREBOARD MISMATCH: AXI_READ addr=0x%08h RRESP=2'b%02b (expected OKAY)", txn.addr, txn.resp)) fail_count++;
end
endfunction


//REPORT_PHASE
function void report_phase(uvm_phase phase);
`uvm_info("SCB", $sformatf(
"============================================================"), UVM_LOW)
`uvm_info("SCB", $sformatf(
"  SCOREBOARD FINAL REPORT  |  PASS: %0d  |  FAIL: %0d",
pass_count, fail_count), UVM_LOW)
`uvm_info("SCB", $sformatf(
"============================================================"), UVM_LOW)
if (fail_count == 0)
`uvm_info("SCB", "  RESULT: ALL TRANSACTIONS PASSED", UVM_LOW)
else
`uvm_error("SCB", $sformatf("  RESULT: %0d TRANSACTION(S) FAILED", fail_count))
endfunction
endclass
`endif



