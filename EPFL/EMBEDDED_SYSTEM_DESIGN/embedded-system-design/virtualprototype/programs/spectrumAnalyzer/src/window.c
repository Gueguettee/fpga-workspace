#include "window.h"

void apply_hann(uint32_t *samples) {
  for (int i = 0; i < HANN_N; i++) {
    int16_t re = (int16_t)(samples[i] >> 16);
    int16_t windowed = (int16_t)(((int32_t)re * (int32_t)hann_lut[i]) >> 15);
    samples[i] = (uint32_t)(uint16_t)windowed << 16;   // im stays 0 pre-FFT
  }
}
