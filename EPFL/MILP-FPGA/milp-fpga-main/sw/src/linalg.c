#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "opt.h"

/*
  linalg.c

  Minimal linear algebra for testbenching.

  Key functions:
  - csr_spmv:  sparse matrix-vector multiply
  - csr_spmv_t: sparse transpose matvec

  These are GREAT FPGA kernels:
  - regular loops
  - easy to pipeline
  - naturally streamable (CSR row-wise)

  dense_solve is CPU-only baseline.
*/

void csr_spmv(const Csr *A, const double *x, double *y) {
  for (int i = 0; i < A->m; i++) {
    double s = 0.0;
    for (int k = A->row_ptr[i]; k < A->row_ptr[i+1]; k++) {
      s += A->val[k] * x[A->col_ind[k]];
    }
    y[i] = s;
  }
}

void csr_spmv_t(const Csr *A, const double *y, double *x) {
  for (int j = 0; j < A->n; j++) x[j] = 0.0;
  for (int i = 0; i < A->m; i++) {
    for (int k = A->row_ptr[i]; k < A->row_ptr[i+1]; k++) {
      x[A->col_ind[k]] += A->val[k] * y[i];
    }
  }
}

double vec_norm_inf(int n, const double *a) {
  double m = 0.0;
  for (int i = 0; i < n; i++) {
    double v = fabs(a[i]);
    if (v > m) m = v;
  }
  return m;
}

double vec_dot(int n, const double *a, const double *b) {
  double s = 0.0;
  for (int i = 0; i < n; i++) s += a[i] * b[i];
  return s;
}

void vec_set(int n, double *a, double v) {
  for (int i = 0; i < n; i++) a[i] = v;
}

void vec_copy(int n, double *dst, const double *src) {
  memcpy(dst, src, (size_t)n * sizeof(double));
}

int dense_solve(int n, double *K, const double *rhs, double *x) {
  /*
    Gaussian elimination with partial pivoting.
    - K overwritten in-place
    - rhs not overwritten
    - x output

    This is just a correctness baseline.
    For FPGA:
      - If m fixed and small: use Cholesky/LDL
      - If m varies/large: use iterative CG / MINRES
  */
  double *b = (double*)malloc((size_t)n * sizeof(double));
  if (!b) return -1;
  memcpy(b, rhs, (size_t)n * sizeof(double));

  for (int i = 0; i < n; i++) x[i] = 0.0;

  for (int k = 0; k < n; k++) {
    int piv = k;
    double best = fabs(K[k*n + k]);
    for (int i = k+1; i < n; i++) {
      double v = fabs(K[i*n + k]);
      if (v > best) { best = v; piv = i; }
    }
    if (best < 1e-14) { free(b); return -2; }

    if (piv != k) {
      for (int j = k; j < n; j++) {
        double tmp = K[k*n + j];
        K[k*n + j] = K[piv*n + j];
        K[piv*n + j] = tmp;
      }
      double tb = b[k]; b[k] = b[piv]; b[piv] = tb;
    }

    double diag = K[k*n + k];
    for (int i = k+1; i < n; i++) {
      double f = K[i*n + k] / diag;
      K[i*n + k] = 0.0;
      for (int j = k+1; j < n; j++) {
        K[i*n + j] -= f * K[k*n + j];
      }
      b[i] -= f * b[k];
    }
  }

  for (int i = n-1; i >= 0; i--) {
    double s = b[i];
    for (int j = i+1; j < n; j++) s -= K[i*n + j] * x[j];
    x[i] = s / K[i*n + i];
  }

  free(b);
  return 0;
}
