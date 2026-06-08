#include <stdio.h>
#include <stdint.h>
#include <swap.h>
#include "i2s.h"
#include "window.h"
#include "fft.h"
#include "mag.h"
#include "bars.h"
#include "profile.h"

#define VGA_BASE 0x50000020

// Framebuffer in SDRAM (BSS). 8-bit grayscale matches the camera/grayscale
static uint8_t  fb[FB_WIDTH * FB_HEIGHT] __attribute__((aligned(4)));
static int16_t  samples_re[FFT_N];
static int16_t  samples_im[FFT_N];
static uint16_t mag_bins[FFT_N / 2];

int main(void) {
  volatile uint32_t *vga = (volatile uint32_t *)VGA_BASE;

  // 640x480 grayscale, framebuffer at &fb[0]
  vga[0] = swap_u32(FB_WIDTH);
  vga[1] = swap_u32(FB_HEIGHT);
  vga[2] = swap_u32(2);
  vga[3] = swap_u32((uint32_t)&fb[0]);

  bars_init();
  i2s_init();

  printf("spectrumAnalyzer iter1 - software baseline\r\n");
  printf("Fs ~= 16.1 kHz, 1024-pt FFT, 32 log bars, capture budget = 63.6 ms/frame\r\n");

  // Discard the first ~12 ms of samples while the mic locks onto the WS pattern
  for (int i = 0; i < 200; i++) (void)i2s_read_blocking(0);
  i2s_clear();

  profile_t accCap = {0, 0, 0}, accWin = {0, 0, 0}, accFft = {0, 0, 0};
  profile_t accMag = {0, 0, 0}, accRen = {0, 0, 0};
  uint32_t  overrun_count = 0;
  uint32_t  frame = 0;

  while (1) {
    profile_t pCap, pWin, pFft, pMag, pRen;

    profile_start();
    for (int i = 0; i < FFT_N; i++) {
      samples_re[i] = i2s_read_blocking(0);
    }
    profile_stop(&pCap);

    profile_start();
    apply_hann(samples_re);
    profile_stop(&pWin);

    profile_start();
    for (int i = 0; i < FFT_N; i++) samples_im[i] = 0;
    fft_q15(samples_re, samples_im);
    profile_stop(&pFft);

    profile_start();
    for (int k = 0; k < FFT_N / 2; k++) {
      mag_bins[k] = mag_approx(samples_re[k], samples_im[k]);
    }
    profile_stop(&pMag);

    profile_start();
    bars_render_from_mag(fb, mag_bins);
    profile_stop(&pRen);

    #define PACC(a, p) do { (a).cycles += (p).cycles; (a).stall += (p).stall; (a).bus_idle += (p).bus_idle; } while (0)
    PACC(accCap, pCap);
    PACC(accWin, pWin);
    PACC(accFft, pFft);
    PACC(accMag, pMag);
    PACC(accRen, pRen);
    #undef PACC

    uint32_t status = i2s_status();
    if (status & I2S_STATUS_OVERRUN) {
      overrun_count++;
      i2s_clear();
    }

    frame++;

    // Every 32 frames, print the average per-stage figures
    if ((frame & 0x1Fu) == 0u) {
      profile_t aCap = { accCap.cycles >> 5, accCap.stall >> 5, accCap.bus_idle >> 5 };
      profile_t aWin = { accWin.cycles >> 5, accWin.stall >> 5, accWin.bus_idle >> 5 };
      profile_t aFft = { accFft.cycles >> 5, accFft.stall >> 5, accFft.bus_idle >> 5 };
      profile_t aMag = { accMag.cycles >> 5, accMag.stall >> 5, accMag.bus_idle >> 5 };
      profile_t aRen = { accRen.cycles >> 5, accRen.stall >> 5, accRen.bus_idle >> 5 };

      uint32_t total_cy = aCap.cycles + aWin.cycles + aFft.cycles + aMag.cycles + aRen.cycles;
      uint32_t total_ms = total_cy / 74250u;

      printf("=== avg over 32 frames (frame %d)  TOTAL: %d cy (~%d ms) ===\r\n",
             frame, total_cy, total_ms);
      profile_print_labeled("capture", &aCap);
      profile_print_labeled("hann   ", &aWin);
      profile_print_labeled("fft    ", &aFft);
      profile_print_labeled("mag    ", &aMag);
      profile_print_labeled("render ", &aRen);
      printf("  overruns in window: %d / 32\r\n", overrun_count);

      // Reset accumulators for the next 32-frame window
      accCap.cycles = 0; accCap.stall = 0; accCap.bus_idle = 0;
      accWin.cycles = 0; accWin.stall = 0; accWin.bus_idle = 0;
      accFft.cycles = 0; accFft.stall = 0; accFft.bus_idle = 0;
      accMag.cycles = 0; accMag.stall = 0; accMag.bus_idle = 0;
      accRen.cycles = 0; accRen.stall = 0; accRen.bus_idle = 0;
      overrun_count = 0;
    }
  }
}
