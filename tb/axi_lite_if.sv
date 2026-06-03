//handwritten code from scratch by plandge
`ifndef AXI_LITE_IF_SV
`define AXI_LITE_IF_SV
interface axi_lite_if #(
parameter data_width = 32,
parameter addr_width = 32)(
input logic ACLK,
input logic ARESETn);

//Address Write channelsgnals (master to slave)
logic [addr_width-1:0] AWADDR;//address to be written
logic [2:0] AWPROT;//encryption bit - privliege, security, instruction/data
logic AWVALID;//master acks if the address is valid
logic AWREADY;//slave acks if it is ready to accept

//write channel signals (master to slave)
logic [data_width-1:0] WDATA;
logic [(data_width/8)-1:0] WSTRB;
logic WVALID;
logic WREADY;

//B channel Signals (slave to master)
logic[1:0] BRESP;
logic BVALID;
logic BREADY;

//AR and R channel signals
logic [addr_width -1:0] ARADDR;
logic ARREADY;
logic ARVALID;
logic [2:0] ARPROT;

logic [data_width -1:0] RDATA;
logic [1:0] RRESP;
logic RREADY;
logic RVALID;

clocking master_cb@(posedge ACLK); //cb-clocking block
default input #1step;
default output #1;
//MASTER DRIVES THESE
output AWADDR, AWPROT, AWVALID, WDATA, WSTRB, WVALID, BREADY, ARADDR, ARPROT, ARVALID, RREADY;
input AWREADY, WREADY, BRESP, BVALID, ARREADY, RDATA, RRESP, RVALID;
endclocking

clocking monitor_cb @(posedge ACLK);
default input #1step;
input AWREADY, WREADY, BRESP, BVALID, ARREADY, RDATA, RRESP, RVALID,AWADDR, AWPROT, AWVALID, WDATA, WSTRB, WVALID, BREADY, ARADDR, ARPROT, ARVALID, RREADY;
endclocking
modport master_mp (clocking master_cb, input ACLK, ARESETn);
modport monitor_mp (clocking monitor_cb, input ACLK, ARESETn);//modports define access writes
endinterface
`endif