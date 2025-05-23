#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <map>
extern "C" {
#include <libxlnk_cma.h>  // Required for memory-mapping functions from Xilinx
}

#include "utils.h"
#include "CAccelProxy.hpp"
#include "CFFTProxy.hpp"

uint32_t CFFTProxy::FFT_HW(void *In_real, void *In_imag, int log2_nfft, void *Out_real, void *Out_imag, uint32_t addr_offset, int workers)
{
  volatile TRegs * regs = (TRegs*)accelRegs;
  uint32_t phyIn_real, phyIn_imag, phyOut_real, phyOut_imag;
  uint32_t status;

  if (logging)
    printf("CFFTProxy::FFT_HW(Input=0x");

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling FFT_HW() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  // We need to obtain the physical addresses corresponding to each of the virtual addresses passed by the application.
  // The accelerator uses only the physical addresses (and only contiguous memory).
  phyIn_real = GetDMAPhysicalAddr(In_real) + addr_offset;
  if (phyIn_real == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)In_real);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyIn_imag = GetDMAPhysicalAddr(In_imag) + addr_offset;
  if (phyIn_imag == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)In_imag);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyOut_real = GetDMAPhysicalAddr(Out_real) + addr_offset;
  if (phyOut_real == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)Out_real);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyOut_imag = GetDMAPhysicalAddr(Out_imag) + addr_offset;
  if (phyOut_imag == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)Out_imag);
    return VIRT_ADDR_NOT_FOUND;
  }

  // Write to registers, Program accel regs
  regs->In_real = (uint32_t)phyIn_real;
  regs->In_imag = (uint32_t)phyIn_imag;
  regs->log2nfft = (uint32_t)log2_nfft;
  regs->Out_real = (uint32_t)phyOut_real;
  regs->Out_imag = (uint32_t)phyOut_imag;
  regs->numHW = (uint32_t)workers;

  if (logging)
    printf("\nStarting accel...\n");

  // Send start command to the accel
  status = regs->control;
  status |= 1;  // Set to 1 ap_start
  regs->control = status;

  // Wait for done signal from the accel
  do {
    status = regs->control;
  } while ( ( (status & 2) != 2) ); // wait until ap_done==1

  return OK;
}
