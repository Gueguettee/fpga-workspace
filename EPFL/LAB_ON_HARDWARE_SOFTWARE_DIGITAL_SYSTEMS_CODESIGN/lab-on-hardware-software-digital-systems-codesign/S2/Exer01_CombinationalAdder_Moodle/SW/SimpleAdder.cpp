#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <map>
#include "CAccelDriver.hpp"
#include "CSimpleAdderDriver.hpp"

// Address constants
const uint32_t SIMPLEADDER_ADDRESS = 0x40000000; // From Vivado's address editor
const uint32_t MAP_SIZE = 64*1024; // Size of address range mapped to the GPIO


///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// main() ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

int main(int argc, char ** argv)
{
  printf("\n\nThis program requires that the GPIO bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  getchar();

  CSimpleAdderDriver simpleAdder(false); // Activate logging.
  if ( simpleAdder.Open(SIMPLEADDER_ADDRESS, MAP_SIZE) != CAccelDriver::OK ) {
    printf("Error mapping device at physical address 0x%08X\n", SIMPLEADDER_ADDRESS);
    return -1;
  }
  printf("Device at physical address 0x%08X successfully mapped into the application virtual address space\n\n",
          SIMPLEADDER_ADDRESS);

  srand(time(NULL));

  uint32_t count, errors = 0;
	for (count = 0; count < 10; ++ count) {
  	uint32_t op1 = rand()%1000, op2 = rand()%1000;
		uint32_t resAccel;
    simpleAdder. ...
		uint32_t resCPU = op1 + op2;
		if (resAccel != resCPU)
			++ errors;
		printf("Result: %u + %u = %u (%u)\n", op1, op2, resAccel, resCPU);
	}
	printf("%u/%u tests OK%s\n", count - errors, count, errors ? "" : " - ALL OK!");

  return 0;
}


