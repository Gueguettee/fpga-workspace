#ifndef CFTTPROXY_HPP
#define CFTTPROXY_HPP

class CFFTProxy : public CAccelProxy {
  protected:
    // Structure that mimics the layout of the peripheral registers.
    // Vitis HLS skips some addresses in the register file. We introduce
    // padding fields to create the right mapping to registers with our structure,
    struct TRegs {
      uint32_t control; // 0x00
      uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
      uint32_t In_real; // 0x10
      uint32_t In_real_h; // 0x14
      uint32_t padding0; // 0x18
      uint32_t In_imag; // 0x1C
      uint32_t In_imag_h; // 0x20
      uint32_t padding1; // 0x24
      uint32_t log2nfft; // 0x28
      uint32_t padding2; // 0x2C
      uint32_t Out_real; // 0x30
      uint32_t Out_real_h; // 0x34
      uint32_t padding3; //0x38
      uint32_t Out_imag; //0x3C
      uint32_t Out_imag_h; // 0x40
      uint32_t padding4; // 0x44
      uint32_t padding5; // 0x48
      uint32_t padding6; // 0x4C
      uint32_t padding7; // 0x50
      uint32_t padding8; // 0x54
      uint32_t padding9; // 0x58
      uint32_t padding10; // 0x5C
      uint32_t padding11; // 0x60
      uint32_t padding12; // 0x64
      uint32_t padding13; // 0x68
    };

  public:
    CFFTProxy(bool Logging = true)
      : CAccelProxy(Logging) {}

    ~CFFTProxy() {}

    uint32_t FFT_HW(void *In_real, void *In_imag, int log2_nfft, void *Out_real, void *Out_imag);
};

#endif  // CFTTPROXY_HPP
