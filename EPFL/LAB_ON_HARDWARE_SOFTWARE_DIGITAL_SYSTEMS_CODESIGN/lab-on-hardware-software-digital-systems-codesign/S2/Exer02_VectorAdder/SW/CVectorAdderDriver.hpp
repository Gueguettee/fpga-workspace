#ifndef CVECTORADDER_HPP
#define CVECTORADDER_HPP

class CVectorAdderDriver : public CAccelDriver {
  protected:
    // Structure that mimics the layout of the peripheral registers.
    // Vitis HLS skips some addresses in the register file. We introduce
    // padding fields to create the right mapping to registers with our structure,
    struct TRegs {
      uint32_t control; // 0x00
      uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
      uint32_t input1; // 0x10
      uint32_t input1_h; // 0x14 The project wa configured for 64-bit addresses, so we need to set this register to 0
      uint32_t padding0; // 0x18
      uint32_t input2; // 0x1C
      uint32_t input2_h; // 0x20 The project wa configured for 64-bit addresses, so we need to set this register to 0
      uint32_t padding1; // 0x24
      uint32_t output; // 0x28
      uint32_t output_h; // 0x2C The project wa configured for 64-bit addresses, so we need to set this register to 0
      uint32_t padding2; // 0x30
      uint32_t length; // 0x34
      uint32_t padding3; //0x38
      uint32_t accum; // 0x3C
    };

  public:
    CVectorAdderDriver(bool Logging = false)
      : CAccelDriver(Logging) {}

    ~CVectorAdderDriver() {}

    uint32_t Add(void * input1, void * input2, void * output,
              uint32_t length, uint32_t accum, uint64_t & elapsed);
};


#endif  // CVECTORADDER_HPP

// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2022.2 (64-bit)
// Tool Version Limit: 2019.12
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// ==============================================================
// control
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read/COR)
//        bit 7  - auto_restart (Read/Write)
//        bit 9  - interrupt (Read)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0 - enable ap_done interrupt (Read/Write)
//        bit 1 - enable ap_ready interrupt (Read/Write)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0 - ap_done (Read/TOW)
//        bit 1 - ap_ready (Read/TOW)
//        others - reserved
// 0x10 : Data signal of input1
//        bit 31~0 - input1[31:0] (Read/Write)
// 0x14 : Data signal of input1
//        bit 31~0 - input1[63:32] (Read/Write)
// 0x18 : reserved
// 0x1c : Data signal of input2
//        bit 31~0 - input2[31:0] (Read/Write)
// 0x20 : Data signal of input2
//        bit 31~0 - input2[63:32] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of output_r
//        bit 31~0 - output_r[31:0] (Read/Write)
// 0x2c : Data signal of output_r
//        bit 31~0 - output_r[63:32] (Read/Write)
// 0x30 : reserved
// 0x34 : Data signal of length_r
//        bit 31~0 - length_r[31:0] (Read/Write)
// 0x38 : reserved
// 0x3c : Data signal of accum
//        bit 31~0 - accum[31:0] (Read/Write)
// 0x40 : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)


