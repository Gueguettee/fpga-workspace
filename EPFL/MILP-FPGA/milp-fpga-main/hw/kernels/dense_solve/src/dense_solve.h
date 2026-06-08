#ifndef DENSE_SOLVE_H
#define DENSE_SOLVE_H

#include "fxp_utils.h"
#include "hls_stream.h"

// LDL^T Cholesky is the default; -DUSE_GAUSSIAN switches to Gaussian elimination.
#ifndef USE_GAUSSIAN
#define USE_CHOLESKY
#endif

#ifndef K_BUILDING_UNROLLING_FACTOR
#define K_BUILDING_UNROLLING_FACTOR 32
#endif
#define SOLVING_UNROLLING_FACTOR K_BUILDING_UNROLLING_FACTOR

void DenseSolve(TFXP_WIRE *input, TFXP_WIRE *output, uint32_t inputWidth, uint32_t inputHeight);

#endif // DENSE_SOLVE_H
