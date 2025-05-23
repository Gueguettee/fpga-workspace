#ifndef CCONV2D_HPP
#define CCONV2D_HPP
#include "CAccelDriver.hpp"

class CConv2DDriver : public CAccelDriver {
  protected:
    // Structure that mimics the layout of the peripheral registers.
    // Vitis HLS skips some addresses in the register file. We introduce
    // padding fields to create the right mapping to registers with our structure,
    struct TRegs {
      uint32_t control; // 0x00
      uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
      uint32_t input; // 0x10
      uint32_t input_h; // 0x14
      uint32_t padding0; // 0x18
      uint32_t output; // 0x1C
      uint32_t output_h; // 0x20
      uint32_t padding1; // 0x24
      uint32_t coeffs; // 0x28
      uint32_t coeffs_h; // 0x2C
      uint32_t padding2; // 0x30
      uint32_t numChannels; // 0x34
      uint32_t padding3; // 0x38
      uint32_t numFilters; // 0x3C
      uint32_t padding4; // 0x40
      uint32_t inputWidth; // 0x44
      uint32_t padding5; // 0x48
      uint32_t inputHeight; // 0x4C
      uint32_t padding6; // 0x50
      uint32_t convWidth; // 0x54
      uint32_t padding7; // 0x58
      uint32_t convHeight; // 0x5C
    };

  public:
    CConv2DDriver(bool Logging = true)
      : CAccelDriver(Logging) {}

    ~CConv2DDriver() {}

    uint32_t Conv2D_HW(void *input, void * output, void * coeffs,
      uint32_t numFilters, uint32_t numChannels,
      uint32_t inputWidth, uint32_t inputHeight,
      uint32_t convWidth, uint32_t convHeight);
};

#endif  // CCONV2D_HPP

