#include <cstdint>
#include "adder.h"

void Adder(uint32_t a, uint32_t b, uint32_t &res)
{
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE s_axilite port=a
#pragma HLS INTERFACE s_axilite port=b
#pragma HLS INTERFACE s_axilite port=res

	res = a + b;
}
