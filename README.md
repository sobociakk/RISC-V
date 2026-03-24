# RISC-V 5-Stage Pipelined Processor
A 5-stage pipelined RV32I RISC-V processor with AXI4-Lite bus, UART & GPIO — built from scratch for educational purposes.
## Scope — What's Included

|  | 
|---|
| 5-stage pipeline (IF/ID/EX/MEM/WB) |
| ~15 key RV32I instructions | 
| Data forwarding + stall logic | 
| AXI4-Lite master bus interface |
| UART + GPIO peripherals | 

### Instruction Subset (15 instructions to start)

| Category | Instructions | What they do |
|---|---|---|
| **Arithmetic** | `ADD`, `SUB`, `ADDI` | Add / subtract numbers |
| **Logic** | `AND`, `OR`, `XOR`, `ANDI` | Bitwise operations |
| **Shift** | `SLL`, `SRL` | Shift bits left / right |
| **Compare** | `SLT`, `SLTI` | Set if less than |
| **Memory** | `LW`, `SW` | Load / store a word |
| **Branch** | `BEQ`, `BNE` | Branch if equal / not equal |
| **Jump** | `JAL`, `JALR` | Function calls, returns, and indirect jumps |

Adding more instructions later just means adding entries to decoder — the pipeline doesn't change.

---

## Specifications

| Parameter | Choice | Why |
|---|---|---|
| **ISA** | RV32I (subset) | Simplest RISC-V, open-source, industry-relevant |
| **Pipeline** | 5-stage: IF → ID → EX → MEM → WB | Industry-standard, best learning value |
| **Data width** | 32-bit | Standard RV32 word size |
| **Registers** | 32 × 32-bit (2 read, 1 write) | Required by RISC-V spec |
| **Memory** | Harvard (separate I-mem / D-mem) | Avoid structural hazard on fetch + load/store |
| **I-Memory** | BRAM, 4 KB | Holds your program |
| **D-Memory** | BRAM, 4 KB | Holds data variables |
| **Bus** | AXI4-Lite master | Industry standard, connects peripherals |
| **Peripherals** | UART + GPIO via AXI4-Lite | Proves the bus actually works |
| **Target** | Any FPGA board (~50–100 MHz) | Basys 3, DE10-Lite, Tang Nano, etc. |

---

## Design Trade-offs

| | Single-cycle | 5-stage pipeline |
|---|---|---|
| Clock speed | Slow (long critical path) | Fast (short stages) |
| Throughput | 1 instr / long cycle | ~1 instr / short cycle |
| Complexity | Simple | Medium (hazards to handle) |

### Why Harvard memory?

In a pipelined design, the IF stage reads an instruction while the MEM stage reads/writes data — at the same time. Two separate memories let both happen in parallel.

### Why AXI4-Lite?

- **Industry standard** — used everywhere in Xilinx/AMD and ARM SoCs
- **Simple variant** of AXI — no burst, no out-of-order — perfect for learning
- **Proves system integration** — CPU actually talks to peripherals
  
---

### What Each Stage Does

| Stage | Describe | Key hardware |
|---|---|---|
| ** IF** | Uses the PC to read the next instruction from memory. PC increments by +4 (or jumps if branching). | PC register, I-MEM, adder, mux |
| ** ID** | Figures out what instruction it is, reads source registers, generates immediate. | Decoder, Register File (2 read ports), Imm Gen |
| ** EX** | Does the actual computation (add, subtract, compare, shift). Checks branch conditions. | ALU, Branch Comparator, Forwarding Muxes |
| ** MEM** | Access data memory — only used by `LW` (load) and `SW` (store). Other instructions just pass through. | Data Memory |
| ** WB** | Writes the result back into the register file (destination register `rd`). | Write-back mux |

### Pipeline Registers

Each pair of stages is separated by a pipeline register that stores everything the next stage needs:

| Pipeline Register | What it carries |
|---|---|
| **IF/ID** | Instruction word, PC value |
| **ID/EX** | Control signals, register values, immediate, rd, PC |
| **EX/MEM** | ALU result, write data, rd, control signals |
| **MEM/WB** | ALU result or memory data, rd, control signals |

> These are flip-flops that update every clock edge — they're what make pipelining work.

---

## Hazards — The Tricky Part

Hazards are situations where the pipeline can't just keep flowing. There are three kinds, two of which need to be handled at this stage:

### Data Hazard (most common)

**Problem:** An instruction needs a value that the previous instruction hasn't written back yet.

```
ADD  x3, x1, x2    ← writes to x3
SUB  x5, x3, x4    ← needs x3, but it's not in the register file yet!
```

**Solution — Forwarding:** Grab the result directly from the pipeline register instead of waiting for write-back.

### Control Hazard (branches)

**Problem:** A branch decides to jump, but 2 instructions after it are already in the pipeline.

**Solution (v1):** Flush those 2 instructions (replace with NOPs). Costs 2 cycles per taken branch. Simple and correct — optimize later.

---

## AXI4-Lite Bus

AXI4-Lite is a simple request/response bus. CPU is the master, peripherals are slaves.

### Address Map

| Peripheral | Address Range | What it does |
|---|---|---|
| Data Memory | `0x0000_0000` – `0x0000_0FFF` | RAM for variables |
| UART | `0x1000_0000` – `0x1000_000F` | Serial print / receive |
| GPIO | `0x2000_0000` – `0x2000_0003` | LED / button control |

### Key AXI4-Lite Signals

| Channel | Signals | Direction | Purpose |
|---|---|---|---|
| Write Address | `AWADDR`, `AWVALID`, `AWREADY` | M → S | Where to write |
| Write Data | `WDATA`, `WSTRB`, `WVALID`, `WREADY` | M → S | What to write |
| Write Response | `BRESP`, `BVALID`, `BREADY` | S → M | Write OK? |
| Read Address | `ARADDR`, `ARVALID`, `ARREADY` | M → S | Where to read |
| Read Data | `RDATA`, `RRESP`, `RVALID`, `RREADY` | S → M | Data back |

