# CS-476 Embedded System Design - PW2: Profiling Module

## Group Members

| Name               | Gaspar Number |
|--------------------|---------------|
| Gaetan Jenni       | 386450        |
| Noel Willem Pihl   | 421856        |

## Where to find the work

### Verilog

- **`modules/profiling/verilog/profiling.v`** - Profiling custom instruction module, containing 4 hardware counters controllable via custom instruction
- **`modules/profiling/verilog/counter.v`** - 32-bit up/down counter used by the profiling module
- **`modules/profiling/verilog/profiling_tb.v`** - Testbench for the profiling module
- **`systems/singleCore/verilog/or1420SingleCore.v`** - Top-level module modified to instantiate profileCi with custom ID 11 (0xB) and wire it into the custom instruction bus
- **`systems/singleCore/scripts/yosysOr1420.script`** - Updated to include counter.v and profiling.v in the synthesis

### Software

- **`programs/grayscale/src/grayscale.c`** - Modified to use the profiling custom instruction to measure and print execution cycles, stall cycles, and bus-idle cycles for the grayscale conversion loop
