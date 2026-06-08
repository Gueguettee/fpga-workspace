#include <stdio.h>
#include <stdint.h>
#include <vga.h>

#define RAM_CI_ID 0xC
#define RAM_WRITE_BIT (1u << 9)

static inline void ram_write(uint32_t addr, uint32_t data) {
  uint32_t a = (addr & 0x1FF) | RAM_WRITE_BIT;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xC"
                :: [in1] "r" (a), [in2] "r" (data));
}

static inline uint32_t ram_read(uint32_t addr) {
  uint32_t a = addr & 0x1FF;
  uint32_t v;
  asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xC"
                : [out1] "=r" (v) : [in1] "r" (a));
  return v;
}

int main (void) {
  vga_clear();
  printf("ramDmaCi test (CI id=0x%X)\n", RAM_CI_ID);

  for (uint32_t i = 0; i < 512; i++) {
    ram_write(i, i ^ 0xA5A5A5A5);
  }

  uint32_t errors = 0;
  uint32_t firstBadAddr = 0, firstBadGot = 0, firstBadExp = 0;
  for (uint32_t i = 0; i < 512; i++) {
    uint32_t expected = i ^ 0xA5A5A5A5;
    uint32_t got = ram_read(i);
    if (got != expected) {
      if (errors == 0) { firstBadAddr = i; firstBadGot = got; firstBadExp = expected; }
      errors++;
    }
  }

  if (errors == 0) {
    printf("Pattern sweep: OK (512 words)\n");
  } else {
    printf("Pattern sweep: FAIL (%u mismatches), first @%u got 0x%08X exp 0x%08X\n",
           errors, firstBadAddr, firstBadGot, firstBadExp);
  }

  ram_write(0,   0xDEADBEEF);
  ram_write(511, 0xCAFEBABE);
  uint32_t r0   = ram_read(0);
  uint32_t r511 = ram_read(511);
  printf("Edge: [0]=0x%08X %s, [511]=0x%08X %s\n",
         r0,   (r0   == 0xDEADBEEF) ? "OK" : "FAIL",
         r511, (r511 == 0xCAFEBABE) ? "OK" : "FAIL");

  uint32_t aInvalid = (1u << 10) | (1u << 9) | 5;
  uint32_t d = 0x12345678;
  asm volatile ("l.nios_rrr r0,%[in1],%[in2],0xC"
                :: [in1] "r" (aInvalid), [in2] "r" (d));
  uint32_t r5 = ram_read(5);
  printf("Invalid-upper-bits probe: [5]=0x%08X %s (must keep 0x%08X)\n",
         r5, (r5 == (5u ^ 0xA5A5A5A5u)) ? "OK" : "FAIL", 5u ^ 0xA5A5A5A5u);

  printf("Done.\n");
  return 0;
}
