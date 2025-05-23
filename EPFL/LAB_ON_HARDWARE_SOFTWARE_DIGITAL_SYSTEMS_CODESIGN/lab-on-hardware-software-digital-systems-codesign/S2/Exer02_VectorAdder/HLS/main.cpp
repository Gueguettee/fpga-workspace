#include <ap_int.h>
#include <stdint.h>
#include <stdio.h>
#include "vector.h"

const int length = 16;
ap_uint<32> input1[length], input2[length], output[length];

void PrintVector(ap_uint<32> * vector, int length)
{
  for (int ii = 0; ii < length; ++ ii)
    printf("%u ", (uint32_t)vector[ii]);
  printf("\n");
}

int main(int, char **)
{
  for (uint32_t ii = 0; ii < length; ++ ii) {
    input1[ii] = ii;
    input2[ii] = ii*2;
    output[ii] = 0;
  }

	AddVectors(input1, input2, output, length, 5);

  printf("Input1:\n");
  PrintVector(input1, length);
  printf("Input2:\n");
  PrintVector(input2, length);
  printf("Output:\n");
  PrintVector(output, length);

	return 0;
}
