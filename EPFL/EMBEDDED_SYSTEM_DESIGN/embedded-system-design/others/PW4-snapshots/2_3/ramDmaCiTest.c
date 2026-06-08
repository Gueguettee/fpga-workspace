#include <stdio.h>
#include <stdint.h>
#include <vga.h>
#include <swap.h>

#define CI_ID         0xC

#define A_WR          (1u << 9)
#define A_REG_MEM     (0u << 10)
#define A_REG_BASE    (1u << 10)
#define A_REG_MEMADR  (2u << 10)
#define A_REG_BLOCK   (3u << 10)
#define A_REG_BURST   (4u << 10)
#define A_REG_CTL     (5u << 10)

static inline void ci_write(uint32_t a, uint32_t d) {
  asm volatile ("l.nios_rrr r0,%[x],%[y],0xC" :: [x] "r" (a), [y] "r" (d));
}
static inline uint32_t ci_read(uint32_t a) {
  uint32_t v;
  asm volatile ("l.nios_rrr %[o],%[x],r0,0xC" : [o] "=r" (v) : [x] "r" (a));
  return v;
}

static inline void     mem_write(uint32_t addr, uint32_t d) { ci_write(A_REG_MEM | A_WR | (addr & 0x1FF), d); }
static inline uint32_t mem_read (uint32_t addr)             { return ci_read(A_REG_MEM | (addr & 0x1FF)); }

static inline void     dma_set_base (uint32_t v) { ci_write(A_REG_BASE   | A_WR, v); }
static inline void     dma_set_mem  (uint32_t v) { ci_write(A_REG_MEMADR | A_WR, v); }
static inline void     dma_set_block(uint32_t v) { ci_write(A_REG_BLOCK  | A_WR, v); }
static inline void     dma_set_burst(uint32_t v) { ci_write(A_REG_BURST  | A_WR, v); }
static inline void     dma_ctrl     (uint32_t v) { ci_write(A_REG_CTL    | A_WR, v); }
static inline uint32_t dma_base  (void) { return ci_read(A_REG_BASE);   }
static inline uint32_t dma_mem   (void) { return ci_read(A_REG_MEMADR); }
static inline uint32_t dma_block (void) { return ci_read(A_REG_BLOCK);  }
static inline uint32_t dma_burst (void) { return ci_read(A_REG_BURST);  }
static inline uint32_t dma_status(void) { return ci_read(A_REG_CTL);    }

static uint32_t fails;

static int wait_dma_done(const char *label) {
  uint32_t spin = 0;
  while (dma_status() & 1u) {
    if (++spin > 2000000u) {
      printf("  FAIL %s: timeout waiting for DMA, status=0x%08X\n", label, dma_status());
      fails++;
      return 0;
    }
  }
  return 1;
}

static uint32_t check_buffer(uint32_t mem_offset, uint32_t count, uint32_t pattern_base) {
  uint32_t errs = 0;
  for (uint32_t i = 0; i < count; i++) {
    uint32_t got = mem_read(mem_offset + i);
    uint32_t exp = pattern_base | i;
    if (got != exp) {
      if (!errs) printf("  first mismatch @%u got 0x%08X exp 0x%08X\n", mem_offset + i, got, exp);
      errs++;
    }
  }
  return errs;
}

static void test_pattern_sweep(void) {
  printf("[1] sec.2.2 pattern sweep (512 words)\n");
  for (uint32_t i = 0; i < 512; i++) mem_write(i, i ^ 0xA5A5A5A5u);
  uint32_t errs = 0, badA = 0, badG = 0, badE = 0;
  for (uint32_t i = 0; i < 512; i++) {
    uint32_t e = i ^ 0xA5A5A5A5u;
    uint32_t g = mem_read(i);
    if (g != e) { if (!errs) { badA=i; badG=g; badE=e; } errs++; }
  }
  if (errs) { printf("  FAIL %u mismatches, first @%u got 0x%08X exp 0x%08X\n", errs, badA, badG, badE); fails++; }
  else      { printf("  OK\n"); }
}

static void test_config_roundtrip(void) {
  printf("[2] config register round-trip and width masks\n");
  dma_set_base(0xDEADBEEFu);
  if (dma_base() != 0xDEADBEEFu) { printf("  FAIL base r/w: got 0x%08X\n", dma_base()); fails++; }

  dma_set_mem(0xFFFFFFFFu);
  if (dma_mem() != 0x1FFu) { printf("  FAIL memStart mask: got 0x%08X exp 0x1FF\n", dma_mem()); fails++; }

  dma_set_block(0xFFFFFFFFu);
  if (dma_block() != 0x3FFu) { printf("  FAIL blockSize mask: got 0x%08X exp 0x3FF\n", dma_block()); fails++; }

  dma_set_burst(0xFFFFFFFFu);
  if (dma_burst() != 0xFFu) { printf("  FAIL burstSize mask: got 0x%08X exp 0xFF\n", dma_burst()); fails++; }

  printf("  done\n");
}

static void test_status_idle(void) {
  printf("[3] status register idle at reset\n");
  uint32_t s = dma_status();
  if (s != 0) { printf("  FAIL status=0x%08X exp 0\n", s); fails++; }
  else        { printf("  OK\n"); }
}

static void test_illegal_ctrl_3(void) {
  printf("[4] control=3 must NOT start the DMA\n");
  dma_set_block(16);
  dma_ctrl(3);
  uint32_t s = dma_status();
  if (s & 1u) { printf("  FAIL status.active set: 0x%08X\n", s); fails++; }
  else        { printf("  OK (status=0x%08X)\n", s); }
}

static void test_invalid_upper_bits(void) {
  printf("[5] valueA[31:13] != 0 must be a no-op\n");
  mem_write(5, 0xC0FFEE05u);
  uint32_t before = mem_read(5);
  uint32_t aInvalid = (1u << 13) | A_WR | 5u;
  ci_write(aInvalid, 0xDEAD0000u);
  uint32_t after = mem_read(5);
  if (after != before) { printf("  FAIL mem[5] changed: before=0x%08X after=0x%08X\n", before, after); fails++; }
  else                 { printf("  OK (mem[5]=0x%08X unchanged)\n", after); }
}

static volatile uint32_t src_buf[256];

static void test_dma_single_burst(void) {
  printf("[6] DMA: blockSize=64, burstSize=255 (one burst of 64 words)\n");
  for (uint32_t i = 0; i < 64; i++) src_buf[i] = swap_u32(0xC0DE0000u | i);
  for (uint32_t i = 0; i < 64; i++) mem_write(i, 0xBAD00000u | i);

  dma_set_base((uint32_t)&src_buf[0]);
  dma_set_mem(0);
  dma_set_block(64);
  dma_set_burst(255);
  dma_ctrl(1);

  if (!wait_dma_done("single-burst")) return;
  uint32_t s = dma_status();
  if (s & 2u) { printf("  FAIL bus error: status=0x%08X\n", s); fails++; return; }

  uint32_t errs = check_buffer(0, 64, 0xC0DE0000u);
  if (errs) { printf("  FAIL %u mismatches\n", errs); fails++; }
  else      { printf("  OK\n"); }
}

static void test_dma_multi_burst(void) {
  printf("[7] DMA: blockSize=16, burstSize=3 (4 bursts of 4 words)\n");
  for (uint32_t i = 0; i < 16; i++) src_buf[i] = swap_u32(0x1EAF0000u | i);
  for (uint32_t i = 0; i < 16; i++) mem_write(100 + i, 0xDEAD0000u | i);

  dma_set_base((uint32_t)&src_buf[0]);
  dma_set_mem(100);
  dma_set_block(16);
  dma_set_burst(3);
  dma_ctrl(1);

  if (!wait_dma_done("multi-burst")) return;
  uint32_t s = dma_status();
  if (s & 2u) { printf("  FAIL bus error: status=0x%08X\n", s); fails++; return; }

  uint32_t errs = check_buffer(100, 16, 0x1EAF0000u);
  if (errs) { printf("  FAIL %u mismatches\n", errs); fails++; }
  else      { printf("  OK\n"); }
}

static void test_dma_partial_last_burst(void) {
  printf("[8] DMA: blockSize=10, burstSize=3 (2 full bursts + 1 partial of 2)\n");
  for (uint32_t i = 0; i < 10; i++) src_buf[i] = swap_u32(0x2ACE0000u | i);
  for (uint32_t i = 0; i < 10; i++) mem_write(200 + i, 0xBEEF0000u | i);

  dma_set_base((uint32_t)&src_buf[0]);
  dma_set_mem(200);
  dma_set_block(10);
  dma_set_burst(3);
  dma_ctrl(1);

  if (!wait_dma_done("partial-last")) return;
  uint32_t s = dma_status();
  if (s & 2u) { printf("  FAIL bus error: status=0x%08X\n", s); fails++; return; }

  uint32_t errs = check_buffer(200, 10, 0x2ACE0000u);
  if (errs) { printf("  FAIL %u mismatches\n", errs); fails++; }
  else      { printf("  OK\n"); }
}

int main (void) {
  vga_clear();
  printf("ramDmaCi test (CI id=0x%X)\n", CI_ID);
  fails = 0;

  test_pattern_sweep();
  test_config_roundtrip();
  test_status_idle();
  test_illegal_ctrl_3();
  test_invalid_upper_bits();
  test_dma_single_burst();
  test_dma_multi_burst();
  test_dma_partial_last_burst();

  if (fails == 0) printf("\nALL TESTS PASSED\n");
  else            printf("\n%u TEST(S) FAILED\n", fails);
  return 0;
}
