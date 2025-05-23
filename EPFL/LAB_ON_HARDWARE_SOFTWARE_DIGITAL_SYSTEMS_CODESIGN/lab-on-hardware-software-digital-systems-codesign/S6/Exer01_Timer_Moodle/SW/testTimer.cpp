#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
extern "C" {
#include <libxlnk_cma.h>  // Required for memory-mapping functions from Xilinx
}

// Base address for the mapping of (all) peripherals
#define BASE_MAP  0x43C00000

// Adjust the size of the mapping to cover all the peripherals, or use multiple mappings.
const uint32_t MAP_SIZE = 64*1024;

enum {REG_COUNTER = 0, REG_ENABLE = 1, REG_ENABLE_INTERRUPT = 2, CLEAR_INTERRUPT = 3};

int main(int argc, char ** argv)
{
  volatile uint8_t * device = NULL;
  volatile uint32_t * regCounter;
  volatile uint32_t * regEnable;
  volatile uint32_t * regEnableInterrupt;
  volatile uint32_t * regClearInterrupt;

  printf("\n\nThis program requires that the TimerInterrupt bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

  // Obtain a pointer to access the peripherals in the address map.
	device = (uint8_t*)cma_mmap(BASE_MAP, MAP_SIZE);
	if (device == NULL) {
		printf("Error opening device!\n");
    exit(-1);
	}
  printf("Mmap done. Peripherals at %08X\n", (uint32_t)device);

  regCounter = (uint32_t*)(device) + REG_COUNTER;
  regEnable = (uint32_t*)(device) + REG_ENABLE;
  regEnableInterrupt = (uint32_t*)(device) + REG_ENABLE_INTERRUPT;
  regClearInterrupt = (uint32_t*)(device) + CLEAR_INTERRUPT;
  printf("Counter at: %08X - Enable at: %08X - EnableInterrupt at: %08X - ClearInterrupt at %08X\n", 
    (uint32_t)regCounter, (uint32_t)regEnable, (uint32_t)regEnableInterrupt, (uint32_t)regClearInterrupt);

  // Init device.
  *regEnableInterrupt = 0;
  *regEnable = 1;
  printf("Timer started!\n\n");

  uint32_t seconds = 0;
  uint32_t lastCounter = 0, newCounter = 0;
  while (1) {
    newCounter = *regCounter;
    if ( (lastCounter > 0) && (newCounter == 0) ) {
    //if ( (lastCounter > 100) && (newCounter < 100) ) {
      ++ seconds;
      printf("Elapsed %u seconds.\n", seconds);
    }

    lastCounter = newCounter;
  }

  //////////////////////////////////////////////  

	cma_munmap((void*)device, MAP_SIZE);

	return 0;
}

