#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <map>
#include <unistd.h>
#include "util.hpp"
#include "CAccelProxy.hpp"
#include "CSparseSolveProxy.hpp"

uint32_t CSparseSolveProxy::SparseSolve_HW(void *input, void *output,
      uint32_t m, uint32_t n,
      uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
      uint32_t mode,
      uint32_t *kform_iters, uint32_t *factor_iters,
      uint32_t *triangular_iters)
{
  volatile TRegs * regs = (TRegs*)accelRegs;
  uint64_t phyInput, phyOutput;
  uint32_t status;

  if (logging)
    printf("CSparseSolveProxy::SparseSolve_HW(Input=0x%016lX Output=0x%016lX "
           "m=%u n=%u nnz_A=%u nnz_K=%u nnz_L=%u)\n",
           (uint64_t)input, (uint64_t)output,
           m, n, nnz_A, nnz_K, nnz_L);

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling SparseSolve_HW() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  phyInput = GetDMAPhysicalAddr(input);
  if (phyInput == 0) return VIRT_ADDR_NOT_FOUND;
  phyOutput = GetDMAPhysicalAddr(output);
  if (phyOutput == 0) return VIRT_ADDR_NOT_FOUND;

  regs->input_l         = (uint32_t)phyInput;
  regs->input_r         = (uint32_t)(phyInput >> 32);
  regs->output_l        = (uint32_t)phyOutput;
  regs->output_r        = (uint32_t)(phyOutput >> 32);
  regs->m               = m;
  regs->n               = n;
  regs->nnz_A           = nnz_A;
  regs->nnz_K           = nnz_K;
  regs->nnz_L           = nnz_L;
  regs->mode            = mode;

  if (logging)
    printf("\nStarting accel...\n");
  fflush(stdout);

  status = regs->control;
  status |= 1;  // ap_start
  regs->control = status;

  do {
    status = regs->control;
  } while ((status & 2) != 2);     // ap_done

  // Per-phase iteration counters
  if (kform_iters)      *kform_iters      = regs->kform_iters;
  if (factor_iters)     *factor_iters     = regs->factor_iters;
  if (triangular_iters) *triangular_iters = regs->triangular_iters;
  return OK;
}
