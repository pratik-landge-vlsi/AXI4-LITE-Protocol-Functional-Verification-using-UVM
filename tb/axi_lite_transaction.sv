`ifndef AXI_LITE_TRANSACTION_SV
`define AXI_LITE_TRANSACTION_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
//enum declaration (making technical terms like 0 and 1, we define human understandable words using enum
typedef enum bit {
READ = 0,
WRITE = 1 } axi_rw_e; //_e is a naming convention for enum type in industry

//class declaration
class axi_lite_transaction extends uvm_sequence_item; //my new class will inherit all the basic needed uvm properties

//field declarations
rand axi_rw_e rw;
rand logic [31:0] addr;
rand logic [31:0] data;
rand logic [3:0] wstrb;
logic [1:0] resp;

//factory registration and automation (register class once with uvm factory and then create/use anywhere using "type_id::create()"
//UVM_ALL_ON will turn on automation for all these field, i.e. printing, copying, comparing, packing anything everything, all automated
`uvm_object_utils_begin(axi_lite_transaction) //i am registering my class for factory and to begin automation
`uvm_field_enum(axi_rw_e, rw,   UVM_ALL_ON) //register rw field. ('enum type', 'field')
`uvm_field_int (addr,           UVM_ALL_ON) //register address
`uvm_field_int (data,           UVM_ALL_ON) //register data
`uvm_field_int (wstrb,          UVM_ALL_ON) //register strobes
`uvm_field_int (resp,           UVM_ALL_ON) //register response 
`uvm_object_utils_end //closing automation block 


//constraints declarations (without constraints , randomize() could generate unaligned addresses, when supposed to generate 0x03; it can generate 0x0003 etc
constraint addr_align_c {
addr[1:0] == 2'b00;//address starts from 00, because my data bus is 32 bits~4 bytes. so my address should start from 00 and then multiples of 4, 0x00-0x040x08.....
}
constraint addr_range_c{
addr inside {[32'h00:32'h1c]};//address must range between 0x00 to 0x1C (register bank = 8 registers*4bytes == 32 bytes of address) 
}

constraint wstrb_valid_c{
(rw == WRITE) -> (wstrb != 4'b0000); //if this is a write, THEN strobes cannot be 0 (-> means implication) 
}
constraint wstrb_ready_c{
(rw == READ) -> (wstrb == 4'b0000); //if this is read, THEN strobes must be zero
}

//constructor declarations
function new (string name = "axi_lite_transaction");
super.new(name);
endfunction

//converting to string (converts entire transaction into a readable string for scoreboard & monitor)
//when scoreboard finds a mismatch, it doesnt only print FAIL, it will now print what parameters made it fail within string
function string convert2string();
return $sformatf("rw=%s addr=0x%08h data=0x%08h wstrb=4'b%04b resp=2'b%02b", rw.name(), addr, data, wstrb, resp);
endfunction

//end of class
endclass
`endif





