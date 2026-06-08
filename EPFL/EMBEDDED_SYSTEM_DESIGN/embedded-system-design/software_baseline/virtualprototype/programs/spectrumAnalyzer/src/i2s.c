#include "i2s.h"
#include <swap.h>

// 32-bit MMIO uses swap_u32 because the bus is byte-reversed vs. the BE CPU
static volatile uint32_t * const I2S = (volatile uint32_t *) I2S_BASE;

#define R_STATUS  0
#define R_SAMPLE  1
#define R_CTRL    2

static inline void i2s_write(uint32_t reg, uint32_t v) { I2S[reg] = swap_u32(v); }
static inline uint32_t i2s_read(uint32_t reg)          { return swap_u32(I2S[reg]); }

void i2s_init(void) {
  // single-cycle clear pulse, then steady-state enable
  i2s_write(R_CTRL, I2S_CTRL_ENABLE | I2S_CTRL_CLEAR);
  i2s_write(R_CTRL, I2S_CTRL_ENABLE);
}

void i2s_clear(void) {
  i2s_write(R_CTRL, I2S_CTRL_ENABLE | I2S_CTRL_CLEAR);
  i2s_write(R_CTRL, I2S_CTRL_ENABLE);
}

uint32_t i2s_status(void) { return i2s_read(R_STATUS); }

int16_t i2s_read_blocking(uint16_t *counter_out) {
  while ((i2s_read(R_STATUS) & I2S_STATUS_AVAIL) == 0u) { /* spin */ }
  uint32_t w = i2s_read(R_SAMPLE);
  if (counter_out) *counter_out = (uint16_t)(w >> 16);
  return (int16_t)(w & 0xFFFFu);
}
