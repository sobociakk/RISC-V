# RISC-V 5-Stage Pipelined Processor
---

## Scope — What's Included

| Included | 
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

### Why 5-stage pipeline?

Think of a pipeline like a laundry assembly line:

```
Without pipeline:  [wash+dry+fold]        [wash+dry+fold]        ← 1 shirt at a time
                   ==================     ==================

With 5-stage:      [wash] [dry] [fold]                            ← 3 shirts overlapping
                          [wash] [dry] [fold]
                                 [wash] [dry] [fold]
```

Each stage does less work → shorter clock period → higher clock speed.

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
- **Proves system integration** — your CPU actually talks to peripherals
  
---

### What Each Stage Does

| Stage | Plain English | Key hardware |
|---|---|---|
| **① IF** | Uses the PC to read the next instruction from memory. PC increments by +4 (or jumps if branching). | PC register, I-MEM, adder, mux |
| **② ID** | Figures out what instruction it is, reads source registers, generates immediate. | Decoder, Register File (2 read ports), Imm Gen |
| **③ EX** | Does the actual computation (add, subtract, compare, shift). Checks branch conditions. | ALU, Branch Comparator, Forwarding Muxes |
| **④ MEM** | Access data memory — only used by `LW` (load) and `SW` (store). Other instructions just pass through. | Data Memory |
| **⑤ WB** | Writes the result back into the register file (destination register `rd`). | Write-back mux |

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

---

## Build Roadmap (~8 weeks)

| Phase | What to do | Time |
|---|---|---|
| **1. Study** | Learn RV32I encoding + pipeline concepts (Harris & Harris book, Ch. 7) | 1 week |
| **2. ALU + RegFile** |Code modules & write basic testbenches | 1 week |
| **3. Pipeline skeleton** | Wire up 5 stages, simulate basic instruction flow | 1.5 weeks |
| **4. Hazards** | Add forwarding unit + stall logic + branch flush | 1.5 weeks |
| **5. Memory** | Integrate BRAM for I-MEM and D-MEM | 3–4 days |
| **6. AXI4-Lite** | Build bus master + interconnect + UART slave | 1.5 weeks |
| **7. Simulate** | Run C/Assembly test programs, verify full AXI interactions, finishing full system | 1.5 weeks |
