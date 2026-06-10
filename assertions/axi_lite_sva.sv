`ifndef AXI_LITE_SVA_SV
`define AXI_LITE_SVA_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

module axi_lite_sva (
    input logic        ACLK,
    input logic        ARESETn,
    input logic        AWVALID,
    input logic        AWREADY,
    input logic [31:0] AWADDR,
    input logic        WVALID,
    input logic        WREADY,
    input logic        BVALID,
    input logic        BREADY,
    input logic [1:0]  BRESP,
    input logic        ARVALID,
    input logic        ARREADY,
    input logic [31:0] ARADDR,
    input logic        RVALID,
    input logic        RREADY,
    input logic [1:0]  RRESP
);

default clocking @(posedge ACLK); endclocking
default disable iff (!ARESETn);

//=========================================================================
// PROTOCOL ASSERTIONS — apply to any AXI-Lite slave
//=========================================================================

// 1. AWADDR must be word aligned
property p_awaddr_aligned;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID == 1) |-> (AWADDR[1:0] == 2'b00);
endproperty
a_awaddr_aligned: assert property (p_awaddr_aligned)
    else `uvm_error("SVA", "VIOLATION: AWADDR not word-aligned")

// 2. ARADDR must be word aligned
property p_araddr_aligned;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID == 1) |-> (ARADDR[1:0] == 2'b00);
endproperty
a_araddr_aligned: assert property (p_araddr_aligned)
    else `uvm_error("SVA", "VIOLATION: ARADDR not word-aligned")

// 3. AWVALID must stay high until AWREADY
property p_awvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID == 1 && AWREADY == 0) |=> (AWVALID == 1);
endproperty
a_awvalid_stable: assert property (p_awvalid_stable)
    else `uvm_error("SVA", "VIOLATION: AWVALID dropped before AWREADY")

// 4. WVALID must stay high until WREADY
property p_wvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (WVALID == 1 && WREADY == 0) |=> (WVALID == 1);
endproperty
a_wvalid_stable: assert property (p_wvalid_stable)
    else `uvm_error("SVA", "VIOLATION: WVALID dropped before WREADY")

// 5. ARVALID must stay high until ARREADY
property p_arvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID == 1 && ARREADY == 0) |=> (ARVALID == 1);
endproperty
a_arvalid_stable: assert property (p_arvalid_stable)
    else `uvm_error("SVA", "VIOLATION: ARVALID dropped before ARREADY")

// 6. AWADDR must not change while handshake pending
property p_awaddr_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID == 1 && AWREADY == 0) |=> $stable(AWADDR);
endproperty
a_awaddr_stable: assert property (p_awaddr_stable)
    else `uvm_error("SVA", "VIOLATION: AWADDR changed before AWREADY")

// 7. ARADDR must not change while handshake pending
property p_araddr_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID == 1 && ARREADY == 0) |=> $stable(ARADDR);
endproperty
a_araddr_stable: assert property (p_araddr_stable)
    else `uvm_error("SVA", "VIOLATION: ARADDR changed before ARREADY")

// 8. BVALID must drop after handshake
property p_bvalid_deasserts;
    @(posedge ACLK) disable iff (!ARESETn)
    (BVALID && BREADY) |=> (!BVALID);
endproperty
a_bvalid_deasserts: assert property (p_bvalid_deasserts)
    else `uvm_error("SVA", "VIOLATION: BVALID stayed high after handshake")

// 9. RVALID must drop after handshake
property p_rvalid_deasserts;
    @(posedge ACLK) disable iff (!ARESETn)
    (RVALID && RREADY) |=> (!RVALID);
endproperty
a_rvalid_deasserts: assert property (p_rvalid_deasserts)
    else `uvm_error("SVA", "VIOLATION: RVALID stayed high after handshake")

//=========================================================================
// DESIGN-SPECIFIC ASSERTIONS — specific to our 8-register bank
//=========================================================================

// 10. BRESP must always be OKAY
property p_bresp_always_okay;
    @(posedge ACLK) disable iff (!ARESETn)
    (BVALID && BREADY) |-> (BRESP == 2'b00);
endproperty
a_bresp_always_okay: assert property (p_bresp_always_okay)
    else `uvm_error("SVA", "DESIGN VIOLATION: BRESP is not OKAY")

// 11. RRESP must always be OKAY
property p_rresp_always_okay;
    @(posedge ACLK) disable iff (!ARESETn)
    (RVALID && RREADY) |-> (RRESP == 2'b00);
endproperty
a_rresp_always_okay: assert property (p_rresp_always_okay)
    else `uvm_error("SVA", "DESIGN VIOLATION: RRESP is not OKAY")

// 12. AWADDR must be within valid register range 0x00-0x1C
property p_awaddr_in_range;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID == 1) |-> (AWADDR >= 32'h00 && AWADDR <= 32'h1C);
endproperty
a_awaddr_in_range: assert property (p_awaddr_in_range)
    else `uvm_error("SVA", "DESIGN VIOLATION: AWADDR out of valid register range")

// 13. ARADDR must be within valid register range 0x00-0x1C
property p_araddr_in_range;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID == 1) |-> (ARADDR >= 32'h00 && ARADDR <= 32'h1C);
endproperty
a_araddr_in_range: assert property (p_araddr_in_range)
    else `uvm_error("SVA", "DESIGN VIOLATION: ARADDR out of valid register range")

endmodule
`endif