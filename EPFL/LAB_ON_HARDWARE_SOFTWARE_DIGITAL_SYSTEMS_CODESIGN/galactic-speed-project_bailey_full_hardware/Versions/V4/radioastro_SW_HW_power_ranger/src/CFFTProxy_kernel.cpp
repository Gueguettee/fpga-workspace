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
#include "CAccelDriver.hpp"
#include "CFFTProxy_kernel.hpp"

uint32_t CFFTProxy::FFT_HW(void *In_real, void *In_imag, int log2_nfft, void *Out_real, void *Out_imag, uint32_t addr_offset, int workers)
{
  uint32_t phyIn_real, phyIn_imag, phyOut_real, phyOut_imag;

  if (logging)
    printf("CFFTProxy::FFT_HW(Input=0x");

  if (driver == 0) {
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

  struct user_message message = {(uint32_t)phyIn_real, (uint32_t)phyIn_imag, (uint32_t)log2_nfft, (uint32_t)phyOut_real, (uint32_t)phyOut_imag, (uint32_t)workers};
  
  // int nfft = 1 << log2_nfft;
  // cma_flush_cache(In_real, (uint32_t)phyIn_real, nfft*workers*sizeof(uint32_t));
  // cma_flush_cache(In_imag, (uint32_t)phyIn_imag, nfft*workers*sizeof(uint32_t));
  // cma_invalidate_cache(Out_real, (uint32_t)phyOut_real, nfft*workers*sizeof(uint32_t));
  // cma_invalidate_cache(Out_imag, (uint32_t)phyOut_imag, nfft*workers*sizeof(uint32_t));

  if (logging)
    printf("\nStarting accel...\n");

  int32_t readBytes = read(driver, (void *)&message, sizeof(message));
  if (readBytes != 0)
    printf("Warning! Read %d bytes instead than %d\n", readBytes, 0);

  // cma_invalidate_cache(Out_real, (uint32_t)phyOut_real, nfft*workers*sizeof(uint32_t));
  // cma_invalidate_cache(Out_imag, (uint32_t)phyOut_imag, nfft*workers*sizeof(uint32_t));

  return OK;
}
