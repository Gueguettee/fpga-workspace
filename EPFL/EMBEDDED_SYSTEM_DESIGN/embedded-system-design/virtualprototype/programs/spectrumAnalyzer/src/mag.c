#include "mag.h"

uint16_t mag_approx_packed(uint32_t cplx) {
  int16_t re = (int16_t)(cplx >> 16);
  int16_t im = (int16_t)(cplx & 0xFFFFu);
  int32_t a = re < 0 ? -(int32_t)re : (int32_t)re;
  int32_t b = im < 0 ? -(int32_t)im : (int32_t)im;
  int32_t s = a + b;
  return s > 0xFFFF ? (uint16_t)0xFFFFu : (uint16_t)s;
}

uint8_t log_compress(uint32_t mag) {
  if (mag == 0) return 0;
  if (mag > 0xFFFFu) mag = 0xFFFFu;
  int msb = 0;
  uint32_t v = mag;
  while (v > 1u) { v >>= 1; msb++; }
  uint32_t shifted = (msb >= 4) ? (mag >> (msb - 4)) : (mag << (4 - msb));
  uint32_t frac = shifted & 0xFu;
  return (uint8_t)((msb << 4) | frac);
}
