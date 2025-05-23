#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <memory.h>
#include <time.h>
#include <unistd.h>
#include <map>
#include "util.hpp"

const uint32_t MAX_PRINT_LENGTH = 32;
const uint32_t LENGTH = 1000000;
const uint32_t WINDOW_LENGTH = 7;
const uint32_t NUM_REPETITIONS = 100;

// These vectors are for testing the speed in SW - Not used with the accelerator.
// The reason is that the processor would normally use cacheable memory thru the virtual memory system, not the DMA allocated for the device.
uint32_t inputSW[LENGTH], outputSW[LENGTH];

///////////////////////////////////////////////////////////////////////////////
void InitVector(uint32_t * v, uint32_t length, uint32_t value, bool autoInc = false, bool random = false)
{
  if (autoInc) {
    for (uint32_t ii = 0; ii < length; ++ii)
      v[ii] = ii;
  } 
  else if (random) {
    for (uint32_t ii = 0; ii < length; ++ii)
      v[ii] = rand();
  }
  else {
    for (uint32_t ii = 0; ii < length; ++ii)
      v[ii] = value;
  }
}

///////////////////////////////////////////////////////////////////////////////
void ComputeSW(uint32_t * input, uint32_t * output, uint32_t length, uint64_t & elapsed)
{
  struct timespec start, end;

  clock_gettime(CLOCK_MONOTONIC_RAW, &start);
	for (uint32_t external = 0; external < (LENGTH - WINDOW_LENGTH + 1); ++ external) {
		uint32_t accum;
		accum = 0;
		for (uint32_t internal = 0; internal < WINDOW_LENGTH; ++ internal) {
			accum += input[external + internal];
		}
		output[external] = accum / WINDOW_LENGTH;
	}
  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  elapsed += CalcTimeDiff(end, start);
}

///////////////////////////////////////////////////////////////////////////////
void ComputeSWFast(uint32_t * input, uint32_t * output, uint32_t length, uint64_t & elapsed)
{
  struct timespec start, end;
  uint32_t accum = 0;
  uint32_t external, outputIndex;

  clock_gettime(CLOCK_MONOTONIC_RAW, &start);

  // Fill the accum with the first WINDOW_LENGTH - 1 values
  for (external = 0; external < WINDOW_LENGTH - 1; ++ external)
    accum += input[external];

  // Traverse the rest of the elements, adding the new, subtracting the oldest.
  outputIndex = 0;
  for (external = WINDOW_LENGTH - 1; external < length; ++ external) {
    accum += input[external];
    output[outputIndex++] = accum / WINDOW_LENGTH;
    accum -= input[external - (WINDOW_LENGTH - 1)]; // This operation is not associative bc it's unsigned.
  }

  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  elapsed += CalcTimeDiff(end, start);
}

///////////////////////////////////////////////////////////////////////////////
uint32_t CompareVectors(uint32_t * a, uint32_t * b, uint32_t length)
{
	uint32_t numErrors = 0;

	for (uint32_t ii = 0; ii < length; ++ ii) {
		if (a[ii] != b[ii])
			++ numErrors;
	}

	return numErrors;
}


///////////////////////////////////////////////////////////////////////////////
int main(int argc, char **argv)
{
  uint64_t timeSWSlow, timeSWFast;
	//uint32_t numErrors;

	srand(time(NULL));

  // TEST: Fixed value to 1.
  printf("\n====================\nTest of value=1\n\n");
  InitVector(inputSW, LENGTH, 1);
  memset(outputSW, 0, LENGTH * sizeof(uint32_t));

  timeSWSlow = 0;
  timeSWFast = 0;
  for (uint32_t ii = 0; ii < NUM_REPETITIONS; ++ ii) {  
    // The functions accumulate the execution time.
    ComputeSW(inputSW, outputSW, LENGTH, timeSWSlow);
    ComputeSWFast(inputSW, outputSW, LENGTH, timeSWFast);
  }
  
  //numErrors = CompareVectors(outputAccel, outputSW, LENGTH); // Compare also the zeroes at the end of the vector
  //if (numErrors)
  //	printf("---> %u Errors!\n", numErrors);
  //else
  //	printf("---> OK!\n");
  printf("Time SW (slow): %0.3lf s (%llu ns)\n", (timeSWSlow/1e9)/NUM_REPETITIONS, timeSWSlow/NUM_REPETITIONS);
  printf("Time SW (fast): %0.3lf s (%llu ns)\n", (timeSWFast/1e9)/NUM_REPETITIONS, timeSWFast/NUM_REPETITIONS);
 
  printf("\n\n");

  unsigned long long timeAccel, timeSW;
  
  printf("\n\nThis program requires that the bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

  CVectorAdderDriver vectorAdder(false); // Deactivate logging.
  if ( vectorAdder.Open(VECTORADDER_ADDR, MAP_SIZE) != CAccelDriver::OK ) {
    printf("Error mapping device at physical address 0x%08X\n", VECTORADDER_ADDR);
    return -1;
  }
  printf("Device at physical address 0x%08X successfully mapped into the application virtual address space\n\n",
          VECTORADDER_ADDR);

  // We have to allocate DMA memory for the device. We receive addresses in the *virtual* address space of the application.
  printf("Allocating DMA memory...\n");
  uint32_t * input = (uint32_t *)vectorAdder.AllocDMACompatible(LENGTH * 4);
  uint32_t * output = (uint32_t *)vectorAdder.AllocDMACompatible(LENGTH * 4);
  printf("DMA memory allocated.\n");
  printf("Input1: Virtual address: 0x%08X (%u)\n", (uint32_t)input, (uint32_t)input);
  printf("Output: Virtual address: 0x%08X (%u)\n", (uint32_t)output, (uint32_t)output);

  if ( (input == NULL) || (output == NULL) ) {
    printf("Error allocating DMA memory for %u bytes.\n", LENGTH * 4);
  }
  else {
    printf("Initializing vectors...\n");
    InitVectors(input, output, LENGTH);
    printf("Vectors initialized...\n");

    // The peripheral works with physical addresses directly on the system bus.
    vectorAdder.Add(input, output, LENGTH, 7, timeAccel);

    printf("Input:\n");
    PrintVector(input, LENGTH);
    printf("Output:\n");
    PrintVector(output, LENGTH);
    uint32_t numErrors = 0;
    if (!numErrors)
      printf("TEST OK!\n");
    else
      printf("TEST FAILED -- %u errors.\n", numErrors);
  
    printf("\n\nTime accelerator: %0.3lf s (%llu ns)\n", timeAccel/1e9, timeAccel);
  }

  // Free the DMA memory. ---IMPORTANT--- DMA memory is a system-wide resource!!!!!! It's not freed automatically when the app is closed.
  if (input != NULL)
    vectorAdder.FreeDMACompatible(input);
  if (output != NULL)
    vectorAdder.FreeDMACompatible(output);

	return 0;
}

