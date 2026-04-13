# MIPS-processor-DFT-and-ATPG-
An industry-standard manufacturing test flow implementing Scan Chain Insertion and Automated Test Pattern Generation (ATPG) for a MIPS Processor.
<div align="center">

# Single-Cycle MIPS Processor: DFT Insertion & ATPG

</div>

<div align="center">

![Cadence Genus](https://img.shields.io/badge/Cadence-Genus%20Synthesis-blue?style=for-the-badge)
![Cadence Modus](https://img.shields.io/badge/Cadence-Modus%20ATPG-blue?style=for-the-badge)
![Technology](https://img.shields.io/badge/Tech-90nm%20CMOS-green?style=for-the-badge)
![Coverage](https://img.shields.io/badge/Fault%20Coverage-99.97%25-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

*Complete Design-for-Test (DFT) insertion and Automatic Test Pattern Generation (ATPG) flow for a single-cycle MIPS processor implemented in 90nm CMOS technology*

[Overview](#-overview) • [Architecture](#-architecture) • [DFT Flow](#-dft-flow) • [Results](#-results) • [Getting Started](#-getting-started)

---

</div>

## 🎯 Overview

This project presents a **complete DFT insertion and ATPG flow** for a synthesized Single-Cycle MIPS processor (`mips_easy`), targeting a **90nm CMOS foundry library**. The flow covers RTL design with DFT-ready ports, Cadence Genus–based scan chain insertion, Cadence Modus–based test pattern generation, and full structural verification — achieving an industry-grade **99.97% adjusted fault coverage** across 237,332 static faults.

### ✨ Key Highlights

- 🔬 **99.97% ATCov**: Near-complete stuck-at fault coverage with only 5 redundant faults
- ⛓️ **Single 9,214-bit Scan Chain**: Full muxed-scan architecture connecting all sequential elements
- ⚡ **1,512 Test Patterns**: Generated in under 47 seconds of ATPG CPU time
- 🛠️ **Industry-Standard Toolchain**: Cadence Genus (synthesis + DFT) + Cadence Modus (ATPG)
- 🏗️ **Complete Flow**: RTL → DFT-annotated netlist → scan insertion → ATPG → simulation vectors

---

## 🏗 Architecture

### Design Hierarchy

```
mips_easy (Top)
├── control_unit         — Opcode decoder (R-type, LW, SW, BEQ, ADDI, J, JAL)
├── register_file        — 32 × 32-bit register file (inferred as scan FFs)
├── alu_control          — ALU function decoder
├── alu                  — 32-bit ALU (AND, OR, ADD, SUB, SLT)
└── data_memory          — 256-word synchronous SRAM (excluded from scan; MBIST target)
```

### RTL Port Map

| Port | Direction | Width | Description |
|:-----|:---------:|:-----:|:------------|
| `clk` | Input | 1 | System clock |
| `rst_n` | Input | 1 | Active-low synchronous reset |
| `pc_out` | Output | 32 | Program Counter output to instruction memory |
| `instr` | Input | 32 | Fetched instruction word |
| `scan_en` | Input | 1 | **DFT** — Scan shift enable (active high) |
| `scan_in` | Input | 1 | **DFT** — Serial scan data input |
| `scan_out` | Output | 1 | **DFT** — Serial scan data output |
| `test_mode` | Input | 1 | **DFT** — Global test mode control |

### Supported ISA

```
R-type  (opcode 0x00)  :  ADD, SUB, AND, OR, SLT
LW      (opcode 0x23)  :  Load Word
SW      (opcode 0x2B)  :  Store Word
BEQ     (opcode 0x04)  :  Branch if Equal
ADDI    (opcode 0x08)  :  Add Immediate
J       (opcode 0x02)  :  Jump
JAL     (opcode 0x03)  :  Jump and Link
```

---

## 🔄 DFT Flow

```
┌─────────────────────────────────────────────────────────────┐
│               RTL Design (mips_easy.v)                      │
│         DFT ports pre-declared: scan_en, scan_in,           │
│         scan_out, test_mode                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           SYNTHESIS (Cadence Genus — 90nm)                  │
│   • Generic synthesis  →  Technology mapping (slow.lib)     │
│   • Pre-DFT incremental optimization                        │
│   • Pre-DFT netlist: mips_easy_pre_dft.v                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          DFT INSERTION (Cadence Genus)                      │
│   • Scan style: Muxed-Scan                                  │
│   • replace_scan  →  Flip-flops → Scan FFs                  │
│   • connect_scan_chains (chain1: scan_in → scan_out)        │
│   • Post-DFT incremental optimization                       │
│   • Outputs: mips_easy_post_dft.v, .scandef, .pinassign,    │
│              .modedef                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│      STRUCTURAL VERIFICATION (Cadence Modus)                │
│   • Controllability: scan_in → chain1 ✅                    │
│   • Observability:   chain1 → scan_out ✅                   │
│   • Clock race check: Passed ✅                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│        ATPG — FULLSCAN (Cadence Modus)                      │
│   • Fault model: Stuck-at (static)                          │
│   • Test sections: Scan + Reset/Set + Static Logic          │
│   • 1,512 patterns generated in 46.44s CPU time             │
│   • ATCov: 99.97% over 237,332 faults                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│     SIMULATION VECTORS (Verilog + Cyclemap)                 │
│   • 13,934,595 simulation cycles                            │
│   • Total sim time: ~1.11 seconds                           │
│   • Binary-encoded Scan_Load / Shift / Measure_PO /         │
│     Scan_Unload sequences                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 Scan Chain Architecture

| Parameter | Value |
|:----------|:------|
| Scan Style | Muxed-Scan |
| Total Chains | 1 (`chain1`) |
| Chain Length | **9,214 bits** |
| Clock Domain | `clk_test` (Rising Edge) |
| Shift Enable | `scan_en` (Active High) |
| Scan Input (PI) | `scan_in` |
| Scan Output (PO) | `scan_out` |
| First FF | `pc_reg_reg[2]` |
| Last FF | `u_regfile_regs_reg[31][15]` |

### Chain Composition

```
Bits 1   – 30   :  pc_reg_reg[2..31]            (Program Counter, 30 bits)
Bits 31  – 8222 :  u_dmem_mem_reg[0..255][0..31] (Data Memory, 256×32 bits)
Bits 8223 – 9214:  u_regfile_regs_reg[0..31][0..31] (Register File, 32×32 bits)
```

> **Note:** Although data memory appears in the scan chain (Genus inferred it as flip-flops due to the `ram_style = "registers"` pragma interaction), production DFT intent is to exclude `data_memory` from scan and cover it with MBIST. The `set_dont_scan` directive in the Genus script handles this separation.

---

## 📊 Results

### Design Structure Summary

| Metric | Value |
|:-------|:-----:|
| Flattened Logic Blocks | 137,001 |
| Total Pins (Hierarchical) | 986,323 |
| Technology Library Cells | 23,077 |
| MUX2 Cells (Scan Muxes + Logic) | 18,488 |
| Tied-to-0 Nets | 2,046 |
| Tied-to-1 Nets | 1,022 |
| Primary Inputs | 37 |
| Primary Outputs | 33 |
| DFT Control Points | 1 (`scan_in`) |
| DFT Observe Points | 1 (`scan_out`) |

---

### ATPG Coverage Results

| Fault Class | Count |
|:------------|:-----:|
| Total Static Faults | 237,332 |
| Faults Tested | 237,266 |
| Possibly Tested | 0 |
| Redundant (Untestable) | 5 |
| Untested | 61 |
| **Test Coverage (%TCov)** | **99.97%** |
| **Adjusted Test Coverage (%ATCov)** | **99.97%** |

### Pattern Statistics

| Test Section | Patterns |
|:-------------|:--------:|
| Scan | 1 |
| Reset/Set | 1 |
| Static Logic | 1,510 |
| **Total** | **1,512** |

### ATPG Performance

| Metric | Value |
|:-------|:-----:|
| CPU Time | 46.44 seconds |
| Elapsed Time | 53.53 seconds |
| Peak Memory Usage | ~65.5 MB |

### Coverage Progression

The ATPG engine converges quickly, reaching major milestones as follows:

```
Patterns    ATCov
       1 →  28.05%   (Initial scan test)
       2 →  28.48%   (Reset/Set test)
      18 →  54.76%   (First 16 logic tests)
     256 →  75.79%
     512 →  85.54%
     768 →  91.10%
    1024 →  95.71%
    1280 →  99.50%
    1512 →  99.97%   ← Final
```

---

### Structural Verification Status

| Check | Status |
|:------|:------:|
| Scan Chain Controllability | ✅ Verified |
| Scan Chain Observability | ✅ Verified |
| Clock Race Conditions | ✅ Clean |
| DFT Rules Check | ✅ Pass |

---

## ⏱️ Simulation Parameters

| Parameter | Value |
|:----------|:-----:|
| Test Clock Period | 80.000 ns |
| Test Pulse Width | 8.000 ns |
| Strobe Offset | 72.000 ns |
| Strobe Type | Edge-based |
| Time Units | Nanoseconds (ns) |
| Total Simulation Cycles | 13,934,595 |
| Total Simulation Time | ~1,113,299,840 ns (≈ 1.11 s) |

### Vector Encoding

Test vectors are binary-encoded using four operation phases per cycle:

```
Scan_Load    — Load parallel data into scan flip-flops
Shift        — Serial shift through scan chain (9,214 clock pulses)
Measure_PO   — Capture primary output responses
Scan_Unload  — Serially unload captured state for comparison
```

Event codes used in the cyclemap: `104` (Mode Init), `600` (Scan Shift Enable), `300` (Scan Data Stream), `900` (Test Sequence Delimiter).

---

## 📁 Repository Structure

```
.
├── rtl/
│   └── mips_easy.v              # RTL source with DFT ports
├── scripts/
│   ├── run_genus_dft.tcl        # Cadence Genus synthesis + DFT insertion script
│   └── run_modus_atpg.tcl       # Cadence Modus ATPG script
├── reports/
│   ├── scan_chains.rpt          # Scan chain detailed listing (9,214 FFs)
│   ├── test_structures.rpt      # Design structure statistics
│   ├── verify_structures.rpt    # Structural verification results
│   └── test_coverage.rpt        # ATPG coverage report with progression log
├── vectors/
│   ├── test_vectors_v_mainsim.v # Simulation timing parameters
│   ├── test_vectors_v.cyclemap  # Cycle-accurate event map
│   └── test_vectors_v_1.verilog # Binary-encoded test vectors
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

```bash
# Required EDA Tools
- Cadence Genus Synthesis Solution  (synthesis + DFT insertion)
- Cadence Modus DFT Software        (ATPG + simulation)

# Foundry Library (90nm)
- slow.lib  at  /home/install/FOUNDRY/digital/90nm/dig/lib/
- Verilog cell models at /home/install/FOUNDRY/digital/90nm/dig/
```

### Running Synthesis + DFT Insertion

```tcl
# Launch Genus
genus -legacy_ui

# Source the DFT script
source run_genus_dft.tcl
```

This will produce:
- `mips_easy_post_dft.v` — post-DFT gate-level netlist
- `mips_easy.scandef` — scan chain definition for Modus
- `mips_easy.pinassign`, `test.modedef` — Modus protocol files
- `scan_chains.rpt`, `post_dft_timing.rpt`, `post_dft_area.rpt`, `post_dft_power.rpt`

### Running ATPG

```tcl
# Launch Modus
modus -gui

# Source the ATPG script
source run_modus_atpg.tcl
```

This will:
1. Build the flattened gate model
2. Set FULLSCAN testmode
3. Verify scan structures
4. Build the stuck-at fault list
5. Generate and simulate 1,512 test patterns
6. Output `test_vectors_v_1.verilog` and `test_vectors_v.cyclemap`

### Verifying Patterns in Simulation

```bash
# Use Modus built-in simulator
# (timing parameters from test_vectors_v_mainsim.v)
#   Period    : 80 ns
#   Pulse     : 8 ns
#   Strobe    : 72 ns (edge-based)
```

---

## 🔬 Technical Notes

**Why is `data_memory` in the scan chain?**
The RTL uses `(* ram_style = "block" *)` on `data_memory`, which instructs the synthesizer to infer SRAM macros. However, because the netlist was flattened for ATPG and the macro models resolve to flip-flops in the flat model, Genus included those registers in the scan chain. In a full back-end flow, `set_dont_scan [get_cells u_dmem/*]` would be applied, and the memory would be verified separately via MBIST.

**Why are 5 faults redundant?**
These are structurally untestable faults, typically arising from constant-propagation through tied nets (2,046 tied-to-0, 1,022 tied-to-1 nets are present in this netlist). They represent logic that is physically unreachable regardless of primary input combinations, not a limitation of the ATPG engine.

**Dynamic fault coverage is 0.00% in this run.**
Only the static (stuck-at) fault model was executed in this experiment. Transition-delay (dynamic) fault coverage requires a separate ATPG run with a functional clock constraint and is not part of this experiment's scope.

---

## 🎓 Academic Context

**Course**: Digital Systems Testing  
**Experiment**: DFT Insertion & ATPG on a MIPS Processor  
**Institution**: IIITDM Kurnool  
**Tools**: Cadence Genus, Cadence Modus  
**Technology**: 90nm CMOS (slow corner library)

### Learning Outcomes

- RTL design with DFT-ready ports and scan methodology
- Muxed-scan chain insertion using Cadence Genus
- Scan structure verification (controllability & observability)
- ATPG pattern generation with the FULLSCAN test mode
- Interpreting fault coverage reports and pattern statistics
- Test vector encoding and simulation for manufacturing test

---

## 📚 References

1. M. Abramovici, M. A. Breuer, and A. D. Friedman, *Digital Systems Testing and Testable Design*, IEEE Press, 1994.
2. Z. Navabi, *Digital System Test and Testable Design*, Springer, 2011.
3. Cadence Design Systems, *Genus Synthesis Solution User Guide*.
4. Cadence Design Systems, *Modus DFT Software Solution User Guide*.
5. P. Goel, "An Implicit Enumeration Algorithm to Generate Tests for Combinational Logic Circuits," *IEEE Trans. Computers*, 1981.

---

## 🛠 Tools & Technologies

| Category | Tool / Technology |
|:---------|:------------------|
| RTL Design | Verilog HDL |
| Synthesis & DFT | Cadence Genus Synthesis Solution |
| ATPG | Cadence Modus DFT Software Solution |
| Technology Library | 90nm CMOS (slow corner) |
| Scan Style | Muxed-Scan |
| Fault Model | Stuck-at (Static) |

---

## 📬 Contact

**Vedansh Paliwal**  
Roll Number: 123EC0013  
Electronics and Communication Engineering  
**Indian Institute of Information Technology Design and Manufacturing, Kurnool (A.P.)**

---

<div align="center">

### ⭐ Star this repository if you found it helpful!

</div>
