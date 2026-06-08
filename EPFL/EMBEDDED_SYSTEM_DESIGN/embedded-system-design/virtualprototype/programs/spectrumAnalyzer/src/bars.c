#include "bars.h"
#include "mag.h"
#include <stdint.h>

#define BAR_PITCH (FB_WIDTH / BAR_COUNT)
#define BAR_GAP 2
#define USABLE_H (FB_HEIGHT - 4)

/* SPM at 0xC0000000: zero-stall, used for hot inner-loop data */
static int *const spm_hpx = (int *)0xC0000000u;
static int *const spm_peakpx = (int *)(0xC0000000u + 128u);

/* ramDmaCi (CI 12) opcode constants */
static const uint32_t writeBit = 1u << 9;
static const uint32_t busStartAddress = 1u << 10;
static const uint32_t memoryStartAddress = 2u << 10;
static const uint32_t blockSize = 3u << 10;
static const uint32_t burstSize = 4u << 10;
static const uint32_t statusControl = 5u << 10;
static const uint32_t usedBlocksize = 160u; /* words per FB row (640/4) */
static const uint32_t usedBurstSize = 159u; /* hw adds 1 → 160 words */

static uint8_t peak_r[BAR_COUNT];

void bars_init(void)
{
    for (int i = 0; i < BAR_COUNT; i++)
        peak_r[i] = 0;
}

/* Write one row of pixels into the CI SRAM buffer at ciRamBuffer.
 * Uses same variable names (hpx, peak, top, bot, peak_y) as the baseline. */
static void fill_sram_row(uint32_t ciRamBuffer, int y)
{
    for (int i = 0; i < BAR_COUNT; i++)
    {
        int hpx = spm_hpx[i];
        int peak = spm_peakpx[i];
        int top = FB_HEIGHT - hpx - 2;
        int bot = FB_HEIGHT - 2;
        int peak_y = FB_HEIGHT - peak - 2;
        uint32_t lo, mid, hi;
        if (y == peak_y || y == peak_y + 1)
        {
            lo = 0xFFFFFF00u;
            mid = 0xFFFFFFFFu;
            hi = 0x00FFFFFFu;
        }
        else if (y >= top && y < bot)
        {
            lo = 0xC0C0C000u;
            mid = 0xC0C0C0C0u;
            hi = 0x00C0C0C0u;
        }
        else
        {
            lo = 0u;
            mid = 0u;
            hi = 0u;
        }
        uint32_t addr = ciRamBuffer + (uint32_t)i * 5u;
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"((addr + 0u) | writeBit), [in2] "r"(lo));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"((addr + 1u) | writeBit), [in2] "r"(mid));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"((addr + 2u) | writeBit), [in2] "r"(mid));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"((addr + 3u) | writeBit), [in2] "r"(mid));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"((addr + 4u) | writeBit), [in2] "r"(hi));
    }
}

static void compute_heights(const uint16_t *mag_bins, uint8_t *out)
{
    for (int i = 0; i < BAR_COUNT; i++)
    {
        uint16_t peak = 0;                 // loudest bin in band → a tone shows as one clean bar, not summed noise
        int lo = bar_bin_boundary[i];
        int hi = bar_bin_boundary[i + 1];
        for (int k = lo; k < hi; k++)
            if (mag_bins[k] > peak)
                peak = mag_bins[k];
        out[i] = log_compress(peak);
    }
}

void bars_render_from_mag(uint8_t *fb, const uint16_t *mag_bins)
{
    uint8_t heights[BAR_COUNT];
    compute_heights(mag_bins, heights);

    for (int i = 0; i < BAR_COUNT; i++)
    {
        if (heights[i] > peak_r[i])
            peak_r[i] = heights[i];
        else if (peak_r[i] > 0)
            peak_r[i]--;
    }

    for (int i = 0; i < BAR_COUNT; i++)
    {
        spm_hpx[i] = ((int)heights[i] * USABLE_H) / 255;
        spm_peakpx[i] = ((int)peak_r[i] * USABLE_H) / 255;
    }

    uint32_t dmaBuffer = 0;
    uint32_t workBuffer = 256;
    uint32_t status;
    uint32_t fbPointer = (uint32_t)fb;

    asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(blockSize | writeBit), [in2] "r"(usedBlocksize));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(burstSize | writeBit), [in2] "r"(usedBurstSize));

    /* fill first row and kick off initial DMA */
    fill_sram_row(workBuffer, 0);
    asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(workBuffer));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"(fbPointer));
    asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(statusControl | writeBit), [in2] "r"(2u));
    fbPointer += FB_WIDTH;

    for (int y = 1; y < FB_HEIGHT; y++)
    {
        /* swap buffers */
        status = dmaBuffer;
        dmaBuffer = workBuffer;
        workBuffer = status;

        /* fill workBuffer while DMA runs on dmaBuffer */
        fill_sram_row(workBuffer, y);

        /* wait for DMA to finish */
        do
        {
            asm volatile("l.nios_rrr %[out1],%[in1],r0,0xC" : [out1] "=r"(status) : [in1] "r"(statusControl));
        } while (status & 1u);

        /* DMA out workBuffer to framebuffer */
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(memoryStartAddress | writeBit), [in2] "r"(workBuffer));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(busStartAddress | writeBit), [in2] "r"(fbPointer));
        asm volatile("l.nios_rrr r0,%[in1],%[in2],0xC" ::[in1] "r"(statusControl | writeBit), [in2] "r"(2u));
        fbPointer += FB_WIDTH;
    }

    /* wait for last DMA */
    do
    {
        asm volatile("l.nios_rrr %[out1],%[in1],r0,0xC" : [out1] "=r"(status) : [in1] "r"(statusControl));
    } while (status & 1u);
}
