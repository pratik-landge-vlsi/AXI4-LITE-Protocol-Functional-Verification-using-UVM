`timescale 1ns/1ps
`include "uvm_macros.svh" //defines uvm macros
import uvm_pkg::*; //includes all classes from uvm package
`include "axi_lite_if.sv"
`include "axi_lite_base_test.sv"

module top;
logic ACLK;
logic ARESETn;
initial ACLK = 0; //at time zero, clock starts low
always #5 ACLK = ~ACLK;//every 5 time units, flip the clk. 1ns/1ps=5ns toggles (no posedge clk, it runs purely on time delay principle)
initial begin
ARESETn=0; //since it is active low reset, reset is high when it is zero (assert reset)
repeat (10) @(posedge ACLK); //wait for 10 rising clock edges, i.e. hold reset for 10 clocks
@(posedge ACLK); //wait additional clk cycle before deasserting reset (required by spec to ensure synchronous deassert)
ARESETn = 1; //deassert reset, DUT is now ready to receive transaction
`uvm_info("TOP", "Reset deasserted by pratik & simulation starts", UVM_LOW)//prints message in simulation log
end

//INTERFACE INSTANTIATION
axi_lite_if #(
.data_width (32),
.addr_width (32)
) axi_if(
.ACLK (ACLK),
.ARESETn (ARESETn)
);

//REGISTER WIRES
logic [31:0] reg_wr_addr; //dut tells write to this address
logic [31:0] reg_wr_data;//dut tells write to this data
logic [3:0]  reg_wr_strb;//tells active byte lines of strobe
logic        reg_wr_en;//tells to write NOW
logic        reg_wr_wait;//register backend tells dut - WAIT! hold on i m busy
logic        reg_wr_ack; //backend tells dut - write complete
logic [31:0] reg_rd_addr; //dut tells backend - read from this address
logic        reg_rd_en;//dut tells backend-go! fetch this data
logic [31:0] reg_rd_data;//backend returns the data to dut
logic        reg_rd_wait;//backend tells dut - i am busy hold on
logic        reg_rd_ack;//read complete

//DUT INSTANTIATION
axil_reg_if #( //dut name
.DATA_WIDTH (32),
.ADDR_WIDTH (32),
.STRB_WIDTH(4),
.TIMEOUT (4)
) DUT (
.clk (ACLK),
.rst (~ARESETn),
.s_axil_awaddr    (axi_if.AWADDR),
.s_axil_awprot    (axi_if.AWPROT),
.s_axil_awvalid   (axi_if.AWVALID),
.s_axil_awready   (axi_if.AWREADY),
.s_axil_wdata     (axi_if.WDATA),
.s_axil_wstrb     (axi_if.WSTRB),
.s_axil_wvalid    (axi_if.WVALID),
.s_axil_wready    (axi_if.WREADY),
.s_axil_bresp     (axi_if.BRESP),
.s_axil_bvalid    (axi_if.BVALID),
.s_axil_bready    (axi_if.BREADY),
.s_axil_araddr    (axi_if.ARADDR),
.s_axil_arprot    (axi_if.ARPROT),
.s_axil_arvalid   (axi_if.ARVALID),
.s_axil_arready   (axi_if.ARREADY),
.s_axil_rdata     (axi_if.RDATA),
.s_axil_rresp     (axi_if.RRESP),
.s_axil_rvalid    (axi_if.RVALID),
.s_axil_rready    (axi_if.RREADY),
.reg_wr_addr      (reg_wr_addr),
.reg_wr_data      (reg_wr_data),
.reg_wr_strb      (reg_wr_strb),
.reg_wr_en        (reg_wr_en),
.reg_wr_wait      (reg_wr_wait),
.reg_wr_ack       (reg_wr_ack),
.reg_rd_addr      (reg_rd_addr),
.reg_rd_en        (reg_rd_en),
.reg_rd_data      (reg_rd_data),
.reg_rd_wait      (reg_rd_wait),
.reg_rd_ack       (reg_rd_ack)
);


//REGISTER BANK - 8 REGISTERS, 32 BITS WIDE EACH
// 8 registers, each 32 bits wide
// Addresses: 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C
logic [31:0] regbank [0:7];
// Write logic
always @(posedge ACLK) begin
if (~ARESETn) begin
// On reset: clear all registers to 0
for (int i = 0; i < 8; i++)
regbank[i] <= 32'h0;
reg_wr_ack <= 1'b0;
reg_rd_ack <= 1'b0;
reg_rd_data <= 32'h0;
end
else begin
// Default: deassert acks every cycle
reg_wr_ack  <= 1'b0;
reg_rd_ack  <= 1'b0;

// Write operation
// reg_wr_en goes high when DUT has both address and data ready
if (reg_wr_en) begin
// Apply WSTRB byte by byte — only write enabled bytes
if (reg_wr_strb[0]) regbank[reg_wr_addr[4:2]][7:0]   <= reg_wr_data[7:0];
if (reg_wr_strb[1]) regbank[reg_wr_addr[4:2]][15:8]  <= reg_wr_data[15:8];
if (reg_wr_strb[2]) regbank[reg_wr_addr[4:2]][23:16] <= reg_wr_data[23:16];
if (reg_wr_strb[3]) regbank[reg_wr_addr[4:2]][31:24] <= reg_wr_data[31:24];
reg_wr_ack <= 1'b1;  // tell DUT: write done
end

// Read operation
if (reg_rd_en) begin
reg_rd_data <= regbank[reg_rd_addr[4:2]];
reg_rd_ack  <= 1'b1;  // tell DUT: read done, data valid
end
end
end

assign reg_wr_wait = 1'b0;
assign reg_rd_wait = 1'b0;
 
//passing intrerface to UVM
initial begin
uvm_config_db #(virtual axi_lite_if  #(.data_width(32), .addr_width(32)))::set (null, "uvm_test_top*", "vif", axi_if);//storing virtual interfaces in config database
run_test();//by running uvm tests, driver and monitor can retrieve from db
end
endmodule 