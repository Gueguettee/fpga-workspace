#include <stdint.h>
#include "sparse_kform.h"

///////////////////////////////////////////////////////////////////////////////
// Sparse K-formation.
///////////////////////////////////////////////////////////////////////////////

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
    uint32_t &iter_count)
{
  (void)nnz_A; (void)nnz_K;
  uint32_t iters = 0;

  static TFXP     aDj_dense[SPARSE_MAX_N];
  static uint16_t aDj_stamp[SPARSE_MAX_N];
  #pragma HLS BIND_STORAGE variable=aDj_dense type=ram_2p impl=bram
  #pragma HLS BIND_STORAGE variable=aDj_stamp type=ram_2p impl=bram
  const uint16_t STAMP_NONE = 0xFFFFu;

  INIT_ADJ: for (uint32_t c = 0; c < n; c++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_N
  #pragma HLS PIPELINE II=1
    aDj_stamp[c] = STAMP_NONE;
    iters++;
  }

  COL_J: for (uint32_t j = 0; j < m; j++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M

    uint32_t js = A_indptr[j];
    uint32_t je = A_indptr[j + 1];
    uint16_t jstamp = (uint16_t)j;

    // ---- 1) Scatter row j of A scaled by D into aDj_dense + stamp ----
    LOAD_J: for (uint32_t p = js; p < je; p++) {
    #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_N
    #pragma HLS PIPELINE II=1
      uint16_t c = A_indices[p];
      aDj_dense[c] = FXP_Mult(A_values[p], D[c]);
      aDj_stamp[c] = jstamp;
      iters++;
    }

    // ---- 2) For each row i in K's pattern of column j, compute K[i, j] ----
    uint32_t kcs = K_colptr[j];
    uint32_t kce = K_colptr[j + 1];

    K_ROWS: for (uint32_t qK = kcs; qK < kce; qK++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
      uint32_t i = (uint32_t)K_rowidx[qK];
      uint32_t is = A_indptr[i];
      uint32_t ie = A_indptr[i + 1];

      TFXP acc0 = (TFXP)0, acc1 = (TFXP)0;
      uint32_t kend2 = is + (((ie - is) >> 1) << 1);
      DOT: for (uint32_t k = is; k < kend2; k += 2) {
      #pragma HLS LOOP_TRIPCOUNT min=0 max=(SPARSE_MAX_N/2)
      #pragma HLS PIPELINE II=1
        uint16_t col0 = A_indices[k];
        uint16_t col1 = A_indices[k + 1];
        TFXP v0 = (aDj_stamp[col0] == jstamp) ? aDj_dense[col0] : (TFXP)0;
        TFXP v1 = (aDj_stamp[col1] == jstamp) ? aDj_dense[col1] : (TFXP)0;
        acc0 += FXP_Mult(A_values[k],     v0);
        acc1 += FXP_Mult(A_values[k + 1], v1);
        iters++;
      }
      if (kend2 < ie) {
        uint16_t col = A_indices[kend2];
        TFXP v = (aDj_stamp[col] == jstamp) ? aDj_dense[col] : (TFXP)0;
        acc0 += FXP_Mult(A_values[kend2], v);
        iters++;
      }

      k_col_stream.write(acc0 + acc1);
    }
  }

  iter_count = iters;
}
