#ifndef TWIDDLE_LUT_H_INCLUDED
#define TWIDDLE_LUT_H_INCLUDED

#include <stdint.h>

#define FFT_N 1024

// Interleaved [re0, im0, re1, im1, ..., re_{N/2-1}, im_{N/2-1}], Q15.
extern const int16_t twiddle_lut[FFT_N];

#endif
