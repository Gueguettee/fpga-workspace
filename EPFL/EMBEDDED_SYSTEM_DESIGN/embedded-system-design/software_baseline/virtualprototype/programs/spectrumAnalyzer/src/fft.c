#include "fft.h"

static inline int16_t q15_mul(int16_t a, int16_t b) {
  return (int16_t)(((int32_t)a * (int32_t)b) >> 15);
}

void fft_q15(int16_t *re, int16_t *im) {
  // Bit-reverse permute
  for (int i = 1, j = 0; i < FFT_N; i++) {
    int bit = FFT_N >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      int16_t tr = re[i]; re[i] = re[j]; re[j] = tr;
      int16_t ti = im[i]; im[i] = im[j]; im[j] = ti;
    }
  }

  // Cooley-Tukey radix-2 DIT
  int len = 1;
  for (int stage = 0; stage < FFT_LOG2; stage++) {
    int half   = len;
    len      <<= 1;
    int stride = FFT_N / len;
    for (int k = 0; k < FFT_N; k += len) {
      for (int j = 0; j < half; j++) {
        int idx = (j * stride) << 1; 
        int16_t wr = twiddle_lut[idx];
        int16_t wi = twiddle_lut[idx + 1];
        int16_t br = re[k + j + half];
        int16_t bi = im[k + j + half];
        int16_t tr = q15_mul(wr, br) - q15_mul(wi, bi);
        int16_t ti = q15_mul(wr, bi) + q15_mul(wi, br);
        int16_t ar = re[k + j];
        int16_t ai = im[k + j];
        re[k + j]        = (int16_t)((ar + tr) >> 1);
        im[k + j]        = (int16_t)((ai + ti) >> 1);
        re[k + j + half] = (int16_t)((ar - tr) >> 1);
        im[k + j + half] = (int16_t)((ai - ti) >> 1);
      }
    }
  }
}
