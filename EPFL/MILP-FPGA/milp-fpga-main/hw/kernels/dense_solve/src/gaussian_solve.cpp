#include <stdint.h>
#include "gaussian_solve.h"
#include "dense_solve.h"
#include "constants.h"

///////////////////////////////////////////////////////////////////////////////
// Gaussian elimination with partial pivoting
///////////////////////////////////////////////////////////////////////////////

void gaussian_solve_hw(uint32_t m, TFXP K[][DENSE_MAX_M], TFXP b[], TFXP dy[]) {

  LOOP_DENSE_SOLVING_1_1: for (uint32_t i = 0; i < DENSE_MAX_M; i++) {
  #pragma HLS PIPELINE II=1
    if (i >= m) break;

    dy[i] = 0;
  }

#ifndef __SYNTHESIS__
  TFXP minDiag = K[0][0], maxDiag = K[0][0];
  TFXP minF = 0, maxF = 0;
#endif

  LOOP_DENSE_SOLVING_1_2: for (uint32_t k = 0; k < DENSE_MAX_M; k++) {
    if (k >= m) break;

    uint32_t piv = k;
    TFXP best = K[k][k];
    if (best < 0) best = -best;

    LOOP_DENSE_SOLVING_2_1: for (uint32_t i = 1; i < DENSE_MAX_M; i++) {
    #pragma HLS PIPELINE II=1
      if (i <= k) continue;
      if (i >= m) break;

      TFXP v = K[i][k];
      if (v < 0) v = -v;
      if (v > best) { best = v; piv = i; }
    }

    if (piv != k) {
      LOOP_DENSE_SOLVING_2_2: for (uint32_t j = 0; j < DENSE_MAX_M; j++) {
      #pragma HLS PIPELINE II=2
        if (j < k) continue;
        if (j >= m) break;

        TFXP tmp = K[k][j];
        K[k][j] = K[piv][j];
        K[piv][j] = tmp;
      }
      TFXP tb = b[k]; b[k] = b[piv]; b[piv] = tb;
    }

    TFXP diag = K[k][k];
    TFXP inv_diag = FXP_Div(FXP_ONE, diag);

#ifndef __SYNTHESIS__
    if (diag < minDiag) minDiag = diag;
    if (diag > maxDiag) maxDiag = diag;
#endif

    LOOP_DENSE_SOLVING_2_3: for (uint32_t i = 1; i < DENSE_MAX_M; i++) {
      if (i <= k) continue;
      if (i >= m) break;

      TFXP f = FXP_Mult(K[i][k], inv_diag);

#ifndef __SYNTHESIS__
      if (f < minF) minF = f;
      if (f > maxF) maxF = f;
#endif

      K[i][k] = 0;

      TFXP tempK[DENSE_MAX_M];
      #pragma HLS ARRAY_PARTITION variable=tempK cyclic factor=SOLVING_UNROLLING_FACTOR dim=1

      LOOP_DENSE_SOLVING_3_1: for (uint32_t j = 1; j < DENSE_MAX_M; j++) {
      #pragma HLS PIPELINE II=1
      #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR
        if (j <= k) continue;
        if (j >= m) break;

        tempK[j] = K[k][j];
      }

      LOOP_DENSE_SOLVING_3_2: for (uint32_t j = 1; j < DENSE_MAX_M; j++) {
      #pragma HLS PIPELINE II=1
      #pragma HLS UNROLL factor=SOLVING_UNROLLING_FACTOR
        if (j <= k) continue;
        if (j >= m) break;

        K[i][j] -= FXP_Mult(f, tempK[j]);
      }
      b[i] -= FXP_Mult(f, b[k]);
    }
  }

#ifndef __SYNTHESIS__
  printf("  [diag] min=%.4f max=%.4f\n", Fxp2Double(minDiag), Fxp2Double(maxDiag));
  printf("  [factor f] min=%.4f max=%.4f\n", Fxp2Double(minF), Fxp2Double(maxF));
  PrintFxpRange("U (after elim)", K[0], m * m);
  PrintFxpRange("b (after elim)", b, m);
#endif

  LOOP_DENSE_SOLVING_1_3: for (int32_t i = (int32_t)(DENSE_MAX_M - 1); i >= 0; i--) {
    if (i >= (int32_t)m) continue;
    if (i < 0) break;

    TFXP s = b[i];

    LOOP_DENSE_SOLVING_2: for (int32_t j = 1; j < DENSE_MAX_M; j++) {
    #pragma HLS PIPELINE II=1
      if (j <= i) continue;
      if (j >= (int32_t)m) break;

      s -= FXP_Mult(K[i][j], dy[j]);
    }
    dy[i] = FXP_Div(s, K[i][i]);
  }
}
