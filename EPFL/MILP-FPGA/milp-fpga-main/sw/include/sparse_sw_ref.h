#ifndef SPARSE_SW_REF_H
#define SPARSE_SW_REF_H

#include <stdint.h>

// Direct port of python/sparse_solve/numeric_reference.py (same algorithm as
// the FPGA SparseSolve kernel, in C++ float64). Index arrays and b/dy are in
// the host symbolic phase's row-permuted ordering (A = A_perm).
//
// Returns 0 on success, -1 if a non-positive pivot was clamped to 1.0
// (mirrors the FPGA pivot guard at sparse_factor.cpp:104). Caller-allocated
// workspace:
//   K_values     [nnz_K]   K = A·diag(D)·Aᵀ values at K pattern
//   L_values_csc [nnz_L]   L's CSC values
//   Dv           [m]       diagonal
//   w            [m]       sparse-accumulator workspace
//   flag         [m]       column-j tag for sparse accumulator
//   dy           [m]       output
int KFormFactorSolve_SparseSW(
    uint32_t m, uint32_t n,
    uint32_t nnz_K, uint32_t nnz_L,
    const int32_t *A_indptr, const int32_t *A_indices,
    const double  *A_values,
    const double  *D, const double *b,
    const int32_t *K_colptr, const int32_t *K_rowidx,
    const int32_t *L_colptr, const int32_t *L_rowidx_csc,
    const int32_t *L_rowptr, const int32_t *L_colidx_csr,
    const int32_t *L_csc_pos,
    double *K_values, double *L_values_csc, double *Dv,
    double *w, int32_t *flag,
    double *dy);

#endif // SPARSE_SW_REF_H
