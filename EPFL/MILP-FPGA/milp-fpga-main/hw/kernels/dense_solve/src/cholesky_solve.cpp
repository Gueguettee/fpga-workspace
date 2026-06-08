#include <stdint.h>
#include "cholesky_solve.h"
#include "dense_solve.h"
#include "constants.h"

///////////////////////////////////////////////////////////////////////////////
// LDL^T Cholesky solve. K columns stream in one at a time (lower triangle) so
// HLS DATAFLOW overlaps the solve with K-formation.
///////////////////////////////////////////////////////////////////////////////

void cholesky_solve_hw(uint32_t m, hls::stream<TFXP> &k_col_stream,
                       TFXP b[], TFXP dy[]) {
  #pragma HLS ARRAY_PARTITION variable=dy cyclic factor=SOLVING_UNROLLING_FACTOR dim=1

  // K array — receives columns from stream, rebuilt every call
  TFXP K[DENSE_MAX_M][DENSE_MAX_M];
  #pragma HLS BIND_STORAGE variable=K type=ram_t2p impl=uram
  #pragma HLS ARRAY_PARTITION variable=K cyclic factor=SOLVING_UNROLLING_FACTOR dim=2
  // #pragma HLS ARRAY_RESHAPE variable=K cyclic factor=2 dim=1

  TFXP Dv[DENSE_MAX_M];

#ifndef __SYNTHESIS__
  TFXP minD = 0, maxD = 0;
#endif

  // ===== LDL^T factorization (column by column) =====

  LOOP_CHOL_COL: for (uint32_t j = 0; j < DENSE_MAX_M; j++) {
    if (j >= m) break;

    // Receive column j from stream (lower triangle: K[j..m-1][j])
    LOOP_RECV_COL: for (uint32_t row = j; row < DENSE_MAX_M; row++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M
    #pragma HLS PIPELINE II=2
      if (row >= m) break;

      K[row][j] = k_col_stream.read();
    }

    // Precompute v[k] = K[j][k] * Dv[k] for k < j
    TFXP v[DENSE_MAX_M];
    #pragma HLS ARRAY_PARTITION variable=v cyclic factor=SOLVING_UNROLLING_FACTOR dim=1

    LOOP_CHOL_PRECOMPUTE: for (uint32_t k = 0; k < DENSE_MAX_M; k++) {
    #pragma HLS PIPELINE II=1
      if (k >= j) break;

      v[k] = FXP_Mult(K[j][k], Dv[k]);
    }

    // Diagonal: Dv[j] = K[j][j] - sum(K[j][k] * v[k])
    TFXP sum_diag = K[j][j];
    LOOP_CHOL_DIAG: for (uint32_t k = 0; k < DENSE_MAX_M; k++) {
    #pragma HLS PIPELINE II=1
      if (k >= j) break;

      sum_diag -= FXP_Mult(K[j][k], v[k]);
    }

    if (sum_diag <= 0) sum_diag = 1;
    Dv[j] = sum_diag;

#ifndef __SYNTHESIS__
    if (j == 0 || sum_diag < minD) minD = sum_diag;
    if (j == 0 || sum_diag > maxD) maxD = sum_diag;
#endif

    TFXP inv_dj = FXP_Div(FXP_ONE, Dv[j]);

    // Off-diagonal: L[i][j] = (K[i][j] - sum(K[i][k]*v[k])) / Dv[j]
    LOOP_CHOL_OFFDIAG: for (uint32_t i = j + 1; i < DENSE_MAX_M; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M-1
      if (i >= m) break;

      TFXP partial_sum[SOLVING_UNROLLING_FACTOR] = {0};
      #pragma HLS ARRAY_PARTITION variable=partial_sum complete

      LOOP_CHOL_DOT: for (uint32_t k = 0; k < DENSE_MAX_M; k++) {
      #pragma HLS PIPELINE II=1
      #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR
        if (k >= j) break;

        partial_sum[k % SOLVING_UNROLLING_FACTOR] -= FXP_Mult(K[i][k], v[k]);
      }

      TFXP sum_off = K[i][j];
      LOOP_CHOL_REDUCE: for (uint32_t p = 0; p < SOLVING_UNROLLING_FACTOR; p++) {
      #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR

        sum_off += partial_sum[p];
      }

      K[i][j] = FXP_Mult(sum_off, inv_dj);
    }
  }

#ifndef __SYNTHESIS__
  printf("  [LDLt D] min=%.4f max=%.4f\n", Fxp2Double(minD), Fxp2Double(maxD));
  PrintFxpRange("L (lower tri)", K[0], m * m);
#endif

  // ===== Forward substitution: L*z = b =====

  TFXP z[DENSE_MAX_M];
  #pragma HLS ARRAY_PARTITION variable=z cyclic factor=SOLVING_UNROLLING_FACTOR dim=1

  LOOP_FWD: for (uint32_t i = 0; i < DENSE_MAX_M; i++) {
    if (i >= m) break;

    TFXP partial_sum_fwd[SOLVING_UNROLLING_FACTOR] = {0};
    #pragma HLS ARRAY_PARTITION variable=partial_sum_fwd complete

    LOOP_FWD_INNER: for (uint32_t j = 0; j < DENSE_MAX_M; j++) {
    #pragma HLS PIPELINE II=1
    #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR
      if (j >= i) break;

      partial_sum_fwd[j % SOLVING_UNROLLING_FACTOR] -= FXP_Mult(K[i][j], z[j]);
    }

    TFXP s_fwd = b[i];
    LOOP_FWD_REDUCE: for (uint32_t p = 0; p < SOLVING_UNROLLING_FACTOR; p++) {
    #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR

      s_fwd += partial_sum_fwd[p];
    }
    z[i] = s_fwd;
  }

  // ===== Diagonal solve: D*y = z (and initialize dy) =====

  TFXP y[DENSE_MAX_M];

  LOOP_DIAG: for (uint32_t i = 0; i < DENSE_MAX_M; i++) {
  #pragma HLS PIPELINE II=1
    if (i >= m) break;

    y[i] = FXP_Div(z[i], Dv[i]);
    dy[i] = 0;
  }

  // ===== Back substitution: L^T*dy = y =====

  LOOP_BACK: for (int32_t i = (int32_t)(m - 1); i >= 0; i--) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M-1
    if (i < 0) break;

    TFXP partial_sum_back[SOLVING_UNROLLING_FACTOR] = {0};
    #pragma HLS ARRAY_PARTITION variable=partial_sum_back complete

    LOOP_BACK_INNER: for (int32_t j = i + 1; j < DENSE_MAX_M; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M-1
    #pragma HLS PIPELINE II=1
      if (j >= (int32_t)m) break;

      partial_sum_back[j % SOLVING_UNROLLING_FACTOR] -= FXP_Mult(K[j][i], dy[j]);
    }

    TFXP s_back = y[i];
    LOOP_BACK_REDUCE: for (uint32_t p = 0; p < SOLVING_UNROLLING_FACTOR; p++) {
    #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR

      s_back += partial_sum_back[p];
    }
    dy[i] = s_back;
  }
}
