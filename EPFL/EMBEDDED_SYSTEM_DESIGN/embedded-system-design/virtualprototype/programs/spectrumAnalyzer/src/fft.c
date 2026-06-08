#include "fft.h"

void fft_q15(uint32_t *cplx) {
  // Bit-reverse permute
  for (int i = 1, j = 0; i < FFT_N; i++) {
    int bit = FFT_N >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      uint32_t t = cplx[i]; cplx[i] = cplx[j]; cplx[j] = t;
    }
  }

  // Cooley-Tukey radix-2 DIT; butterfly twiddle multiply offloaded to cmulCi (CI 0xD)
  int len = 1;
  for (int stage = 0; stage < FFT_LOG2; stage++) {
    int half   = len;
    len      <<= 1;
    int stride = FFT_N / len;
    for (int k = 0; k < FFT_N; k += len) {
      for (int j = 0; j < half; j++) {
        uint32_t w_s32 = twiddle_lut32[j * stride];
        uint32_t b_s32 = cplx[k + j + half];
        uint32_t t_s32;
        asm volatile ("l.nios_rrr %[o],%[a],%[b],0xD"
                      : [o] "=r" (t_s32)
                      : [a] "r"  (b_s32), [b] "r" (w_s32));
        int16_t tr = (int16_t)(t_s32 >> 16);
        int16_t ti = (int16_t)(t_s32 & 0xFFFFu);

        uint32_t a_s32 = cplx[k + j];
        int16_t ar = (int16_t)(a_s32 >> 16);
        int16_t ai = (int16_t)(a_s32 & 0xFFFFu);

        uint16_t upR = (uint16_t)(int16_t)((ar + tr) >> 1);
        uint16_t upI = (uint16_t)(int16_t)((ai + ti) >> 1);
        uint16_t loR = (uint16_t)(int16_t)((ar - tr) >> 1);
        uint16_t loI = (uint16_t)(int16_t)((ai - ti) >> 1);

        cplx[k + j]        = ((uint32_t)upR << 16) | upI;
        cplx[k + j + half] = ((uint32_t)loR << 16) | loI;
      }
    }
  }
}
