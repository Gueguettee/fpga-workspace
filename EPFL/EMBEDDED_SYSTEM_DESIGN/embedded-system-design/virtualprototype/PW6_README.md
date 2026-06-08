# CS-476 Embedded System Design - PW6: Streaming Interface

## Group Members

| Name               | Gaspar Number |
|--------------------|---------------|
| Gaetan Jenni       | 386450        |
| Noel Willem Pihl   | 421856        |

---

## Task 1 — Overlap transfer with calculation

### Where to find the work

Inside the pw6_1 zip folder.

#### Verilog

- No Verilog changes for Task 1.

#### Software

- **`programs/streamingDma/src/streamingDma.c`** - New program implementing the DMA + ping-pong RGB565→grayscale pipeline. Splits the 2 kB CI memory into two 1 kB half-buffers, runs 600 batches of 512 pixels per frame (640×480), and overlaps the next batch's DMA-in with the current batch's grayscale conversion.

### Profiling Results

Steady-state per-frame counter values, taken from the on-screen serial output. The committed program uses `BURST = 255` (one 256-word burst per DMA-in, one 128-word burst per DMA-out).

#### PW2 baseline (4-pixel SIMD CI, no DMA)

| Metric            | Value     |
|-------------------|----------:|
| Execution cycles  | 8,193,532 |
| Stall cycles      | 6,657,522 |
| Bus-idle cycles   | 3,602,755 |

#### Task 1: DMA + ping-pong (current)

| Metric            | Value     |
|-------------------|----------:|
| Execution cycles  | 2,446,663 |
| Stall cycles      | 1,157,989 |
| Bus-idle cycles   |   975,606 |

#### Comparison

PW2 baseline → Task 1 (DMA + ping-pong):

| Metric            | Improvement |
|-------------------|------------:|
| Execution cycles  |      −70%   |
| Stall cycles      |      −83%   |
| Bus-idle cycles   |      −73%   |
| Overall speed-up  | **3.35×**   |

**Conclusions:**

- Execution cycles drop ~3.35×. Removing the per-word CPU bus round-trips and overlapping DMA with compute is the main contributor.
- Stall cycles drop ~5.75×. The inner loop now hits on-chip CI memory (single-cycle access) instead of the slow bus, so the CPU spends far less time stalled on bus loads/stores.
- Bus-idle cycles drop ~3.69×. DMA bursts keep the bus continuously busy during a transfer, whereas CPU loads only occupy the bus briefly between long stalls.
- The displayed image is visually identical to PW2's.

---

## Task 2 — Streaming accelerator

### Task 2 — where to find the work

Inside the pw6_2 zip folder.

#### Verilog (Task 2)

- **`modules/camera/verilog/camera.v`** - Two `rgb565Grayscale` instances convert each of the 2 RGB565 pixels to 8-bit luminance. The new wire `grayscalePixelWord_s` packs each luminance back into all three RGB565 channels so the result is still a valid RGB565 word but visually gray.

#### Software (Task 2)

- No software changes for Task 2.

### Task 2 verification

- Display: live image, visually grayscale, at 15 fps.

---

## Task 3 — Optimised streaming interface

### Task 3 — where to find the work

Inside the pw6_3 zip folder.

#### Verilog (Task 3)

- **`modules/camera/verilog/camera.v`** - Updated grabber to pack 4 grayscale pixels per 32-bit lineBuffer word:
  - `s_weLineBuffer` now fires every 8 pclk cycles instead of every 4. The OV7670 produces 2 pclk per pixel, so 8 pclk = 4 pixels. For a 640-pixel line (1280 pclk cycles) this drops from 320 words/line to **160 words/line** — exactly half.

#### Software (Task 3)

- **`programs/streaming/src/streaming.c`** - Commented out `#define __RGB565__`. With the macro undefined.

### Task 3 verification

- Display: live grayscale image at 15 fps, visually identical to Task 2.
