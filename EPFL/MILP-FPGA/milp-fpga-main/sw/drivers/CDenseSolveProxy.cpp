#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <map>
#include <unistd.h>
#include "util.hpp"
#include "CAccelProxy.hpp"
#include "CDenseSolveProxy.hpp"

uint32_t CDenseSolveProxy::DenseSolve_HW(void *input, void *output,
      uint32_t inputWidth, uint32_t inputHeight)
{
  volatile TRegs * regs = (TRegs*)accelRegs;
  uint64_t phyInput, phyOutput;
  uint32_t status;

  if (logging)
    printf("CDenseSolveProxy::DenseSolve_HW(Input=0x%016lX, Output=0x%016lX, "
          "Width=%u, Height=%u)\n",
          (uint64_t)input, (uint64_t)output,
          inputWidth, inputHeight);

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling DenseSolve_HW() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  // Obtain the physical addresses corresponding to each of the virtual addresses.
  phyInput = GetDMAPhysicalAddr(input);
  if (phyInput == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%016lX\n", (uint64_t)input);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyOutput = GetDMAPhysicalAddr(output);
  if (phyOutput == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%016lX\n", (uint64_t)output);
    return VIRT_ADDR_NOT_FOUND;
  }

  regs->input_l = (uint32_t)phyInput;
  regs->input_r = (uint32_t)(phyInput >> 32);
  regs->output_l = (uint32_t)phyOutput;
  regs->output_r = (uint32_t)(phyOutput >> 32);
  regs->inputWidth = inputWidth;
  regs->inputHeight = inputHeight;

  if (logging)
    printf("\nStarting accel...\n");

  status = regs->control;
  status |= 1;  // Set to 1 ap_start
  regs->control = status;

  do {
    status = regs->control;
  } while ( ( (status & 2) != 2) ); // wait until ap_done==1

  return OK;
}
