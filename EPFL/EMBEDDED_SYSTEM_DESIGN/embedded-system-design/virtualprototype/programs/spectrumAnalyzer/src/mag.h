#ifndef MAG_H_INCLUDED
#define MAG_H_INCLUDED

#include <stdint.h>

// |re| + |im| from a packed Q15 complex value (high16 = re, low16 = im).
uint16_t mag_approx_packed(uint32_t cplx);

// Compress 0..0xFFFF magnitude to 0..255 with ~16 steps per power of 2.
uint8_t log_compress(uint32_t mag);

#endif
