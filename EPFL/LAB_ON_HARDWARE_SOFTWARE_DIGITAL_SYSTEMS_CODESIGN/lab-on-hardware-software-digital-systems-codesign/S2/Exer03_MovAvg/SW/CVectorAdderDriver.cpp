#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <map>
#include "util.hpp"
#include "CAccelDriver.hpp"
#include "CVectorAdderDriver.hpp"

uint32_t CVectorAdderDriver::Add(void * input1, void * input2, void * output,
          uint32_t length, uint32_t accum, uint64_t & elapsed)
{
  volatile TRegs * regs = (TRegs*)accelRegs;
  uint32_t phyInput1, phyInput2, phyOutput;
  uint32_t status;
  struct timespec start, end;

  if (logging)
    printf("CVectorAdderDriver::Add(Input1=0x%08X, Input2=0x%08X, Output=0x%08X, Length=%u, Accum=%u)\n", 
          (uint32_t)input1, (uint32_t)input2, (uint32_t)output, length, accum);

  if (accelRegs == NULL) {
    if (logging)
      printf("Error: Calling Add() on a non-initialized accelerator.\n");
    return DEVICE_NOT_INITIALIZED;
  }

  // We need to obtain the physical addresses corresponding to each of the virtual addresses passed by the application.
  // The accelerator uses only the physical addresses (and only contiguous memory).
  phyInput1 = GetDMAPhysicalAddr(input1);
  if (phyInput1 == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)input1);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyInput2 = GetDMAPhysicalAddr(input2);
  if (phyInput2 == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)input2);
    return VIRT_ADDR_NOT_FOUND;
  }
  phyOutput = GetDMAPhysicalAddr(output);
  if (phyOutput == 0) {
    if (logging)
      printf("Error: No physical address found for virtual address 0x%08X\n", (uint32_t)output);
    return VIRT_ADDR_NOT_FOUND;
  }

  regs->input1 = (uint32_t)phyInput1;
  regs->input2 = (uint32_t)phyInput2;
  regs->output = (uint32_t)phyOutput;
  regs->length = length;
  regs->accum = accum;

  if (logging)
    printf("\nStarting accel...\n");
  clock_gettime(CLOCK_MONOTONIC_RAW, &start);

  status = regs->control;
  status |= 1;  // Set to 1 ap_start
  regs->control = status;

  do {
    status = regs->control;
  } while ( ( (status & 2) != 2) ); // wait until ap_done==1

  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  elapsed = CalcTimeDiff(end, start);

  return OK;
}

