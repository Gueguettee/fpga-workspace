#include <stdint.h>
#include "hls_stream.h"
#include "sparse_solve.h"
#include "sparse_kform.h"
#include "sparse_factor.h"
#include "sparse_triangular_solve.h"

static void run_kform_factor_forward(
    uint32_t m, uint32_t n, uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
    const uint32_t A_indptr[SPARSE_MAX_M + 1],
    const uint16_t A_indices[SPARSE_MAX_NNZ_A],
    const TFXP    A_values[SPARSE_MAX_NNZ_A],
    const TFXP    D[SPARSE_MAX_N],
    const uint32_t K_colptr_k[SPARSE_MAX_M + 1],
    const uint16_t K_rowidx_k[SPARSE_MAX_NNZ_K],
    const uint32_t K_colptr_f[SPARSE_MAX_M + 1],
    const uint16_t K_rowidx_f[SPARSE_MAX_NNZ_K],
    const uint32_t L_colptr_f[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc_f[SPARSE_L_ON_CHIP_MAX_NNZ],
    const uint32_t L_rowptr[SPARSE_MAX_M + 1],
    const uint16_t L_colidx_csr[SPARSE_L_ON_CHIP_MAX_NNZ],
    const uint32_t L_csr_pos[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    L_values_csc[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    L_values_csr[SPARSE_L_ON_CHIP_MAX_NNZ],
    TFXP    Dv[SPARSE_MAX_M],
    TFXP    Dv_inv[SPARSE_MAX_M],
    const uint32_t L_colptr_fwd[SPARSE_MAX_M + 1],
    const uint16_t L_rowidx_csc_fwd[SPARSE_L_ON_CHIP_MAX_NNZ],
    const TFXP    b[SPARSE_MAX_M],
    TFXP          z[SPARSE_MAX_M],
    uint32_t &kform_count,
    uint32_t &factor_count,
    uint32_t &forward_count)
{
  #pragma HLS DATAFLOW
  hls::stream<TFXP> k_col_stream;
  #pragma HLS STREAM variable=k_col_stream depth=4096
  #pragma HLS BIND_STORAGE variable=k_col_stream type=fifo impl=bram

  hls::stream<TFXP> l_col_stream;
  #pragma HLS STREAM variable=l_col_stream depth=4096
  #pragma HLS BIND_STORAGE variable=l_col_stream type=fifo impl=bram

  sparse_kform_stream_hw(m, n, nnz_A, nnz_K,
                         A_indptr, A_indices, A_values,
                         D,
                         K_colptr_k, K_rowidx_k,
                         k_col_stream,
                         kform_count);

  sparse_factor_stream_hw(m, nnz_K, nnz_L,
                          K_colptr_f, K_rowidx_f, k_col_stream,
                          L_colptr_f, L_rowidx_csc_f,
                          L_rowptr, L_colidx_csr, L_csr_pos,
                          L_values_csc, L_values_csr, Dv, Dv_inv,
                          l_col_stream,
                          factor_count);

  sparse_forward_solve_stream_hw(m, nnz_L,
                                 L_colptr_fwd, L_rowidx_csc_fwd,
                                 l_col_stream,
                                 b, z,
                                 forward_count);
}

void SparseSolve(TFXP_WIRE *input, TFXP_WIRE *output,
                 uint32_t m, uint32_t n,
                 uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
                 uint32_t mode,
                 uint32_t *kform_iters, uint32_t *factor_iters,
                 uint32_t *triangular_iters)
{
#pragma HLS INTERFACE s_axilite port=m
#pragma HLS INTERFACE s_axilite port=n
#pragma HLS INTERFACE s_axilite port=nnz_A
#pragma HLS INTERFACE s_axilite port=nnz_K
#pragma HLS INTERFACE s_axilite port=nnz_L
#pragma HLS INTERFACE s_axilite port=mode
#pragma HLS INTERFACE s_axilite port=kform_iters
#pragma HLS INTERFACE s_axilite port=factor_iters
#pragma HLS INTERFACE s_axilite port=triangular_iters
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE m_axi port=input  offset=slave bundle=master1 \
  num_read_outstanding=32 max_read_burst_length=256 \
  num_write_outstanding=32 depth=4000000
#pragma HLS INTERFACE m_axi port=output offset=slave bundle=master1 \
  num_write_outstanding=32 depth=SPARSE_MAX_M

  // ---- On-chip arrays ----
  static uint32_t A_indptr_loc[SPARSE_MAX_M + 1];
  static uint16_t A_indices_loc[SPARSE_MAX_NNZ_A];
  static TFXP    A_values_loc[SPARSE_MAX_NNZ_A];
  static TFXP    D_loc[SPARSE_MAX_N];
  #pragma HLS BIND_STORAGE variable=A_indices_loc type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=A_values_loc  type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=A_indptr_loc  type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=D_loc         type=ram_t2p impl=bram

  static uint32_t K_colptr_loc[SPARSE_MAX_M + 1];
  static uint16_t K_rowidx_loc[SPARSE_MAX_NNZ_K];
  static uint32_t K_colptr_loc_f[SPARSE_MAX_M + 1];
  static uint16_t K_rowidx_loc_f[SPARSE_MAX_NNZ_K];
  #pragma HLS BIND_STORAGE variable=K_rowidx_loc   type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=K_colptr_loc   type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=K_rowidx_loc_f type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=K_colptr_loc_f type=ram_t2p impl=bram

  static uint32_t L_colptr_loc[SPARSE_MAX_M + 1];
  static uint32_t L_rowptr_loc[SPARSE_MAX_M + 1];
  static uint16_t L_rowidx_csc_loc[SPARSE_L_ON_CHIP_MAX_NNZ];
  static uint16_t L_colidx_csr_loc[SPARSE_L_ON_CHIP_MAX_NNZ];
  static uint32_t L_csr_pos_loc[SPARSE_L_ON_CHIP_MAX_NNZ];
  static TFXP    L_values_csc_loc[SPARSE_L_ON_CHIP_MAX_NNZ];
  static TFXP    L_values_csr_loc[SPARSE_L_ON_CHIP_MAX_NNZ];
  static uint32_t L_colptr_loc_fwd[SPARSE_MAX_M + 1];
  static uint16_t L_rowidx_csc_loc_fwd[SPARSE_L_ON_CHIP_MAX_NNZ];
  #pragma HLS BIND_STORAGE variable=L_colptr_loc      type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_rowptr_loc      type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_rowidx_csc_loc  type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_colidx_csr_loc  type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_csr_pos_loc     type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_values_csc_loc  type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=L_values_csr_loc  type=ram_t2p impl=uram
  #pragma HLS BIND_STORAGE variable=L_colptr_loc_fwd     type=ram_t2p impl=bram
  #pragma HLS BIND_STORAGE variable=L_rowidx_csc_loc_fwd type=ram_t2p impl=bram

  static TFXP Dv_loc[SPARSE_MAX_M];
  static TFXP Dv_inv_loc[SPARSE_MAX_M];
  TFXP b_loc[SPARSE_MAX_M];
  TFXP z_loc[SPARSE_MAX_M];
  TFXP dy_loc[SPARSE_MAX_M];
  #pragma HLS ARRAY_PARTITION variable=Dv_loc     cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS ARRAY_PARTITION variable=Dv_inv_loc cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS ARRAY_PARTITION variable=b_loc      cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS ARRAY_PARTITION variable=z_loc      cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS ARRAY_PARTITION variable=dy_loc     cyclic factor=SPARSE_UNROLL dim=1
  #pragma HLS BIND_STORAGE variable=Dv_loc     type=ram_2p impl=lutram
  #pragma HLS BIND_STORAGE variable=Dv_inv_loc type=ram_2p impl=lutram
  #pragma HLS BIND_STORAGE variable=b_loc      type=ram_2p impl=lutram
  #pragma HLS BIND_STORAGE variable=z_loc      type=ram_2p impl=lutram
  #pragma HLS BIND_STORAGE variable=dy_loc     type=ram_2p impl=lutram

  uint32_t off = 0;
  uint32_t m_plus_1 = m + 1;

  bool load_pat   = (mode == MODE_SETUP);
  bool load_dyn   = (mode == MODE_SOLVE);   // D, b
  bool do_compute = (mode == MODE_SOLVE);

  if (load_pat) {
    LOAD_A_INDPTR: for (uint32_t i = 0; i < m_plus_1; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=2 max=SPARSE_MAX_M+1
    #pragma HLS PIPELINE II=1
      A_indptr_loc[i] = (uint32_t)(int64_t)input[off + i];
    }
  }
  off += m_plus_1;

  if (load_pat) {
    LOAD_A_INDICES: for (uint32_t i = 0; i < nnz_A; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_NNZ_A
    #pragma HLS PIPELINE II=1
      A_indices_loc[i] = (uint16_t)(int64_t)input[off + i];
    }
  }
  off += nnz_A;

  if (load_pat) {
    LOAD_A_VALUES: for (uint32_t i = 0; i < nnz_A; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_NNZ_A
    #pragma HLS PIPELINE II=1
      A_values_loc[i] = input[off + i];
    }
  }
  off += nnz_A;

  if (load_dyn) {
    LOAD_D: for (uint32_t i = 0; i < n; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_N
    #pragma HLS PIPELINE II=1
      D_loc[i] = input[off + i];
    }
  }
  off += n;

  if (load_pat) {
    LOAD_K_COLPTR: for (uint32_t i = 0; i < m_plus_1; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=2 max=SPARSE_MAX_M+1
    #pragma HLS PIPELINE II=1
      uint32_t v = (uint32_t)(int64_t)input[off + i];
      K_colptr_loc[i]   = v;
      K_colptr_loc_f[i] = v;
    }
  }
  off += m_plus_1;

  if (load_pat) {
    LOAD_K_ROWIDX: for (uint32_t i = 0; i < nnz_K; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_NNZ_K
    #pragma HLS PIPELINE II=1
      uint16_t v = (uint16_t)(int64_t)input[off + i];
      K_rowidx_loc[i]   = v;
      K_rowidx_loc_f[i] = v;
    }
  }
  off += nnz_K;

  if (load_pat) {
    LOAD_L_COLPTR: for (uint32_t i = 0; i < m_plus_1; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=2 max=SPARSE_MAX_M+1
    #pragma HLS PIPELINE II=1
      uint32_t v = (uint32_t)(int64_t)input[off + i];
      L_colptr_loc[i]     = v;
      L_colptr_loc_fwd[i] = v;
    }
  }
  off += m_plus_1;

  if (load_pat) {
    LOAD_L_ROWIDX: for (uint32_t i = 0; i < nnz_L; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_L_ON_CHIP_MAX_NNZ
    #pragma HLS PIPELINE II=1
      uint16_t v = (uint16_t)(int64_t)input[off + i];
      L_rowidx_csc_loc[i]     = v;
      L_rowidx_csc_loc_fwd[i] = v;
    }
  }
  off += nnz_L;

  if (load_pat) {
    LOAD_L_ROWPTR: for (uint32_t i = 0; i < m_plus_1; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=2 max=SPARSE_MAX_M+1
    #pragma HLS PIPELINE II=1
      L_rowptr_loc[i] = (uint32_t)(int64_t)input[off + i];
    }
  }
  off += m_plus_1;

  if (load_pat) {
    LOAD_L_COLIDX_CSR: for (uint32_t i = 0; i < nnz_L; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_L_ON_CHIP_MAX_NNZ
    #pragma HLS PIPELINE II=1
      L_colidx_csr_loc[i] = (uint16_t)(int64_t)input[off + i];
    }
  }
  off += nnz_L;

  if (load_pat) {
    LOAD_L_CSR_POS: for (uint32_t i = 0; i < nnz_L; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_L_ON_CHIP_MAX_NNZ
    #pragma HLS PIPELINE II=1
      L_csr_pos_loc[i] = (uint32_t)(int64_t)input[off + i];
    }
  }
  off += nnz_L;

  if (load_dyn) {
    LOAD_B: for (uint32_t i = 0; i < m; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
    #pragma HLS PIPELINE II=1
      b_loc[i] = input[off + i];
    }
  }

  uint32_t kform_count = 0;
  uint32_t factor_count = 0;
  uint32_t triangular_count = 0;

  if (do_compute) {
    uint32_t forward_count = 0;
    run_kform_factor_forward(m, n, nnz_A, nnz_K, nnz_L,
                             A_indptr_loc, A_indices_loc, A_values_loc,
                             D_loc,
                             K_colptr_loc,   K_rowidx_loc,
                             K_colptr_loc_f, K_rowidx_loc_f,
                             L_colptr_loc, L_rowidx_csc_loc,
                             L_rowptr_loc, L_colidx_csr_loc, L_csr_pos_loc,
                             L_values_csc_loc, L_values_csr_loc,
                             Dv_loc, Dv_inv_loc,
                             L_colptr_loc_fwd, L_rowidx_csc_loc_fwd,
                             b_loc, z_loc,
                             kform_count, factor_count, forward_count);

    uint32_t back_count = 0;
    sparse_back_solve_hw(m, nnz_L,
                         L_colptr_loc, L_rowidx_csc_loc, L_values_csc_loc,
                         Dv_inv_loc, z_loc, dy_loc,
                         back_count);
    triangular_count = forward_count + back_count;

    WRITE_DY: for (uint32_t i = 0; i < m; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=1 max=SPARSE_MAX_M
    #pragma HLS PIPELINE II=1
      output[i] = dy_loc[i];
    }
  }

  *kform_iters      = kform_count;
  *factor_iters     = factor_count;
  *triangular_iters = triangular_count;
}
