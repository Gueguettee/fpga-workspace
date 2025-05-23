#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <map>
#include "CAccelDriver.hpp"

#define TESTBIT(x, y) (((x) & (y)) ? 1 : 0)

// Address constants
const uint32_t GPIO_ADDRESS = 0x41200000; // From Vivado's address editor
const uint32_t MAP_SIZE = 64*1024; // Size of address range mapped to the GPIO

// Structure that mimics the layout of the peripheral registers.
// Xilinx's GPIO peripheral has two channels, each with a tri-state register and a data register.
// '0' configures the tri-state as output. '1' configures the tri-state as input.
struct TRegs {
  uint32_t LEDS_REG; // 0x00
  uint32_t LEDS_TRISTATE; // 0x04
  uint32_t BTNS_REG; // 0x08
  uint32_t BTNS_TRISTATE; // 0x0C
  };



bool InitTristates(volatile TRegs * regs)
// Tri-states: 0--> output, 1--> input
// The GPIO device has two channels. We use one to output to the LEDs,
// and the other to read from the buttons.
{
  if (regs == NULL) {
    printf("Error: Calling InitTristates() on a non-initialized accelerator.\n");
    return false;
  }

  // Init 3-states for writing (LEDs) and reading (buttons).
  // This is pointer arithmetic, not integer one: regs + LEDS_TRISTATE*sizeof(uint32_t)
  regs->LEDS_TRISTATE = 0xFFFFFFF0;
  regs->BTNS_TRISTATE = 0xFFFFFFFF;
  return true;
}

uint32_t ReadButtons(volatile TRegs * regs)
{
  return regs->BTNS_REG & 0xF; // Only 4 LSBs
}

void SetLEDs(volatile TRegs * regs, uint32_t LedsValue)
{
  ...
}


///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// main() ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

int main(int argc, char ** argv)
{
  uint32_t buttons = 0; // Last buttons read status

  printf("\n\nThis program requires that the GPIO bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

  CAccelDriver gpio(true); // Activate logging.
  // regs will contain the base address of the GPIO in the virtual address space of this application.
  volatile TRegs * regs = NULL;
  if ( gpio.Open(GPIO_ADDRESS, MAP_SIZE, (volatile void **)&regs) != CAccelDriver::OK ) {
    printf("Error mapping device at physical address 0x%08X\n", GPIO_ADDRESS);
    return -1;
  }
  printf("Device at physical address 0x%08X successfully mapped into the application virtual address space at 0x%08X\n\n",
          GPIO_ADDRESS, (uint32_t)regs);

  printf("The program will exit by pushing the 4 buttons at the same time.\n");
  printf("Press a key\n");
  getchar();

  InitTristates(regs);
  SetLEDs(regs, ...);  // Turn off the leds.

  uint32_t count = 0;
  do {
    buttons = ... // Read the buttons
    ... // Copy the buttons into the LEDs

    printf("Count: %u - SW3: %s - SW2: %s, SW1: %s, SW0: %s          \r", count++,
      TESTBIT(buttons, 8) ? "ON" : "OFF", TESTBIT(buttons, 4) ? "ON" : "OFF",
      TESTBIT(buttons, 2) ? "ON" : "OFF", TESTBIT(buttons, 1) ? "ON" : "OFF");
    fflush(stdout);

    usleep(100000);
  } while (...) // Exit if user pressed the 4 buttons at once
  printf("\n");

  return 0;
}


