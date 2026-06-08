#ifndef SPARSE_FACTOR_H
#define SPARSE_FACTOR_H

#include <stdint.h>
#include "fxp_utils.h"
#include "constants.h"
#include "hls_stream.h"

// Simplicial up-looking sparse LDL^T factor. L arrays live on-chip up to
// SPARSE_L_ON_CHIP_MAX_NNZ (URAM for values, BRAM for indices/positions).
// L_values_csc is the CSC store; L_values_csr holds the same values in CSR
// (row-major) order, mapped via L_csr_pos[p] (CSC pos -> CSR slot).
void sparse_factor_stream_hw(
    uint32_t m,
    uint32_t nnz_K,
    uint32_t nnz_L,
    const uint32_t K_colptr[SPARSE_MAX_M + 1],
    const uint16_t K_rowidx[SPARSE_MAX_NNZ_K],
    hls::stream<TFXP> &k_col_stream,
    const uint32_t L_colptr[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    const uint32_t L_rowptr[SPARSE_MAX_M + 1],
    const uint16_t L_colidx_csr[SPARSE_L_ON_CHIP_MAX_NNZ],
    const uint32_t L_csr_pos[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    L_values_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    L_values_csr[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    Dv[SPARSE_MAX_M],
    TFXP    Dv_inv[SPARSE_MAX_M],
    hls::stream<TFXP> &l_col_stream,
    uint32_t &iter_count);

#endif // SPARSE_FACTOR_H
