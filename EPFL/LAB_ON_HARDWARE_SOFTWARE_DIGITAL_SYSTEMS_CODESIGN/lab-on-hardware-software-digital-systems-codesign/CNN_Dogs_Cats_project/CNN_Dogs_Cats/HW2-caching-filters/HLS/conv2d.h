#ifndef CONV2D_H
#define CONV2D_H

//#include <ap_int.h>
#include <cstdint>

const uint32_t DECIMALS = 20;

#define MAX_WIDTH 128
#define MAX_HEIGHT 128
#define MAX_CHANNELS 256
#define MAX_FILTERS 256
#define COEFFS_MULTIPLICATOR 9

typedef int32_t TFXP; // Parameters and activations
typedef int64_t TFXP_MULT;// Intermmediate results of multiplications

void Conv2D_HW(TFXP *input, TFXP *output, TFXP *filters,// TFXP *biases,
		TFXP numChannels, TFXP numFilters,
		TFXP inputWidth, TFXP inputHeight,
		TFXP convWidth, TFXP convHeight);

#endif // CONV2D_H

