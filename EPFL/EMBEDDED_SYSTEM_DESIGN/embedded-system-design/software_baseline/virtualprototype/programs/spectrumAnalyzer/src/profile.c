#include "profile.h"
#include <stdio.h>

void profile_start(void) {
  // 0x707 = reset + enable counters 0/1/2 (cycles, stalls, bus-idle)
  uint32_t ctl = 0x707u;
  asm volatile ("l.nios_rrr r0,r0,%[in],0xB" :: [in] "r" (ctl));
}

void profile_stop(profile_t *out) {
  uint32_t ctl = 0x70u;       // disable
  asm volatile ("l.nios_rrr r0,r0,%[in],0xB" :: [in] "r" (ctl));
  uint32_t id;
  id = 0; asm volatile ("l.nios_rrr %[o],%[i],r0,0xB" : [o] "=r" (out->cycles)   : [i] "r" (id));
  id = 1; asm volatile ("l.nios_rrr %[o],%[i],r0,0xB" : [o] "=r" (out->stall)    : [i] "r" (id));
  id = 2; asm volatile ("l.nios_rrr %[o],%[i],r0,0xB" : [o] "=r" (out->bus_idle) : [i] "r" (id));
}

void profile_print(const profile_t *p) {
  printf("Execution cycles: %d\r\n", p->cycles);
  printf("Stall cycles    : %d\r\n", p->stall);
  printf("Bus-idle cycles : %d\r\n", p->bus_idle);
}

void profile_print_labeled(const char *label, const profile_t *p) {
  // 7,425 system cycles = 0.1 ms at 74.25 MHz (one-decimal ms = cycles / 7425)
  uint32_t cy_x10 = p->cycles   / 7425u;
  uint32_t st_x10 = p->stall    / 7425u;
  uint32_t bi_x10 = p->bus_idle / 7425u;
  uint32_t pct_st = (p->cycles > 0u) ? ((p->stall    * 100u) / p->cycles) : 0u;
  uint32_t pct_bi = (p->cycles > 0u) ? ((p->bus_idle * 100u) / p->cycles) : 0u;

  // Format: "  label:  61.5 ms | stall  36.9 ms (60%) | idle   9.2 ms (15%)"
  printf("  %s: %4d.%d ms | stall %4d.%d ms (%2d%%) | idle %4d.%d ms (%2d%%)\r\n",
         label,
         cy_x10 / 10u, cy_x10 % 10u,
         st_x10 / 10u, st_x10 % 10u, pct_st,
         bi_x10 / 10u, bi_x10 % 10u, pct_bi);
}
