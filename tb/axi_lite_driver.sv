`ifndef AXI_LITE_DRIVER_SV
`define AXI_LITE_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_transaction.sv"

class axi_lite_driver extends uvm_driver #(axi_lite_transaction);
    `uvm_component_utils(axi_lite_driver)
    virtual axi_lite_if #(.data_width(32), .addr_width(32)) vif;

    function new(string name = "axi_lite_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi_lite_if #(.data_width(32),
                             .addr_width(32)))::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "No virtual interface found in config DB")
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_transaction txn;
        vif.master_cb.AWVALID <= 0;
        vif.master_cb.AWADDR  <= 0;
        vif.master_cb.AWPROT  <= 0;
        vif.master_cb.WVALID  <= 0;
        vif.master_cb.WDATA   <= 0;
        vif.master_cb.WSTRB   <= 0;
        vif.master_cb.BREADY  <= 1;
        vif.master_cb.ARVALID <= 0;
        vif.master_cb.ARADDR  <= 0;
        vif.master_cb.ARPROT  <= 0;
        vif.master_cb.RREADY  <= 1;
        @(posedge vif.ACLK iff vif.ARESETn === 1'b1);
        @(posedge vif.ACLK);
        `uvm_info("DRV", "RESET deasserted- LETS DRIVE BABYYY", UVM_LOW)
        forever begin
            seq_item_port.get_next_item(txn);
            if (txn.rw == WRITE) drive_write(txn);
            else                 drive_read(txn);
            seq_item_port.item_done();
        end
    endtask

    task drive_write(axi_lite_transaction txn);
        `uvm_info("DRV", $sformatf("driving WRITE:rw=WRITE addr=0x%08h data=0x%08h wstrb=4'b%04b resp=2'bxx",
            txn.addr, txn.data, txn.wstrb), UVM_LOW)
        vif.master_cb.AWVALID <= 1'b1;
        vif.master_cb.AWADDR  <= txn.addr;
        vif.master_cb.AWPROT  <= 3'b000;
        vif.master_cb.WVALID  <= 1'b1;
        vif.master_cb.WDATA   <= txn.data;
        vif.master_cb.WSTRB   <= txn.wstrb;
        // FORK-JOIN — detect AW and W handshakes in parallel
        // Sequential waits cause WREADY to be missed on back-to-back txns
        fork
            begin @(posedge vif.ACLK iff vif.master_cb.AWREADY === 1'b1); end
            begin @(posedge vif.ACLK iff vif.master_cb.WREADY  === 1'b1); end
        join
        vif.master_cb.AWVALID <= 1'b0;
        vif.master_cb.WVALID  <= 1'b0;
        `uvm_info("DRV", "Handhshake completed for AW & W channel", UVM_LOW)
        // Direct read for BVALID — avoids clocking block 1ns skew missing single-cycle pulse
        do @(posedge vif.ACLK);
        while (!(vif.BVALID === 1'b1 && vif.BREADY === 1'b1));
        txn.resp = vif.BRESP;
        `uvm_info("DRV", $sformatf("Write complete. BRESP=2'b%02b", txn.resp), UVM_LOW)
    endtask

    task drive_read(axi_lite_transaction txn);
        `uvm_info("DRV", $sformatf("driving READ:rw=READ addr=0x%08h data=0x%08h wstrb=4'b0000 resp=2'bxx",
            txn.addr, txn.data), UVM_LOW)
        vif.master_cb.ARVALID <= 1'b1;
        vif.master_cb.ARADDR  <= txn.addr;
        vif.master_cb.ARPROT  <= 3'b000;
        @(posedge vif.ACLK iff vif.master_cb.ARREADY === 1'b1);
        vif.master_cb.ARVALID <= 1'b0;
        // Direct read for RVALID — same reason as BVALID above
        do @(posedge vif.ACLK);
        while (!(vif.RVALID === 1'b1 && vif.RREADY === 1'b1));
        txn.data = vif.RDATA;
        txn.resp = vif.RRESP;
        `uvm_info("DRV", $sformatf("Read complete. RDATA=0x%08h RRESP=2'b%02b",
            txn.data, txn.resp), UVM_LOW)
    endtask

endclass
`endif
