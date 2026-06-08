# CS-476 Embedded System Design - PW2.2: Grayscale Custom Instruction

## Group Members

| Name               | Gaspar Number |
|--------------------|---------------|
| Gaetan Jenni       | 386450        |
| Noel Willem Pihl   | 421856        |

## Where to find the work

### Verilog

- **`modules/rgb565GrayscaleIse/verilog/rgb565GrayscaleIse.v`** - Grayscale custom instruction module, converts RGB565 to 8-bit grayscale in a single cycle using the formula: `(R*54 + G*183 + B*19) >> 8`
- **`systems/singleCore/verilog/or1420SingleCore.v`** - Top-level module modified to instantiate rgb565GrayscaleIse with custom ID 8 and wire it into the custom instruction bus

### Software

- **`programs/grayscale/src/grayscale.c`** - Modified to use the grayscale custom instruction (ID 0x8) instead of the software RGB565-to-grayscale conversion

## Profiling Results

### Assignment 1: Software grayscale (baseline)

| Metric                   | Value      |
|--------------------------|-----------:|
| Execution cycles         | 29,061,552 |
| Stall cycles             | 17,688,423 |
| Bus-idle cycles          | 16,757,073 |
| Real work (exec − stall) | 11,373,129 |

### Assignment 3: Custom instruction grayscale (4-pixel SIMD, current)

Re-measured 2026-05-04 from the committed `programs/grayscale/grayscale.c`,
which uses the 4-pixel SIMD form of the custom instruction
(`l.nios_rrr ... 0x8` — 2 input words = 4 RGB565 pixels → 1 word of 4 grayscale
bytes).

| Metric                   | Value     |
|--------------------------|----------:|
| Execution cycles         | 8,193,532 |
| Stall cycles             | 6,657,522 |
| Bus-idle cycles          | 3,602,755 |
| Real work (exec − stall) | 1,536,010 |

### Assignment 4: Comparison

Software baseline (Assignment 1) → 4-pixel SIMD CI (Assignment 3):

| Metric                   | Improvement |
|--------------------------|------------:|
| Execution cycles         |      −72%   |
| Stall cycles             |      −62%   |
| Bus-idle cycles          |      −78%   |
| Real work cycles         |  **−86%**   |
| Overall speed-up         | **3.55×**   |

**Conclusions:**

- The real computation work drops by ~7×: the multi-instruction software
  conversion (shifts, masks, multiplies, per-pixel) is replaced by a
  single-cycle custom instruction that processes 4 pixels at once.
- Stall cycles also drop substantially (−62%), because the CPU finishes its
  inner loop faster and therefore issues fewer memory accesses overall —
  individual loads/stores still stall on the bus, but there are far fewer of
  them per frame.
- Bus-idle cycles decrease in line with the shorter total runtime.
- Even after this big improvement, stalls are still the dominant cost
  (6.66 M / 8.19 M ≈ 81% of execution time). This is exactly the bottleneck
  PW6 Task 1 attacks with DMA + ping-pong (see `PW6_README.md`).
