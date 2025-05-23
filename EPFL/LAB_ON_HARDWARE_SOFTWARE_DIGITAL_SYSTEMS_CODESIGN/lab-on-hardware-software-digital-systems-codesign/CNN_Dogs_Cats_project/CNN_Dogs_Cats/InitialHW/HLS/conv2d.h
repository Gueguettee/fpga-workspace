#ifndef CONV2D_H
#define CONV2D_H

#include <ap_int.h>
#include <cstdint>

typedef ap_int<32> TFXP; // Parameters and activations
typedef ap_int<64> TFXP_MULT;// Intermmediate results of multiplications

void Conv2D_HW(TFXP *input, TFXP *output, TFXP *filters,
		TFXP numChannels, TFXP numFilters,
		TFXP inputWidth, TFXP inputHeight,
		TFXP convWidth, TFXP convHeight);

#endif // CONV2D_H

