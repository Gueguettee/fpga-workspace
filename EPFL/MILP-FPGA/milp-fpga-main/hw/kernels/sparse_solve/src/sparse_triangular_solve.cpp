#include <stdint.h>
#include "sparse_triangular_solve.h"

void sparse_forward_solve_stream_hw(
    uint32_t m,
    uint32_t nnz_L,
    const uint32_t L_colptr[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    hls::stream<TFXP> &l_col_stream,
    const TFXP    b[SPARSE_MAX_M],
    TFXP          z[SPARSE_MAX_M],
    uint32_t      &iter_count)
{
  (void)nnz_L;
  uint32_t iters = 0;

  LOOP_FWD_INIT: for (uint32_t i = 0; i < m; i++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
  #pragma HLS PIPELINE II=1
    z[i] = b[i];
    iters++;
  }

  LOOP_FWD_COL: for (uint32_t j = 0; j < m; j++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M

    uint32_t cs = L_colptr[j];
    uint32_t ce = L_colptr[j + 1];

    // First emit from factor is the unit diagonal at p=cs (FXP_ONE) — discard.
    TFXP diag_val = l_col_stream.read();
    (void)diag_val;
    iters++;

    TFXP zj = z[j];

    // r values are strictly increasing within a column, so the DEPENDENCE
    // pragmas hold.
    LOOP_FWD_SCATTER: for (uint32_t p = cs + 1; p < ce; p++) {
    #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_M
    #pragma HLS PIPELINE II=1
    #pragma HLS DEPENDENCE variable=z type=inter direction=RAW false
    #pragma HLS DEPENDENCE variable=z type=inter direction=WAW false
      TFXP v = l_col_stream.read();
      uint32_t r = (uint32_t)L_rowidx_csc[p];
      z[r] -= FXP_Mult(v, zj);
      iters++;
    }
  }

  iter_count = iters;
}

void sparse_back_solve_hw(
    uint32_t m,
    uint32_t nnz_L,
    const uint32_t L_colptr[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    const TFXP    L_values_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    const TFXP    Dv_inv[SPARSE_MAX_M],
    const TFXP    z[SPARSE_MAX_M],
    TFXP          dy[SPARSE_MAX_M],
    uint32_t      &iter_count)
{
  (void)nnz_L;
  uint32_t iters = 0;

  // ===== Diagonal solve folded into back-init: dy = z * Dv_inv =====
  LOOP_DIAG: for (uint32_t i = 0; i < m; i++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
  #pragma HLS PIPELINE II=1
    dy[i] = FXP_Mult(z[i], Dv_inv[i]);
    iters++;
  }

  // ===== Back substitution: L^T dy = (D^-1 z) =====
  LOOP_BACK_COL: for (int32_t j = (int32_t)m - 1; j >= 0; j--) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M

    uint32_t cs = L_colptr[j];
    uint32_t ce = L_colptr[j + 1];

    TFXP partial_sum[SPARSE_UNROLL] = {0};
    #pragma HLS ARRAY_PARTITION variable=partial_sum complete

    LOOP_BACK_DOT: for (uint32_t p = cs + 1; p < ce; p++) {
    #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_M
    #pragma HLS PIPELINE II=1
      uint32_t r = (uint32_t)L_rowidx_csc[p];
      partial_sum[p % SPARSE_UNROLL] -= FXP_Mult(L_values_csc[p], dy[r]);
      iters++;
    }

    TFXP s = dy[j];
    LOOP_BACK_REDUCE: for (uint32_t k = 0; k < SPARSE_UNROLL; k++) {
    #pragma HLS UNROLL
      s += partial_sum[k];
    }
    dy[j] = s;
  }

  iter_count = iters;
}
