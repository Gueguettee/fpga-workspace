#ifndef CDENSESOLVE_HPP
#define CDENSESOLVE_HPP

class CDenseSolveProxy : public CAccelProxy {
  protected:
    struct TRegs {
      uint32_t control; // 0x00
      uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
      uint32_t input_l; // 0x10
      uint32_t input_r; // 0x14
      uint32_t padding0; // 0x18
      uint32_t output_l; // 0x1C
      uint32_t output_r; // 0x20
      uint32_t padding1; // 0x24
      uint32_t inputWidth; // 0x28
      uint32_t padding2; // 0x2C
      uint32_t inputHeight; // 0x30
    };

  public:
    CDenseSolveProxy(bool Logging = false)
      : CAccelProxy(Logging) {}

    ~CDenseSolveProxy() {}

    uint32_t DenseSolve_HW(void *input, void *output,
      uint32_t inputWidth, uint32_t inputHeight);
};

#endif  // CDENSESOLVE_HPP
