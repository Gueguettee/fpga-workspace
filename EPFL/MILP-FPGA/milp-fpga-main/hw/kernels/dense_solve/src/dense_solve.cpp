#include <stdint.h>
#include "dense_solve.h"
#include "gaussian_solve.h"
#include "cholesky_solve.h"
#include "constants.h"
#include "hls_stream.h"

///////////////////////////////////////////////////////////////////////////////
// K-formation (column-major): streams out one column at a time
///////////////////////////////////////////////////////////////////////////////

static void k_formation_hw(
    uint32_t m, uint32_t n,
    TFXP Ad[DENSE_MAX_M][DENSE_MAX_N],
    TFXP D[DENSE_MAX_N],
    hls::stream<TFXP> &k_col_stream)
{
  LOOP_K_COL: for (uint32_t col = 0; col < DENSE_MAX_M; col++) {
    if (col >= m) break;

    // Precompute acj_dj[k] = Ad[col][k] * D[k]
    TFXP acj_dj[DENSE_MAX_N];
    #pragma HLS ARRAY_PARTITION variable=acj_dj complete

    LOOP_K_PRE: for (uint32_t k = 0; k < DENSE_MAX_N; k++) {
    #pragma HLS PIPELINE II=1
      if (k >= n) break;

      acj_dj[k] = FXP_Mult(Ad[col][k], D[k]);
    }

    // Accumulate: sum[row] += acj_dj[k] * Ad[row][k] for row >= col
    TFXP sum[DENSE_MAX_M] = {0};
    #pragma HLS ARRAY_PARTITION variable=sum cyclic factor=K_BUILDING_UNROLLING_FACTOR dim=1

    uint32_t row_start = (col / K_BUILDING_UNROLLING_FACTOR) * K_BUILDING_UNROLLING_FACTOR;
    LOOP_K_DOT_OUTER: for (uint32_t k = 0; k < DENSE_MAX_N; k++) {
      if (k >= n) break;
      LOOP_K_DOT_INNER: for (uint32_t row = row_start; row < DENSE_MAX_M; row++) {
      #pragma HLS PIPELINE II=1
      #pragma HLS UNROLL factor=K_BUILDING_UNROLLING_FACTOR
        if (row >= m) break;
        if (row >= col) {
          sum[row] += FXP_Mult(acj_dj[k], Ad[row][k]);
        }
      }
    }

    // Stream out lower triangle of column col: K[col][col], K[col+1][col], ..., K[m-1][col]
    LOOP_K_STREAM: for (uint32_t row = col; row < DENSE_MAX_M; row++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M
    #pragma HLS PIPELINE II=1
      if (row >= m) break;

      k_col_stream.write(sum[row]);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////
// DATAFLOW wrapper: overlaps K-formation with Cholesky solve
///////////////////////////////////////////////////////////////////////////////

#ifdef USE_CHOLESKY
static void kform_and_solve_hw(
    uint32_t m, uint32_t n,
    TFXP Ad[DENSE_MAX_M][DENSE_MAX_N],
    TFXP D[DENSE_MAX_N],
    TFXP b[DENSE_MAX_M],
    TFXP dy[DENSE_MAX_M])
{
  #pragma HLS DATAFLOW

  hls::stream<TFXP> k_col_stream;
  #pragma HLS STREAM variable=k_col_stream depth=DENSE_MAX_M

  k_formation_hw(m, n, Ad, D, k_col_stream);
  cholesky_solve_hw(m, k_col_stream, b, dy);
}
#endif

///////////////////////////////////////////////////////////////////////////////
// Top-level kernel
///////////////////////////////////////////////////////////////////////////////

void DenseSolve(TFXP_WIRE *input, TFXP_WIRE *output, uint32_t inputWidth, uint32_t inputHeight) {
#pragma HLS INTERFACE s_axilite port=inputWidth
#pragma HLS INTERFACE s_axilite port=inputHeight
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE m_axi port=input offset=slave bundle=master1 \
  num_read_outstanding=32 max_read_burst_length=256 \
  num_write_outstanding=32 depth=263168
#pragma HLS INTERFACE m_axi port=output offset=slave bundle=master1 \
  num_write_outstanding=32 depth=512

  uint32_t n = inputWidth & 0xFFFF;
  uint32_t m = inputHeight & 0xFFFF;
  uint32_t skipAd = (inputHeight >> 16) & 1;
  uint32_t mn = m * n;

  static TFXP Ad[DENSE_MAX_M][DENSE_MAX_N];
  #pragma HLS BIND_STORAGE variable=Ad type=ram_t2p impl=uram
  #pragma HLS ARRAY_PARTITION variable=Ad cyclic factor=K_BUILDING_UNROLLING_FACTOR dim=1
  // #pragma HLS ARRAY_RESHAPE variable=Ad cyclic factor=2 dim=2

  TFXP D[DENSE_MAX_N];
  TFXP b[DENSE_MAX_M];
  TFXP dy[DENSE_MAX_M];
  #pragma HLS ARRAY_PARTITION variable=dy cyclic factor=SOLVING_UNROLLING_FACTOR dim=1

  // Burst-read Ad (skip if cached from previous call)
  if (!skipAd) {
    LOOP_READ_AD: for (uint32_t i = 0; i < m; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M
      LOOP_READ_AD_2: for (uint32_t j = 0; j < n; j++) {
      #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_N
      #pragma HLS LOOP_FLATTEN
      #pragma HLS PIPELINE II=2

        Ad[i][j] = input[i * n + j];
      }
    }
  }

  // Burst-read D
  LOOP_READ_D: for (uint32_t j = 0; j < n; j++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_N
  #pragma HLS PIPELINE II=1

    D[j] = input[mn + j];
  }

  // Burst-read rhs
  LOOP_READ_RHS: for (uint32_t i = 0; i < m; i++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M
  #pragma HLS PIPELINE II=1

    b[i] = input[mn + n + i];
  }

#ifndef __SYNTHESIS__
  PrintFxpRange("Ad", Ad[0], n);
  PrintFxpRange("D", D, n);
  PrintFxpRange("rhs", b, m);
#endif

#ifdef USE_CHOLESKY
  kform_and_solve_hw(m, n, Ad, D, b, dy);
#else
  // Gaussian path: no DATAFLOW (needs full K upfront for pivoting)
  {
    TFXP K[DENSE_MAX_M][DENSE_MAX_M];
    #pragma HLS BIND_STORAGE variable=K type=ram_t2p impl=bram
    #pragma HLS ARRAY_PARTITION variable=K cyclic factor=SOLVING_UNROLLING_FACTOR dim=2

    LOOP_K_BUILDING: for (uint32_t i = 0; i < DENSE_MAX_M; i++) {
      if (i >= m) break;

      TFXP aij_dj[DENSE_MAX_N];

      TFXP sum[DENSE_MAX_M] = {0};
      #pragma HLS ARRAY_PARTITION variable=sum cyclic factor=K_BUILDING_UNROLLING_FACTOR dim=1

      LOOP_K_BUILDING_2_1: for (uint32_t j = 0; j < DENSE_MAX_N; j++) {
      #pragma HLS PIPELINE II=1
        if (j >= n) break;

        aij_dj[j] = FXP_Mult(Ad[i][j], D[j]);
      }

      LOOP_K_BUILDING_2_2: for (uint32_t idx = 0; idx < DENSE_MAX_N * DENSE_MAX_M; idx++) {
      #pragma HLS PIPELINE II=1
      #pragma HLS UNROLL factor=K_BUILDING_UNROLLING_FACTOR
        uint32_t j  = idx >> DENSE_MAX_M_POWER;
        uint32_t k2 = idx & (DENSE_MAX_M - 1);
        if (j >= n || k2 < i || k2 >= m) continue;

        sum[k2] += FXP_Mult(aij_dj[j], Ad[k2][j]);
      }

      LOOP_K_BUILDING_2_3: for (uint32_t k2 = 0; k2 < DENSE_MAX_M; k2++) {
      #pragma HLS PIPELINE II=2
        if (k2 < i) continue;
        if (k2 >= m) break;

        K[i][k2] = sum[k2];
        K[k2][i] = sum[k2];  // Mirror
      }
    }

    gaussian_solve_hw(m, K, b, dy);
  }
#endif

#ifndef __SYNTHESIS__
  PrintFxpRange("dy", dy, m);
#endif

  // Burst-write dy
  LOOP_WRITE_DY: for (uint32_t i = 0; i < m; i++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=DENSE_MAX_M
  #pragma HLS PIPELINE II=1

    output[i] = dy[i];
  }
}
