#ifndef CSEQMATCHERDRIVER_HPP
#define CSEQMATCHERDRIVER_HPP

class CSeqMatcherDriver : public CAccelDriver {
  protected:
    // Structure that mimics the layout of the peripheral registers.
    // Vitis HLS skips some addresses in the register file. We introduce
    // padding fields to create the right mapping to registers with our structure,
    struct TRegs {
      uint32_t control; // 0x00
      uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
      uint32_t returnValue; // 0x10
      uint32_t padding0; // 0x14
      uint32_t numDBEntries; // 0x18
      uint32_t padding1; // 0x1C
      uint32_t numSeqsSpecimen; // 0x20
      uint32_t padding2; // 0x24
      uint32_t seqsDB;  // 0x28
      uint32_t padding3; // 0x2C
      uint32_t seqsSpecimen;  // 0x30
      uint32_t padding4; // 0x34
      uint32_t lengthsDB; // 0x38
      uint32_t padding5; // 0x3C
      uint32_t lengthsSpecimen; // 0x40
      uint32_t padding6; // 0x44
      uint32_t scores; // 0x48
      uint32_t padding7; // 0x4C
    };

  public:
    CSeqMatcherDriver(bool Logging = false)
      : CAccelDriver(Logging) {}

    ~CSeqMatcherDriver() {}

    uint32_t SeqMatcher_HW(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
        void * seqsDB, void * seqsSpecimen, void * lengthsDB, void * lengthsSpecimen,
        void * scores, uint32_t & numComparisons);
};

#endif  // CSEQMATCHERDRIVER_HPP

