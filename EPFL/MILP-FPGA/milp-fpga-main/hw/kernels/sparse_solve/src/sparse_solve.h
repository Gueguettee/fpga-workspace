#ifndef SPARSE_SOLVE_H
#define SPARSE_SOLVE_H

#include <stdint.h>
#include "fxp_utils.h"
#include "constants.h"

#define MODE_SETUP            0u
#define MODE_SOLVE            1u

void SparseSolve(TFXP_WIRE *input, TFXP_WIRE *output,
                 uint32_t m, uint32_t n,
                 uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
                 uint32_t mode,
                 uint32_t *kform_iters, uint32_t *factor_iters,
                 uint32_t *triangular_iters);

#endif // SPARSE_SOLVE_H
