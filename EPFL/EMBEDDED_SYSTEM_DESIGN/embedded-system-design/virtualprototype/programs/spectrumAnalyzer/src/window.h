#ifndef WINDOW_H_INCLUDED
#define WINDOW_H_INCLUDED

#include <stdint.h>
#include "window_lut.h"

// Packed Q15: high16 = re, low16 = im. Window multiplies re; im is left at 0.
void apply_hann(uint32_t *samples);

#endif
