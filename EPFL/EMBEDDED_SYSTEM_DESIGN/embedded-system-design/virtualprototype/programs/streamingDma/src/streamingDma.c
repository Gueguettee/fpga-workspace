#include <stdio.h>
#include <stdint.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>

// CI 0xC: ramDmaCi register encoding
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
static inline uint32_t dma_status   (void)       { return ci_read(A_REG_CTL); }

static inline int wait_dma(const char *tag) {
  uint32_t spin = 0;
  while (dma_status() & 1u) {
    if (++spin > 5000000u) { printf("DMA timeout @%s status=0x%X\r\n", tag, dma_status()); return 0; }
  }
  if (dma_status() & 2u) { printf("DMA bus err @%s status=0x%X\r\n", tag, dma_status()); return 0; }
  return 1;
}

// Pipeline geometry
#define PIX_PER_BUF         512
#define RGB_WORDS_PER_BUF   256   // 2 RGB565 px / 32-bit word
#define GRAY_WORDS_PER_BUF  128   // 4 gray bytes / 32-bit word
#define NUM_BUFFERS         600   // 640*480 / 512
#define BUF_A_OFF           0
#define BUF_B_OFF           256
#define BURST               255   // burst+1 = 256 words → full half-buffer in one burst

static void streaming_pipeline(uint32_t rgb_addr, uint32_t gray_addr) {
  dma_set_burst(BURST);

  // Step 1: prime buffer A with first 512 RGB pixels
  dma_set_base(rgb_addr);
  dma_set_mem(BUF_A_OFF);
  dma_set_block(RGB_WORDS_PER_BUF);
  dma_ctrl(1);
  if (!wait_dma("prime")) return;

  // Step 2: 599 overlap iterations
  for (int it = 0; it < NUM_BUFFERS - 1; it++) {
    uint32_t cur_off  = (it & 1) ? BUF_B_OFF : BUF_A_OFF;
    uint32_t next_off = (it & 1) ? BUF_A_OFF : BUF_B_OFF;

    // (a) Kick DMA-in for next batch — overlaps with compute below
    dma_set_base(rgb_addr + (uint32_t)(it + 1) * (RGB_WORDS_PER_BUF * 4));
    dma_set_mem(next_off);
    dma_set_block(RGB_WORDS_PER_BUF);
    dma_ctrl(1);

    // (b) Convert in place: read 2k,2k+1 (RGB) → write k (gray); k <= 2k so safe
    for (uint32_t k = 0; k < GRAY_WORDS_PER_BUF; k++) {
      uint32_t p1 = swap_u32(mem_read(cur_off + 2*k));
      uint32_t p2 = swap_u32(mem_read(cur_off + 2*k + 1));
      uint32_t g;
      asm volatile ("l.nios_rrr %[o],%[a],%[b],0x8"
                    : [o] "=r" (g) : [a] "r" (p1), [b] "r" (p2));
      mem_write(cur_off + k, swap_u32(g));
    }

    if (!wait_dma("in")) return;

    // (c) DMA-out: 128 gray words → grayscale screen buffer
    dma_set_base(gray_addr + (uint32_t)it * (GRAY_WORDS_PER_BUF * 4));
    dma_set_mem(cur_off);
    dma_set_block(GRAY_WORDS_PER_BUF);
    dma_ctrl(2);
    if (!wait_dma("out")) return;
  }

  // Step 3: final flush — last batch already loaded by previous DMA-in
  uint32_t last_off = ((NUM_BUFFERS - 1) & 1) ? BUF_B_OFF : BUF_A_OFF;
  for (uint32_t k = 0; k < GRAY_WORDS_PER_BUF; k++) {
    uint32_t p1 = swap_u32(mem_read(last_off + 2*k));
    uint32_t p2 = swap_u32(mem_read(last_off + 2*k + 1));
    uint32_t g;
    asm volatile ("l.nios_rrr %[o],%[a],%[b],0x8"
                  : [o] "=r" (g) : [a] "r" (p1), [b] "r" (p2));
    mem_write(last_off + k, swap_u32(g));
  }
  dma_set_base(gray_addr + (uint32_t)(NUM_BUFFERS - 1) * (GRAY_WORDS_PER_BUF * 4));
  dma_set_mem(last_off);
  dma_set_block(GRAY_WORDS_PER_BUF);
  dma_ctrl(2);
  if (!wait_dma("flush")) return;
}

// File-scope arrays land in BSS (not on the stack). Removes any risk that a
// 921 KB stack frame interacts badly with the prologue or with printf's stack use.
static volatile uint16_t rgb565[640*480]    __attribute__((aligned(4)));
static volatile uint8_t  grayscale[640*480] __attribute__((aligned(4)));

int main(void) {
  volatile uint32_t cycles, stall, idle, result;
  volatile unsigned int *vga = (unsigned int *) 0X50000020;
  camParameters camParams;

  vga_clear();

  printf("Initialising camera (this takes up to 3 seconds)!\n");
  camParams = initOv7670(VGA);
  printf("Done!\n");
  printf("NrOfPixels : %d\n", camParams.nrOfPixelsPerLine);
  result = (camParams.nrOfPixelsPerLine <= 320) ? camParams.nrOfPixelsPerLine | 0x80000000 : camParams.nrOfPixelsPerLine;
  vga[0] = swap_u32(result);
  printf("NrOfLines  : %d\n", camParams.nrOfLinesPerImage);
  result = (camParams.nrOfLinesPerImage <= 240) ? camParams.nrOfLinesPerImage | 0x80000000 : camParams.nrOfLinesPerImage;
  vga[1] = swap_u32(result);
  printf("PCLK (kHz) : %d\n", camParams.pixelClockInkHz);
  printf("FPS        : %d\n", camParams.framesPerSecond);

  vga[2] = swap_u32(2);                                // 8-bit grayscale screen mode
  vga[3] = swap_u32((uint32_t) &grayscale[0]);         // grayscale frame buffer base

  while (1) {
    takeSingleImageBlocking((uint32_t) &rgb565[0]);

    // Reset + enable counters 0,1,2
    uint32_t control = 0x707;
    asm volatile ("l.nios_rrr r0,r0,%[in2],0xB" :: [in2] "r" (control));

    streaming_pipeline((uint32_t) &rgb565[0], (uint32_t) &grayscale[0]);

    // Disable counters
    control = 0x70;
    asm volatile ("l.nios_rrr r0,r0,%[in2],0xB" :: [in2] "r" (control));

    uint32_t counterid = 0;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (cycles) : [in1] "r" (counterid));
    counterid = 1;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (stall)  : [in1] "r" (counterid));
    counterid = 2;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (idle)   : [in1] "r" (counterid));

    printf("Execution cycles: %d\r\n", cycles);
    printf("Stall cycles    : %d\r\n", stall);
    printf("Bus-idle cycles : %d\r\n", idle);
  }
}
