#ifndef CSMPLEADDERDRIVER_HPP
#define CSMPLEADDERDRIVER_HPP

class CSimpleAdderDriver : public CAccelDriver {
  protected:
    // Structure that mimics the layout of the peripheral registers.
    // Vitis HLS skips some addresses in the register file. We introduce
    // padding fields to create the right mapping to registers with our structure,
    struct TRegs {
      uint32_t _padding0[4]; // Regs 0-3
      uint32_t REG_A; // 0x04
      uint32_t _padding2;
      uint32_t REG_B; // 0x06
      uint32_t _padding3;
      uint32_t REG_RESULT; // 0x08
      uint32_t _padding4;
      uint32_t res_reg_ctrl;
    };

  public:
    CSimpleAdderDriver(bool Logging = false)
      : CAccelDriver(Logging) {}

    ~CSimpleAdderDriver() {}

    uint32_t Add(uint32_t A, uint32_t B, uint32_t & Result);
};


#endif  // CSMPLEADDERDRIVER_HPP

