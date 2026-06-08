#ifndef BARS_H_INCLUDED
#define BARS_H_INCLUDED

#include <stdint.h>

#define FB_WIDTH  640
#define FB_HEIGHT 480
#define BAR_COUNT 32

extern const uint16_t bar_bin_boundary[BAR_COUNT + 1];

void bars_init(void);
void bars_render_from_mag(uint8_t *fb, const uint16_t *mag_bins);

#endif
