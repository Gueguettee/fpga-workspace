#ifndef SPARSE_TRIANGULAR_SOLVE_H
#define SPARSE_TRIANGULAR_SOLVE_H

#include <stdint.h>
#include "fxp_utils.h"
#include "constants.h"
#include "hls_stream.h"

// Streaming forward substitution L z = b. Consumes l_col_stream in factor's
// emit order; sits in the kform->factor->forward DATAFLOW to overlap with factor.
void sparse_forward_solve_stream_hw(
    uint32_t m,
    uint32_t nnz_L,
    const uint32_t L_colptr[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    hls::stream<TFXP> &l_col_stream,
    const TFXP    b[SPARSE_MAX_M],
    TFXP          z[SPARSE_MAX_M],
    uint32_t      &iter_count);

// Back substitution L^T dy = D^-1 z. Sequential after the DATAFLOW because L^T
// walks columns m-1..0 and needs all of L_values_csc materialised on chip.
void sparse_back_solve_hw(
    uint32_t m,
    uint32_t nnz_L,
    const uint32_t L_colptr[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    const TFXP    L_values_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    const TFXP    Dv_inv[SPARSE_MAX_M],
    const TFXP    z[SPARSE_MAX_M],
    TFXP          dy[SPARSE_MAX_M],
    uint32_t      &iter_count);

#endif // SPARSE_TRIANGULAR_SOLVE_H
