#ifndef LP_IPM_SPARSE_H
#define LP_IPM_SPARSE_H

// Shared API for the sparse IPM drivers (HW and SW); only the per-iter solve
// differs (FPGA SparseSolve vs SW KFormFactorSolve_SparseSW). Orderings:
// A_perm = A[P,:], b permuted; c/x/s original; y/dy/rp/rhs permuted.

#include <stdint.h>
#include "opt.h"
#include "fxp_utils.h"

class CSparseSolveProxy;

// Pre-computed K and L symbolic patterns, plus A in CSR (variable-ordered).
// Loaded once from the SPLI fixture; identical across all IPM iterations.
typedef struct {
  uint32_t nnz_A, nnz_K, nnz_L;
  // CSR A (permuted)
  const uint32_t *A_indptr;       // m + 1
  const uint16_t *A_indices;      // nnz_A
  const double  *A_values;        // nnz_A — float64 for SW path; HW packs to FXP
  // K symbolic
  const uint32_t *K_colptr;       // m + 1
  const uint16_t *K_rowidx;       // nnz_K
  // L symbolic (CSC + CSR dual view)
  const uint32_t *L_colptr;       // m + 1
  const uint16_t *L_rowidx_csc;   // nnz_L
  const uint32_t *L_rowptr;       // m + 1
  const uint16_t *L_colidx_csr;   // nnz_L
  const uint32_t *L_csc_pos;      // nnz_L (inverse of L_csr_pos)
  const uint32_t *L_csr_pos;      // nnz_L
} IpmSymbolic;

// DMA-mapped buffers needed by SparseSolve_HW. Allocated once by the caller
// (see lpIpmSparseTestbench's InitDevice) and reused across IPM iters and
// across fixtures.
typedef struct {
  TFXP     *inputHW;
  TFXP     *outputHW;
} IpmHwBuffers;

// Pack the (pattern + A_values) section of inputHW once per fixture. After
// this, only D and b need to be written before each MODE_SOLVE call.
void pack_ipm_static_inputs(TFXP *inputHW,
                            uint32_t m, uint32_t n,
                            uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
                            const uint32_t *A_indptr,  const uint16_t *A_indices,
                            const double  *A_values,
                            const uint32_t *K_colptr, const uint16_t *K_rowidx,
                            const uint32_t *L_colptr, const uint16_t *L_rowidx_csc,
                            const uint32_t *L_rowptr, const uint16_t *L_colidx_csr,
                            const uint32_t *L_csr_pos,
                            uint32_t *off_D_out, uint32_t *off_b_out);

// HW IPM: each iter calls SparseSolve_HW(MODE_SOLVE) on the FPGA.
Result lp_solve_ipm_sparse_hw(const LPStd *M, const LPParams *p,
                              const IpmSymbolic *sym,
                              CSparseSolveProxy *solver,
                              const IpmHwBuffers *bufs);

// SW IPM: each iter calls KFormFactorSolve_SparseSW on the ARM CPU.
// Same algorithm in C++ doubles — fairness baseline for the FPGA.
Result lp_solve_ipm_sparse_sw(const LPStd *M, const LPParams *p,
                              const IpmSymbolic *sym);

#endif // LP_IPM_SPARSE_H
