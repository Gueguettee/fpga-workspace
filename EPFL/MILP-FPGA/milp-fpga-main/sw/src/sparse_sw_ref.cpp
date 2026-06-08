// SW sparse reference: simplicial up-looking LDL^T on K = A·diag(D)·A^T plus
// triangular solves. Direct port of python/sparse_solve/numeric_reference.py.
// b is permuted (A = A_perm); dy returned in the permuted ordering.
// Returns 0, or -1 if a non-positive pivot was clamped to 1.0 (mirrors
// sparse_factor.cpp:104).

#include "sparse_sw_ref.h"

int KFormFactorSolve_SparseSW(uint32_t m, uint32_t /*n*/,
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
                              double *dy)
{
  // 1) K_values: gather K[i,j] for each (i,j) in the K pattern via two-pointer
  //    intersection of A_perm rows i and j.
  for (uint32_t k = 0; k < nnz_K; k++) K_values[k] = 0.0;
  for (uint32_t j = 0; j < m; j++) {
    int32_t ja = A_indptr[j];
    int32_t jb = A_indptr[j + 1];
    for (int32_t p = K_colptr[j]; p < K_colptr[j + 1]; p++) {
      int32_t i = K_rowidx[p];
      int32_t ia = A_indptr[i];
      int32_t ib = A_indptr[i + 1];
      double s = 0.0;
      int32_t a = ia, b_it = ja;
      while (a < ib && b_it < jb) {
        int32_t ca = A_indices[a];
        int32_t cb = A_indices[b_it];
        if (ca == cb)      { s += A_values[a] * D[ca] * A_values[b_it]; a++; b_it++; }
        else if (ca < cb)  { a++; }
        else               { b_it++; }
      }
      K_values[p] = s;
    }
  }

  // 2) Up-looking LDL^T factor. flag/w form a sparse accumulator per column j.
  for (uint32_t i = 0; i < m; i++) { flag[i] = -1; w[i] = 0.0; Dv[i] = 0.0; }
  for (uint32_t k = 0; k < nnz_L; k++) L_values_csc[k] = 0.0;

  bool pivot_clamped = false;
  for (uint32_t j = 0; j < m; j++) {
    double diag = 0.0;
    for (int32_t p = K_colptr[j]; p < K_colptr[j + 1]; p++) {
      int32_t i = K_rowidx[p];
      double v = K_values[p];
      if ((uint32_t)i == j) { diag = v; }
      else                  { w[i] = v; flag[i] = (int32_t)j; }
    }

    int32_t rs = L_rowptr[j];
    int32_t re = L_rowptr[j + 1];
    for (int32_t q = rs; q < re; q++) {
      int32_t k = L_colidx_csr[q];
      if ((uint32_t)k >= j) continue;
      double l_jk = L_values_csc[L_csc_pos[q]];
      double u    = l_jk * Dv[k];
      diag -= l_jk * u;
      for (int32_t q2 = L_colptr[k]; q2 < L_colptr[k + 1]; q2++) {
        int32_t r = L_rowidx_csc[q2];
        if ((uint32_t)r <= j) continue;
        if (flag[r] != (int32_t)j) { w[r] = 0.0; flag[r] = (int32_t)j; }
        w[r] -= L_values_csc[q2] * u;
      }
    }

    if (diag <= 0.0) { diag = 1.0; pivot_clamped = true; }
    Dv[j] = diag;
    double inv_diag = 1.0 / diag;

    for (int32_t p = L_colptr[j]; p < L_colptr[j + 1]; p++) {
      int32_t r = L_rowidx_csc[p];
      if ((uint32_t)r == j) {
        L_values_csc[p] = 1.0;
      } else {
        double v = (flag[r] == (int32_t)j) ? w[r] : 0.0;
        L_values_csc[p] = v * inv_diag;
      }
    }
  }

  // 3) Solve L D L^T dy = b (forward, scale by D, back).
  for (uint32_t i = 0; i < m; i++) dy[i] = b[i];
  for (uint32_t j = 0; j < m; j++) {
    double zj = dy[j];
    for (int32_t p = L_colptr[j] + 1; p < L_colptr[j + 1]; p++) {
      dy[L_rowidx_csc[p]] -= L_values_csc[p] * zj;
    }
  }
  for (uint32_t j = 0; j < m; j++) dy[j] /= Dv[j];
  for (int32_t j = (int32_t)m - 1; j >= 0; j--) {
    double s = dy[j];
    for (int32_t p = L_colptr[j] + 1; p < L_colptr[j + 1]; p++) {
      s -= L_values_csc[p] * dy[L_rowidx_csc[p]];
    }
    dy[j] = s;
  }

  return pivot_clamped ? -1 : 0;
}
