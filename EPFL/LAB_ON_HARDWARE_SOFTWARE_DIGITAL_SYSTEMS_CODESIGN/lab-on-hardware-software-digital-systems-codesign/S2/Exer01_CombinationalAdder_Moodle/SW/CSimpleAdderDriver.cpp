#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <map>
#include "util.hpp"
#include "CAccelDriver.hpp"
#include "CSimpleAdderDriver.hpp"

uint32_t CSimpleAdderDriver::Add(uint32_t A, uint32_t B, uint32_t & Result)
{
  volatile TRegs * regs = (TRegs*)accelRegs;

  if (logging)
    printf("CSimpleAdderDriver::Add(A=%u, B=%u)\n", A, B);

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling Add() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  ...
  ...

  if (logging) {
    printf("Registers configured:\n");
    printf("A: %u\n", regs->REG_A);
    printf("B: %u\n", regs->REG_B);
  }

  // We should test the res_ap_vld bit (bit 0) of res_reg_ctrl before reading the result
  Result = ...

  return OK;
}

