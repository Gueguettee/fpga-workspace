#include <stdint.h>
#include "sparse_factor.h"

static const uint32_t FLAG_NONE = 0xFFFFFFFFu;

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
    uint32_t &iter_count)
{
  (void)nnz_K; (void)nnz_L;
  uint32_t iters = 0;

  // mark[i] == j means w[i] is live for column j.
  TFXP    w[SPARSE_MAX_M];
  uint32_t mark[SPARSE_MAX_M];
  #pragma HLS ARRAY_PARTITION variable=w    cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS ARRAY_PARTITION variable=mark cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS BIND_STORAGE variable=w    type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=mark type=ram_t2p impl=bram

  INIT_MARK: for (uint32_t i = 0; i < m; i++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
  #pragma HLS PIPELINE II=1
    mark[i] = FLAG_NONE;
    iters++;
  }

  COL_J: for (uint32_t j = 0; j < m; j++) {
  #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M

    // ---- 1) Gather K[:, j] (lower tri) into w + diag, reading from stream ----
    TFXP diag = (TFXP)0;
    uint32_t ks = K_colptr[j];
    uint32_t ke = K_colptr[j + 1];
    GATHER_K: for (uint32_t qK = ks; qK < ke; qK++) {
    #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_NNZ_K
    #pragma HLS PIPELINE II=1
      uint32_t r = (uint32_t)K_rowidx[qK];
      TFXP v = k_col_stream.read();
      if (r == j) {
        diag = v;
      } else {
        w[r] = v;
        mark[r] = j;
      }
      iters++;
    }

    // ---- 2) Rank-1 updates from previous columns of L (row-j walk) ----
    uint32_t lrs = L_rowptr[j];
    uint32_t lre = L_rowptr[j + 1];
    ROW_J_K: for (uint32_t q = lrs; q < lre; q++) {
    #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_M
      uint32_t k = (uint32_t)L_colidx_csr[q];
      if (k >= j) break;  // CSR row j ends with the diagonal at column j

      TFXP l_jk = L_values_csr[q];
      TFXP u    = FXP_Mult(l_jk, Dv[k]);
      diag    -= FXP_Mult(l_jk, u);

      uint32_t cs_k = L_colptr[k];
      uint32_t ce_k = L_colptr[k + 1];

      UPDATE_COL_K: for (uint32_t p2 = cs_k; p2 < ce_k; p2++) {
      #pragma HLS LOOP_TRIPCOUNT min=0 max=SPARSE_MAX_M
      #pragma HLS PIPELINE II=1
      #pragma HLS DEPENDENCE variable=w    type=inter direction=RAW false
      #pragma HLS DEPENDENCE variable=w    type=inter direction=WAW false
      #pragma HLS DEPENDENCE variable=mark type=inter direction=RAW false
      #pragma HLS DEPENDENCE variable=mark type=inter direction=WAW false
        iters++;
        uint32_t r = (uint32_t)L_rowidx_csc[p2];
        if (r <= j) continue;
        TFXP delta = FXP_Mult(L_values_csc[p2], u);
        if (mark[r] != j) {
          w[r] = (TFXP)0 - delta;
          mark[r] = j;
        } else {
          w[r] = w[r] - delta;
        }
      }
    }

    // ---- 3) Set Dv[j] and emit column j of L ----
    // Survival valve for near-singular pivots; same idea as cholesky_solve.cpp:66.
    if (diag <= (TFXP)0) diag = FXP_ONE;
    Dv[j] = diag;
    TFXP inv_diag = FXP_Recip(diag);
    Dv_inv[j] = inv_diag;

    uint32_t cs_j = L_colptr[j];
    uint32_t ce_j = L_colptr[j + 1];

    EMIT_COL_J: for (uint32_t p = cs_j; p < ce_j; p++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
    #pragma HLS PIPELINE II=1
      uint32_t r = (uint32_t)L_rowidx_csc[p];
      TFXP v_emit;
      if (r == j) {
        v_emit = FXP_ONE;
      } else {
        TFXP v = (mark[r] == j) ? w[r] : (TFXP)0;
        v_emit = FXP_Mult(v, inv_diag);
      }
      L_values_csc[p] = v_emit;
      L_values_csr[L_csr_pos[p]] = v_emit;
      l_col_stream.write(v_emit);
      iters++;
    }
  }

  iter_count = iters;
}
