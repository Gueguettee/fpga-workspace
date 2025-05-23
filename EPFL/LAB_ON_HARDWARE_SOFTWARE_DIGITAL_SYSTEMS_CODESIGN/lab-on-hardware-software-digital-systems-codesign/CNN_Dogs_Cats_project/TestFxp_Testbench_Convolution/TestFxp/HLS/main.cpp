#include <stdio.h>
#include <stdint.h>
#include <ap_fixed.h>


///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
	ap_fixed<4,2> a = 0.5;

	float values[] = {
        3, 2, // Cannot be represented
        1.75, 1.5, 1.25, 1.0, 0.75, 0.5, 0.25, 0, -0.25, -0.5, -0.75, -1.0, -1.25, -1.5, -1.75, -2.0, 
        -2.25, -3}; // Cannot be represented
	uint32_t numValues = sizeof(values) / sizeof(float);

	for (uint32_t ii = 0; ii < numValues; ++ ii) {
		a = values[ii];
    bool correct = (a.to_float()) == values[ii];
		std::cout << "Value = " << values[ii] << "\t --> a = " << a << " -->\t\t" << (correct ? "OK\n" : "FAIL\n");
	}

	for (uint32_t ii = 0; ii < numValues; ++ ii) {
    a = values[ii];
    bool correct = (a.to_float()) == values[ii];
    if (correct) {
      printf("Float=%0.2f --> FxP (hex)=%02hX\n", values[ii], *(uint8_t*)&a);
    }
  }

  return 0;
}


