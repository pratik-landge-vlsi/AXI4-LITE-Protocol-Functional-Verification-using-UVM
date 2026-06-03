# AXI4-Lite Slave Verification Using UVM

An industry-grade UVM 1.2 verification environment for an AXI4-Lite slave register bank, built from scratch over 40 days as a self-directed summer project.

---

## What This Project Is

This testbench verifies an open-source AXI4-Lite slave RTL using constrained-random stimulus, a reference model scoreboard, and a fully automated regression suite. Every transaction is independently observed by a monitor, compared against a software reference model, and reported as PASS or FAIL.

The goal was to build something that looks and works like a real industry testbench, not a tutorial project.

---

## Architecture

uvm_test_top
+-- env              (axi_lite_env)
+-- agt              (axi_lite_agent — ACTIVE mode)
¦     +-- drv        (axi_lite_driver)
¦     +-- sqr        (axi_lite_sequencer)
¦     +-- mon        (axi_lite_monitor)
+-- ref_model        (axi_lite_ref_model)
+-- scb              (axi_lite_scoreboard)


- Driver drives AXI4-Lite signals using fork-join for simultaneous AW and W channel handshakes
- Monitor independently observes every completed transaction without driving any signal
- Reference Model maintains a software register bank with correct WSTRB byte-lane masking
- Scoreboard compares every read-back against the reference model and reports PASS or FAIL

---

## What Is Verified

| Scenario | Sequence | Status |
|---|---|---|
| All 8 register addresses | Address Sweep | ? |
| All 15 WSTRB byte-lane patterns | WSTRB Sweep | ? |
| Back-to-back partial writes same register | Burst Write | ? |
| Constrained-random write-readback | Random Regression | ? |
| Bug injection (WSTRB ignore) caught | RTL mutation | ? |

---

## How to Run

### Prerequisites
- QuestaSim 2026.1 with UVM 1.2
- UVM DPI library compiled (see sim/uvm_dpi/)

### Single run
```bash
cd sim
make run
```

### Run with a specific seed
```bash
make run SEED=12345
```

### Full regression (5 seeds)
```bash
make regression
```

### GUI with waveforms
```bash
make gui
```

---

## RTL Source

Open-source AXI4-Lite register interface from Alex Forencich's verilog-axi library.  
Wrapped with an 8×32-bit register bank in `tb/top.sv`.

---

## Tools

- QuestaSim 2026.1
- UVM 1.2
- SystemVerilog
- NC State University ECE servers (grendel cluster)

---

## Author

Pratik Landge  
MS Computer Engineering, NC State University  
[LinkedIn](https://www.linkedin.com/in/pratik-landge/)

