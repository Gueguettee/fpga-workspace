#ifndef TWIDDLE_LUT_H_INCLUDED
#define TWIDDLE_LUT_H_INCLUDED

#include <stdint.h>

#define FFT_N 1024

// Packed for the cmulCi CI: each entry is {wr[31:16], wi[15:0]} in Q15.
extern const uint32_t twiddle_lut32[FFT_N / 2];

#endif
