#include "bars.h"
#include "mag.h"
#include <string.h>

#define BAR_PITCH (FB_WIDTH / BAR_COUNT)   // 20 px
#define BAR_GAP   2
#define BAR_W     (BAR_PITCH - BAR_GAP)    // 18 px

#define BG_GRAY    0x00
#define BAR_GRAY   0xC0
#define PEAK_GRAY  0xFF
#define USABLE_H   (FB_HEIGHT - 4)

static uint8_t peak_r[BAR_COUNT];

void bars_init(void) {
  for (int i = 0; i < BAR_COUNT; i++) peak_r[i] = 0;
}

static inline void hline(uint8_t *fb, int x, int y, int w, uint8_t gray) {
  uint8_t *p = fb + (uint32_t)y * FB_WIDTH + x;
  for (int i = 0; i < w; i++) p[i] = gray;
}

static void compute_heights(const uint16_t *mag_bins, uint8_t *out) {
  for (int i = 0; i < BAR_COUNT; i++) {
    uint16_t peak = 0; 
    int lo = bar_bin_boundary[i];
    int hi = bar_bin_boundary[i + 1];
    for (int k = lo; k < hi; k++)
      if (mag_bins[k] > peak) peak = mag_bins[k];
    out[i] = log_compress(peak);
  }
}

void bars_render_from_mag(uint8_t *fb, const uint16_t *mag_bins) {
  uint8_t heights[BAR_COUNT];
  compute_heights(mag_bins, heights);

  // Peak hold: jump up immediately, decay slowly
  for (int i = 0; i < BAR_COUNT; i++) {
    if (heights[i] > peak_r[i]) peak_r[i] = heights[i];
    else if (peak_r[i] > 0) peak_r[i]--;
  }

  // Clear to black
  memset(fb, BG_GRAY, (size_t)FB_WIDTH * FB_HEIGHT);

  // Draw bars from the bottom up; peak is a 2-px white tick above the bar
  for (int i = 0; i < BAR_COUNT; i++) {
    int x0    = i * BAR_PITCH + (BAR_GAP / 2);
    int hpx   = ((int)heights[i] * USABLE_H) / 255;
    int peak  = ((int)peak_r[i]  * USABLE_H) / 255;
    int top   = FB_HEIGHT - hpx - 2;
    int bot   = FB_HEIGHT - 2;
    for (int y = top; y < bot; y++) hline(fb, x0, y, BAR_W, BAR_GRAY);
    int peak_y = FB_HEIGHT - peak - 2;
    if (peak_y >= 0 && peak_y + 1 < FB_HEIGHT) {
      hline(fb, x0, peak_y,     BAR_W, PEAK_GRAY);
      hline(fb, x0, peak_y + 1, BAR_W, PEAK_GRAY);
    }
  }
}
