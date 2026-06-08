#ifndef MAG_H_INCLUDED
#define MAG_H_INCLUDED

#include <stdint.h>

// |re| + |im|  (alpha-max-plus-beta-min with alpha=beta=1; ~7% peak error)
uint16_t mag_approx(int16_t re, int16_t im);

// Compress 0..0xFFFF magnitude to 0..255 with ~16 steps per power of 2.
uint8_t log_compress(uint32_t mag);

#endif
