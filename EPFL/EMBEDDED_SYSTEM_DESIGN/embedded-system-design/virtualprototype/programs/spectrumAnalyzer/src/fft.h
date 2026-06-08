#ifndef FFT_H_INCLUDED
#define FFT_H_INCLUDED

#include <stdint.h>
#include "twiddle_lut.h"

#define FFT_LOG2 10

// In-place radix-2 DIT FFT, Q15 fixed-point.
void fft_q15(uint32_t *cplx);

#endif
