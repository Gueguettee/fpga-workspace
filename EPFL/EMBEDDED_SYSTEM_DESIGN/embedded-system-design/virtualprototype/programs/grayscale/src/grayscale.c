#include <stdio.h>
#include <ov7670.h>
#include <swap.h>
#include <vga.h>


int main () {
  volatile uint16_t rgb565[640*480];
  volatile uint8_t grayscale[640*480];
  volatile uint32_t result, cycles,stall,idle;
  volatile unsigned int *vga = (unsigned int *) 0X50000020;
  camParameters camParams;
  vga_clear();

  printf("Initialising camera (this takes up to 3 seconds)!\n" );
  camParams = initOv7670(VGA);
  printf("Done!\n" );
  printf("NrOfPixels : %d\n", camParams.nrOfPixelsPerLine );
  result = (camParams.nrOfPixelsPerLine <= 320) ? camParams.nrOfPixelsPerLine | 0x80000000 : camParams.nrOfPixelsPerLine;
  vga[0] = swap_u32(result);
  printf("NrOfLines  : %d\n", camParams.nrOfLinesPerImage );
  result =  (camParams.nrOfLinesPerImage <= 240) ? camParams.nrOfLinesPerImage | 0x80000000 : camParams.nrOfLinesPerImage;
  vga[1] = swap_u32(result);
  printf("PCLK (kHz) : %d\n", camParams.pixelClockInkHz );
  printf("FPS        : %d\n", camParams.framesPerSecond );
  uint32_t * rgb = (uint32_t *) &rgb565[0];
  vga[2] = swap_u32(2);
  vga[3] = swap_u32((uint32_t) &grayscale[0]);
  while(1) {
    uint32_t * gray = (uint32_t *) &grayscale[0];
    takeSingleImageBlocking((uint32_t) &rgb565[0]);

    // Reset all counters and enable them
    uint32_t control = 0x707;
    asm volatile ("l.nios_rrr r0,r0,%[in2],0xB" :: [in2] "r" (control));

    uint32_t grayPixels;
    int totalPairs = (camParams.nrOfLinesPerImage * camParams.nrOfPixelsPerLine) >> 1;
    for (int p = 0; p < totalPairs; p += 2) {
      uint32_t pixel1 = rgb[p];
      uint32_t pixel2 = rgb[p + 1];
      asm volatile ("l.nios_rrr %[out1],%[in1],%[in2],0x8"
                    : [out1] "=r" (grayPixels)
                    : [in1]  "r" (pixel1),
                      [in2]  "r" (pixel2));
      *gray++ = grayPixels;
    }

    // Disable counters
    control = 0x70;
    asm volatile ("l.nios_rrr r0,r0,%[in2],0xB" :: [in2] "r" (control));

    // Read counter0
    uint32_t counterid = 0;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (cycles) : [in1] "r" (counterid));

    // Read counter1
    counterid = 1;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (stall) : [in1] "r" (counterid));

    // Read counter2
    counterid = 2;
    asm volatile ("l.nios_rrr %[out1],%[in1],r0,0xB" : [out1] "=r" (idle) : [in1] "r" (counterid));

    printf("Execution cycles: %d\r\n", cycles);
    printf("Stall cycles    : %d\r\n", stall);
    printf("Bus-idle cycles : %d\r\n", idle);
  }
}
