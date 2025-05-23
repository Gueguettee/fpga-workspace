#ifndef CFTTPROXY_KERNEL_HPP
#define CFTTPROXY_KERNEL_HPP

class CFFTProxy : public CAccelDriver {
  protected:
    // Structure used to pass commands between user-space and kernel-space.
    struct user_message {
      uint32_t phyIn_real;
      uint32_t phyIn_imag;
      uint32_t log2_nfft;
      uint32_t phyOut_real;
      uint32_t phyOut_imag;
      uint32_t workers;
    };

  public:
    CFFTProxy(bool Logging = true)
      : CAccelDriver(Logging) {}

    ~CFFTProxy() {}

    uint32_t FFT_HW(void *In_real, void *In_imag, int log2_nfft, void *Out_real, void *Out_imag, uint32_t addr_offset = 0, int workers = 1);
};

#endif  // CFTTPROXY_KERNEL_HPP
