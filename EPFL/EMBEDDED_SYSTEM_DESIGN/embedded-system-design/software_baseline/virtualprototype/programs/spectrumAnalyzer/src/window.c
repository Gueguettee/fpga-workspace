#include "window.h"

void apply_hann(int16_t *samples) {
  for (int i = 0; i < HANN_N; i++) {
    samples[i] = (int16_t)(((int32_t)samples[i] * (int32_t)hann_lut[i]) >> 15);
  }
}
