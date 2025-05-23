#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <map>
#include "CAccelDriver.hpp"
#include "CVectorAdderDriver.hpp"
#include "util.hpp"

///////////////////////////////////////
// Device kernel driver
const char * DRIVER_NAME = "/dev/adder";
const uint32_t LENGTH = 4*1024*1024; // x4 --> Size of each vector, there are 3 vectors.

// These vectors are for testing the speed in SW - Not used with the accelerator.
// The reason is that the processor would normally use cacheable memory thru the virtual memory system, not the DMA allocated for the device.
uint32_t sw1[LENGTH], sw2[LENGTH], sw3[LENGTH];


///////////////////////////////////////////////////////////////////////////////
void SoftwareProcessing(uint32_t * input1, uint32_t * input2, uint32_t * output,
  uint32_t length, uint32_t acc, unsigned long long & elapsed)
{
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC_RAW, &start);
  for (uint32_t ii = 0; ii < length; ++ ii)
    output[ii] = input1[ii] + input2[ii] + acc;
  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  elapsed = CalcTimeDiff(end, start);
}

///////////////////////////////////////////////////////////////////////////////
void PrintVector(uint32_t * vector, int length)
{
  if (length <= 64) {
    for (int ii = 0; ii < length; ++ ii)
      printf("%u ", vector[ii]);
    printf("\n");
  }
  else {
    printf("[Vector omitted as length %d is too large]\n", length);
  }
}

///////////////////////////////////////////////////////////////////////////////
void InitVectors(uint32_t * v1, uint32_t * v2, uint32_t *v3, uint32_t length)
{
  for (uint32_t ii = 0; ii < length; ++ ii) {
    v1[ii] = ii;
    v2[ii] = ii*3;
    v3[ii] = 4;
  }
}

///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
  unsigned long long timeAccel, timeSW;
  
  printf("\n\nThis program requires that the bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

  CVectorAdderDriver vectorAdder(false); // Deactivate logging.
  if ( vectorAdder.Open(DRIVER_NAME) != CAccelDriver::OK ) {
    printf("Error opening the device driver %s", DRIVER_NAME);
    return -1;
  }
  printf("Device successfully opened from the kernel driver\n\n");

  // We have to allocate DMA memory for the device. We receive addresses in the *virtual* address space of the application.
  printf("Allocating DMA memory...\n");
  uint32_t * input1 = (uint32_t *)vectorAdder.AllocDMACompatible(LENGTH * 4);
  uint32_t * input2 = (uint32_t *)vectorAdder.AllocDMACompatible(LENGTH * 4);
  uint32_t * output = (uint32_t *)vectorAdder.AllocDMACompatible(LENGTH * 4);
  printf("DMA memory allocated.\n");
  printf("Input1: Virtual address: 0x%08X (%u)\n", (uint32_t)input1, (uint32_t)input1);
  printf("Input2: Virtual address: 0x%08X (%u)\n", (uint32_t)input2, (uint32_t)input2);
  printf("Output: Virtual address: 0x%08X (%u)\n", (uint32_t)output, (uint32_t)output);

  if ( (input1 == NULL) || (input2 == NULL) || (output == NULL) ) {
    printf("Error allocating DMA memory for %u bytes.\n", LENGTH * 4);
  }
  else {
    printf("Initializing vectors...\n");
    InitVectors(input1, input2, output, LENGTH);
    printf("Vectors initialized...\n");

    // The peripheral works with physical addresses directly on the system bus.
    for (uint32_t reps = 0; reps < 20; ++ reps)
      vectorAdder.Add(input1, input2, output, LENGTH, 7, timeAccel);

    printf("Input1:\n");
    PrintVector(input1, LENGTH);
    printf("Input2:\n");
    PrintVector(input2, LENGTH);
    printf("Output:\n");
    PrintVector(output, LENGTH);
    uint32_t numErrors = 0;
    for (uint32_t ii = 0; ii < LENGTH; ++ ii)
      numErrors += (output[ii] != (input1[ii]+input2[ii]+7));
    if (!numErrors)
      printf("TEST OK!\n");
    else
      printf("TEST FAILED -- %u errors.\n", numErrors);

    // Measure the speed in SW.
    printf("Measuring speed in SW\n");
    InitVectors(sw1, sw2, sw3, LENGTH);
    SoftwareProcessing(sw1, sw2, sw3, LENGTH, 7, timeSW);
  
    printf("\n\nTime accelerator: %0.3lf s (%llu ns)\n", timeAccel/1e9, timeAccel);
    printf("Time SW: %0.3lf s (%llu ns)\n", timeSW/1e9, timeSW);
  }

  // Free the DMA memory. ---IMPORTANT--- DMA memory is a system-wide resource!!!!!! It's not freed automatically when the app is closed.
  if (input1 != NULL)
    vectorAdder.FreeDMACompatible(input1);
  if (input2 != NULL)
    vectorAdder.FreeDMACompatible(input2);
  if (output != NULL)
    vectorAdder.FreeDMACompatible(output);

	return 0;
}

