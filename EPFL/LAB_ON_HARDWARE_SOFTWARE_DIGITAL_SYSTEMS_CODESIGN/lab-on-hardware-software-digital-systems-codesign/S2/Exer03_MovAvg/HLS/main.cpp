#include <ap_int.h>
#include <stdint.h>
#include <stdio.h>
#include "mov.h"

const int window_length = 7;
const int length = 100;
ap_uint<32> input[length], output[length];

void PrintVector(ap_uint<32> * vector, int length)
{
  for (int ii = 0; ii < length; ++ ii)
    printf("%u ", (uint32_t)vector[ii]);
  printf("\n");
}

int main(int, char **)
{
  for (uint32_t ii = 0; ii < length; ++ ii) {
    input[ii] = ii;
    output[ii] = 0;
  }

	MovingAvg(input, output, length);

  printf("Input:\n");
  PrintVector(input, length);
  printf("Output:\n");
  PrintVector(output, length);

	return 0;
}
