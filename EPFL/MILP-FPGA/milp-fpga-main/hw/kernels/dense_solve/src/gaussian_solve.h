#ifndef GAUSSIAN_SOLVE_H
#define GAUSSIAN_SOLVE_H

#include "fxp_utils.h"
#include "constants.h"

void gaussian_solve_hw(uint32_t m, TFXP K[][DENSE_MAX_M], TFXP b[], TFXP dy[]);

#endif // GAUSSIAN_SOLVE_H
