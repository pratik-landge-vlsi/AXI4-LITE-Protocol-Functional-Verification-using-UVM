`ifndef AXI_LITE_MONITOR_SV
`define AXI_LITE_MONITOR_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_lite_transaction.sv"

class axi_lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_if #(.data_width(32), .addr_width(32)) vif;
    uvm_analysis_port #(axi_lite_transaction) ap;

    function new(string name = "axi_lite_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi_lite_if #(.data_width(32),
                             .addr_width(32)))::get(this, "", "vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface in config DB")
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info("MONITOR", "Monitor active from time 0. Waiting for reset.", UVM_LOW)
        wait(vif.ARESETn === 1'b1);
        @(posedge vif.ACLK);
        `uvm_info("MONITOR", "LESGOO BRO-reset deasserted, lets watch the drama", UVM_LOW)

        forever begin
            @(posedge vif.ACLK);

            if (vif.AWVALID === 1'b1 && vif.AWREADY === 1'b1) begin
                axi_lite_transaction txn;
                txn = axi_lite_transaction::type_id::create("txn");
                txn.rw    = WRITE;
                txn.addr  = vif.AWADDR;
                txn.data  = vif.WDATA;
                txn.wstrb = vif.WSTRB;
                collect_write(txn);
                ap.write(txn);
                `uvm_info("MON",
                    $sformatf("Observed: %s", txn.convert2string()), UVM_LOW)
            end

            else if (vif.ARVALID === 1'b1 && vif.ARREADY === 1'b1) begin
                axi_lite_transaction txn;
                txn = axi_lite_transaction::type_id::create("txn");
                txn.rw   = READ;
                txn.addr = vif.ARADDR;
                collect_read(txn);
                ap.write(txn);
                `uvm_info("MON",
                    $sformatf("Observed: %s", txn.convert2string()), UVM_LOW)
            end
        end
    endtask

    task collect_write(axi_lite_transaction txn);
        // Explicit loop — no iff construct, no clocking block
        // Wait until BVALID+BREADY seen on a clock edge
        do @(posedge vif.ACLK);
        while (!(vif.BVALID === 1'b1 && vif.BREADY === 1'b1));
        txn.resp = vif.BRESP;
    endtask

    task collect_read(axi_lite_transaction txn);
        // Explicit loop — no iff construct, no clocking block
        do @(posedge vif.ACLK);
        while (!(vif.RVALID === 1'b1 && vif.RREADY === 1'b1));
        txn.data  = vif.RDATA;
        txn.resp  = vif.RRESP;
        txn.wstrb = 4'b0000;
    endtask

endclass
`endif
