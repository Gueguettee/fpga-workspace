#ifndef SPARSE_KFORM_H
#define SPARSE_KFORM_H

#include <stdint.h>
#include "fxp_utils.h"
#include "constants.h"
#include "hls_stream.h"

///////////////////////////////////////////////////////////////////////////////
// Sparse K-formation: K = A diag(D) A^T, filled only at the host-precomputed
// lower-tri K pattern via a two-pointer merge over intersecting nonzeros.
///////////////////////////////////////////////////////////////////////////////

// Streaming variant: writes K[i, j] column-by-column into k_col_stream in
// K_rowidx order; consumed in the same order inside a DATAFLOW region.
void sparse_kform_stream_hw(
    uint32_t m,
    uint32_t n,
    uint32_t nnz_A,
    uint32_t nnz_K,
    const uint32_t A_indptr[SPARSE_MAX_M + 1],
    const uint16_t A_indices[SPARSE_MAX_NNZ_A],
    const TFXP    A_values[SPARSE_MAX_NNZ_A],
    const TFXP    D[SPARSE_MAX_N],
    const uint32_t K_colptr[SPARSE_MAX_M + 1],
    const uint16_t K_rowidx[SPARSE_MAX_NNZ_K],
    hls::stream<TFXP> &k_col_stream,
    uint32_t &iter_count);

#endif // SPARSE_KFORM_H
