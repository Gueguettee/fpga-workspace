#include <stdint.h>
#include <stdio.h>
#include "adder.h"

int main(int , char ** )
{
	uint32_t a = 5, b = 3, res;

	Adder(a, b, res);
	printf("Result: %u\n", res);


	return 0;
}
