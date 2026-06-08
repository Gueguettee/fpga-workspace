#ifndef I2S_H_INCLUDED
#define I2S_H_INCLUDED

#include <stdint.h>

#define I2S_BASE 0x50000060

#define I2S_STATUS_AVAIL    0x1u
#define I2S_STATUS_OVERRUN  0x2u
#define I2S_STATUS_FILL_SH  2

#define I2S_CTRL_ENABLE     0x1u
#define I2S_CTRL_CLEAR      0x2u
#define I2S_CTRL_IRQ_EN     0x4u
#define I2S_CTRL_ACK_OVR    0x8u

void     i2s_init(void);
void     i2s_clear(void);
void     i2s_ack_overrun(void);
uint32_t i2s_status(void);
int16_t  i2s_read_blocking(uint16_t *counter_out);

#endif
