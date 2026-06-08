# CS-476 Embedded System Design - PW4: Build-in Peripheral DMA-Controller

## Group Members

| Name               | Gaspar Number |
|--------------------|---------------|
| Gaetan Jenni       | 386450        |
| Noel Willem Pihl   | 421856        |

## Where to find the work

### Verilog

- **`modules/ramDmaCi/verilog/ramDmaCi.v`** - 512x32-bit dual-ported CI-attached memory plus DMA-controller. Port A (CPU clock) serves the custom-instruction interface; port B (negative edge of the CPU clock) is driven by the DMA engine. The module holds the DMA FSM, the bus-in registers and the bus-out flip-flops.
- **`systems/singleCore/verilog/or1420SingleCore.v`** - Top-level wiring: custom-instruction ID 0xC, bus master request/grant on `s_busRequests[27]` / `s_busGrants[27]`, and the DMA contribution to the ORed bus signals (`s_beginTransaction`, `s_endTransaction`, `s_addressData`, `s_byteEnables`, `s_readNotWrite`, `s_dataValid`, `s_burstSize`).

### Software

- **`programs/ramDmaCiTest/src/ramDmaCiTest.c`** - Polling-mode test program: memory round-trip, register width masks, illegal accesses (`control=3`, `valueA[31:13] != 0`), and DMA transfers bus <-> CI-memory for single-burst, multi-burst and partial-last-burst patterns in both directions.

## Snapshots per sub-exercise

Each folder of the "PW4_snapshots" folder holds the version of the three source files at the corresponding milestone. The current virtualprototype corresponds to the latest version (PW4.4).
