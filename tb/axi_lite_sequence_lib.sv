`ifndef AXI_LITE_SEQUENCE_LIB_SV
`define AXI_LITE_SEQUENCE_LIB_SV
`include "uvm_macros.svh" //include all uvm macros
import uvm_pkg::*; //bring all uvm classes into one scope
`include "axi_lite_transaction.sv"

//sequencer class
class axi_lite_sequencer extends uvm_sequencer #(axi_lite_transaction); //enables UVMs inbuilt sequencer,  #(axi_lite_transaction) - transaction type declaration
`uvm_component_utils(axi_lite_sequencer) //factory registration (sequencer is an component, not an object)
function new (string name = "axi_lite_sequencer", uvm_component parent = null);
super.new(name, parent);
endfunction
endclass

//sequence declaration (test 1) - Single WRITE sequence
class axi_lite_write_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils (axi_lite_write_seq) //sequences are basically objects, they get created and destroyed for every test run
function new (string name = "axi_lite_write_seq");
super.new(name);
endfunction

task body();//most important, all transaction generation logic goes in here
axi_lite_transaction txn;//declaring pointer/handle to transaction
txn = axi_lite_transaction::type_id::create ("txn");//creating actual transaction object using factory
start_item(txn);//MOST IMP - it tells sequencer that "be ready, i am gonna assign u something"
if(!txn.randomize() with {rw==WRITE;})//randomize all rand fields, while the filter of operation is rw==write. if(!txn=randomize()) - returns 0 if randomization fails to work within allotted constraints
`uvm_fatal("SEQ", "Randomization failed for write transaction")
`uvm_info ("WRITE_SEQ", $sformatf("Generated WRITE: %s", txn.convert2string()), UVM_LOW)//print the failure result as defined in string format, to debug efficiently
finish_item (txn); //this sends transaction to driver and blocks/holds until driver says item_done(). basically everything gets stall until driver physically does all transaction stuff
endtask
 endclass


//sequence declaration (test 2) - single READ sequence
class axi_lite_read_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils (axi_lite_read_seq)
function new (string name = "axi_lite_read_seq");
super.new(name);
endfunction

task body();
axi_lite_transaction txn;
txn = axi_lite_transaction::type_id::create("txn");
start_item(txn);
if (!txn.randomize() with {rw==READ;})
`uvm_fatal ("SEQ", "Randomization failed for read transaction")
`uvm_info ("READ_SEQ", $sformatf("Generated READ: %s", txn.convert2string()), UVM_LOW)
finish_item (txn);
endtask
endclass

//sequence declaration (test 3) - write then read sequence
class axi_lite_write_read_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils (axi_lite_write_read_seq)
function new (string name = "axi_lite_write_read_seq");
super.new(name);
endfunction

task body();
axi_lite_write_seq wr_seq;//handles write first sequences
axi_lite_read_seq rd_seq;//handles read after sequences
wr_seq = axi_lite_write_seq::type_id::create("wr_seq");
rd_seq = axi_lite_read_seq::type_id::create("rd_seq");

//m-sequencer - it is pointer which says that "WRITE/READ sequence is running and i need to block other upcoming operation before current is done"
wr_seq.start(m_sequencer); //starts write sequence
rd_seq.start(m_sequencer);//after write completes, read sequence starts
endtask
endclass


//WRITE AND READ-BACK TO SAME ADDRESS
class axi_lite_write_rdbck_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils(axi_lite_write_rdbck_seq)
function new (string name = "axi_lite_write_rdbck_seq");
super.new(name);
endfunction

task body();
axi_lite_transaction wr_txn;
axi_lite_transaction rd_txn;

//STEP1-CREATE AND RANDOMIZE WRITE TRANSACTIONS
wr_txn = axi_lite_transaction::type_id::create("wr_txn");
start_item(wr_txn);
if (!wr_txn.randomize() with {rw==WRITE;})
`uvm_fatal("SEQ", "WRITE RANDOMIZATION FAILED")
`uvm_info("WR_RB_SEQ",$sformatf("Write-RDBCK: WRITE addr=0x%08h data=0x%08h wstrb=4'b%04b",wr_txn.addr, wr_txn.data, wr_txn.wstrb), UVM_LOW)
finish_item(wr_txn);


//CREATING READ FOR THE SAME ADDRESS
rd_txn = axi_lite_transaction::type_id::create("rd_txn");
start_item(rd_txn);
//addr==wr_txn.addr, forces read addr to equal the write addr
if(!rd_txn.randomize() with {rw==READ; addr==wr_txn.addr;})
`uvm_fatal("SEQ", "READ RANDOMIZATION FAILED")
`uvm_info("WR_RB_SEQ", $sformatf("WRITE_RDBCK: READ addr=0x%08h (Expecting written data)", rd_txn.addr), UVM_LOW)
finish_item(rd_txn);
endtask
endclass



//RANDOM REGRESSION
//RUNS N number of write then read back transactions
//every address, data, strobe combination fully randomized
class axi_lite_rand_regression_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils(axi_lite_rand_regression_seq)

//number of transaction
int unsigned num_transactions = 20;//default is 20 random txn.
function new(string name = "axi_lite_rand_regression_seq");
super.new(name);
endfunction

task body();
axi_lite_write_rdbck_seq wr_rb_seq;
int n = num_transactions;
void'(uvm_config_db #(int)::get(null, "", "num_transactions", n));
`uvm_info("RAND_REG", $sformatf("Starting Random Regression: %0d write-readback transactions", num_transactions), UVM_LOW)
repeat(n) begin
wr_rb_seq = axi_lite_write_rdbck_seq::type_id::create("wr_rb_seq");
wr_rb_seq.start(m_sequencer);//each call generates one complete WR_RDBCK txn
end

`uvm_info("RAND_REG", $sformatf("RANDOM REGRESSION COMPLETE: %0d transactions run", num_transactions), UVM_LOW)
endtask
endclass

//CLASS DECLARATION FOR ADDRESS SWEEP - writes and then reads the same
class axi_lite_addr_sweep_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils(axi_lite_addr_sweep_seq)

function new(string name = "axi_lite_addr_sweep_seq");
super.new(name);
endfunction

task body();
axi_lite_transaction wr_txn, rd_txn;
logic [31:0] addrs [8] = '{
32'h00, 32'h04, 32'h08, 32'h0C,
32'h10, 32'h14, 32'h18, 32'h1C
};

`uvm_info("ADDR_SWEEP",
"Starting address sweep: writing all 8 registers", UVM_LOW)

foreach (addrs[i]) begin
wr_txn = axi_lite_transaction::type_id::create("wr_txn");
start_item(wr_txn);
if (!wr_txn.randomize() with {
rw    == WRITE;
addr  == addrs[i];
wstrb == 4'b1111;
})
`uvm_fatal("SEQ", "Addr sweep write failed")
finish_item(wr_txn);

rd_txn = axi_lite_transaction::type_id::create("rd_txn");
start_item(rd_txn);
if (!rd_txn.randomize() with {
rw   == READ;
addr == addrs[i];
})
`uvm_fatal("SEQ", "Addr sweep read failed")
finish_item(rd_txn);
end

`uvm_info("ADDR_SWEEP", "Address sweep complete: all 8 registers verified", UVM_LOW)
endtask
endclass



//CLASS DECLARATION FOR BURST WRTIE SAME RGSTR - writes the same rgstr 8 times with different random partial strobes, reads back after each write

class axi_lite_burst_write_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils(axi_lite_burst_write_seq)

int unsigned num_writes = 8;

function new(string name = "axi_lite_burst_write_seq");
super.new(name);
endfunction

task body();
axi_lite_transaction wr_txn, rd_txn;

`uvm_info("BURST_WR",
$sformatf("Burst writing %0d times to addr=0x00000008", num_writes),
UVM_LOW)

repeat(num_writes) begin
wr_txn = axi_lite_transaction::type_id::create("wr_txn");
start_item(wr_txn);
if (!wr_txn.randomize() with {
rw   == WRITE;
addr == 32'h08;
})
`uvm_fatal("SEQ", "Burst write failed")
finish_item(wr_txn);

rd_txn = axi_lite_transaction::type_id::create("rd_txn");
start_item(rd_txn);
if (!rd_txn.randomize() with {
rw   == READ;
addr == 32'h08;
})
`uvm_fatal("SEQ", "Burst read failed")
finish_item(rd_txn);
end

`uvm_info("BURST_WR",
$sformatf("Burst write complete: %0d writes verified", num_writes),
UVM_LOW)
endtask
endclass


//WSTRB SWEEP - Tests all 15 non-zero strobe patterns on rgstr 0
class axi_lite_wstrb_sweep_seq extends uvm_sequence #(axi_lite_transaction);
`uvm_object_utils(axi_lite_wstrb_sweep_seq)

function new(string name = "axi_lite_wstrb_sweep_seq");
super.new(name);
endfunction

task body();
axi_lite_transaction wr_txn, rd_txn;

`uvm_info("WSTRB_SWEEP",
"Starting WSTRB sweep: testing all 15 non-zero strobe patterns",
UVM_LOW)

for (int strb = 1; strb <= 15; strb++) begin
wr_txn = axi_lite_transaction::type_id::create("wr_txn");
start_item(wr_txn);
if (!wr_txn.randomize() with {
rw    == WRITE;
addr  == 32'h00;
wstrb == strb[3:0];
})
`uvm_fatal("SEQ", "WSTRB sweep write failed")
finish_item(wr_txn);

rd_txn = axi_lite_transaction::type_id::create("rd_txn");
start_item(rd_txn);
if (!rd_txn.randomize() with {
rw   == READ;
addr == 32'h00;
})
`uvm_fatal("SEQ", "WSTRB sweep read failed")
finish_item(rd_txn);
end

`uvm_info("WSTRB_SWEEP",
"WSTRB sweep complete: all 15 strobe patterns verified", UVM_LOW)
endtask
endclass





`endif











