// SW sparse IPM driver: same loop as lp_ipm_sparse_hw.cpp, but the per-iter
// solve runs on the ARM CPU via KFormFactorSolve_SparseSW (same algorithm as
// the FPGA, float64) — the fairness baseline for the FPGA.

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "opt.h"
#include "lp_ipm_sparse.h"
#include "sparse_sw_ref.h"

// linalg.c is compiled by g++ under the Makefile.
void csr_spmv  (const Csr *A, const double *x, double *y);
void csr_spmv_t(const Csr *A, const double *y, double *x);
double vec_norm_inf(int n, const double *a);
double vec_dot(int n, const double *a, const double *b);
void   vec_set(int n, double *a, double v);
void   vec_copy(int n, double *dst, const double *src);

static double now_ms_local(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1.0e6;
}

static double step_to_positive_local(int n, const double *v, const double *dv, double alpha) {
  double a = 1.0;
  for (int i = 0; i < n; i++) {
    if (dv[i] < 0.0) {
      double cand = -alpha * v[i] / dv[i];
      if (cand < a) a = cand;
    }
  }
  if (a > 1.0) a = 1.0;
  if (a < 0.0) a = 0.0;
  return a;
}

// KFormFactorSolve_SparseSW takes int32 index arrays; IpmSymbolic uses u32/u16
// (fixture-native). Widen once per solve, amortised over the IPM iters.
static void widen_to_int32(int32_t *dst, const uint32_t *src, size_t n) {
  for (size_t i = 0; i < n; i++) dst[i] = (int32_t)src[i];
}
static void widen16_to_int32(int32_t *dst, const uint16_t *src, size_t n) {
  for (size_t i = 0; i < n; i++) dst[i] = (int32_t)src[i];
}

Result lp_solve_ipm_sparse_sw(const LPStd *M, const LPParams *p,
                              const IpmSymbolic *sym)
{
  const int m = M->m;
  const int n = M->n;

  Result r;
  r.status = OPT_MAXIT;
  r.iters = 0; r.obj = 0.0; r.prim_inf = 0.0; r.dual_inf = 0.0;
  memset(&r.prof, 0, sizeof(Profile));
  r.x = (double*)calloc((size_t)n, sizeof(double));
  if (!r.x) { r.status = OPT_NUMERR; return r; }

  // IPM working vectors
  double *x  = (double*)malloc((size_t)n * sizeof(double));
  double *s  = (double*)malloc((size_t)n * sizeof(double));
  double *y  = (double*)malloc((size_t)m * sizeof(double));
  double *rp = (double*)malloc((size_t)m * sizeof(double));
  double *rd = (double*)malloc((size_t)n * sizeof(double));
  double *Ax = (double*)malloc((size_t)m * sizeof(double));
  double *Aty= (double*)malloc((size_t)n * sizeof(double));
  double *D  = (double*)malloc((size_t)n * sizeof(double));
  double *t  = (double*)malloc((size_t)n * sizeof(double));
  double *rhs= (double*)malloc((size_t)m * sizeof(double));
  double *dy = (double*)malloc((size_t)m * sizeof(double));
  double *dx = (double*)malloc((size_t)n * sizeof(double));
  double *ds = (double*)malloc((size_t)n * sizeof(double));

  // KFormFactorSolve_SparseSW workspace (one allocation per IPM solve).
  int32_t *A_indptr_i  = (int32_t*)malloc((size_t)(m + 1)    * sizeof(int32_t));
  int32_t *A_indices_i = (int32_t*)malloc((size_t)sym->nnz_A * sizeof(int32_t));
  int32_t *K_colptr_i  = (int32_t*)malloc((size_t)(m + 1)    * sizeof(int32_t));
  int32_t *K_rowidx_i  = (int32_t*)malloc((size_t)sym->nnz_K * sizeof(int32_t));
  int32_t *L_colptr_i  = (int32_t*)malloc((size_t)(m + 1)    * sizeof(int32_t));
  int32_t *L_rowidx_i  = (int32_t*)malloc((size_t)sym->nnz_L * sizeof(int32_t));
  int32_t *L_rowptr_i  = (int32_t*)malloc((size_t)(m + 1)    * sizeof(int32_t));
  int32_t *L_cic_i     = (int32_t*)malloc((size_t)sym->nnz_L * sizeof(int32_t));
  int32_t *L_csc_pos_i = (int32_t*)malloc((size_t)sym->nnz_L * sizeof(int32_t));
  double  *K_values_d  = (double*) malloc((size_t)sym->nnz_K * sizeof(double));
  double  *L_values_d  = (double*) malloc((size_t)sym->nnz_L * sizeof(double));
  double  *Dv_d        = (double*) malloc((size_t)m          * sizeof(double));
  double  *w_d         = (double*) malloc((size_t)m          * sizeof(double));
  int32_t *flag_i      = (int32_t*)malloc((size_t)m          * sizeof(int32_t));

  if (!x||!s||!y||!rp||!rd||!Ax||!Aty||!D||!t||!rhs||!dy||!dx||!ds||
      !A_indptr_i||!A_indices_i||!K_colptr_i||!K_rowidx_i||!L_colptr_i||
      !L_rowidx_i||!L_rowptr_i||!L_cic_i||!L_csc_pos_i||
      !K_values_d||!L_values_d||!Dv_d||!w_d||!flag_i) {
    r.status = OPT_NUMERR; goto cleanup;
  }

  // Widen u32/u16 fixture index arrays to int32 once (KFormFactorSolve_SparseSW signature).
  widen_to_int32  (A_indptr_i, sym->A_indptr,    (size_t)(m + 1));
  widen16_to_int32(A_indices_i, sym->A_indices,   sym->nnz_A);
  widen_to_int32  (K_colptr_i, sym->K_colptr,    (size_t)(m + 1));
  widen16_to_int32(K_rowidx_i, sym->K_rowidx,    sym->nnz_K);
  widen_to_int32  (L_colptr_i, sym->L_colptr,    (size_t)(m + 1));
  widen16_to_int32(L_rowidx_i, sym->L_rowidx_csc, sym->nnz_L);
  widen_to_int32  (L_rowptr_i, sym->L_rowptr,    (size_t)(m + 1));
  widen16_to_int32(L_cic_i,    sym->L_colidx_csr, sym->nnz_L);
  widen_to_int32  (L_csc_pos_i, sym->L_csc_pos,   sym->nnz_L);

  vec_set(n, x, 1.0);
  vec_set(m, y, 0.0);
  {
    double cmin = M->c[0];
    for (int j = 1; j < n; j++) if (M->c[j] < cmin) cmin = M->c[j];
    for (int j = 0; j < n; j++) s[j] = M->c[j] - cmin + 1.0;
  }

  {
    double t0_total = now_ms_local();

    for (int it = 0; it < p->max_iter; it++) {
      double t0, t1;
      r.iters = it + 1;

      t0 = now_ms_local();
      csr_spmv(&M->A, x, Ax);
      for (int i = 0; i < m; i++) rp[i] = Ax[i] - M->b[i];
      t1 = now_ms_local(); r.prof.spmv_ms += (t1 - t0);

      t0 = now_ms_local();
      csr_spmv_t(&M->A, y, Aty);
      t1 = now_ms_local(); r.prof.spmv_t_ms += (t1 - t0);

      t0 = now_ms_local();
      for (int j = 0; j < n; j++) rd[j] = Aty[j] + s[j] - M->c[j];
      double mu = vec_dot(n, x, s) / (double)n;
      r.prim_inf = vec_norm_inf(m, rp);
      r.dual_inf = vec_norm_inf(n, rd);
      t1 = now_ms_local(); r.prof.vecops_ms += (t1 - t0);

      if (p->conv_log) {
        double obj_cur = vec_dot(n, M->c, x);
        fprintf(p->conv_log, "%s,%s,%d,%.6e,%.6e,%.6e,%.6e\n",
                p->conv_fixture ? p->conv_fixture : "?",
                p->conv_solver ? p->conv_solver : "?",
                r.iters, r.prim_inf, r.dual_inf, mu, obj_cur);
      }

      if (r.prim_inf < p->tol && r.dual_inf < p->tol && mu < p->tol) {
        r.status = OPT_OK; break;
      }

      t0 = now_ms_local();
      for (int j = 0; j < n; j++) D[j] = x[j] / s[j];
      for (int j = 0; j < n; j++) {
        double sinv_rc = x[j] - (p->sigma * mu) / s[j];
        t[j] = sinv_rc - D[j] * rd[j];
      }
      csr_spmv(&M->A, t, Ax);
      for (int i = 0; i < m; i++) rhs[i] = -rp[i] + Ax[i];
      t1 = now_ms_local(); r.prof.other_ms += (t1 - t0);

      // SW solve: kform + factor + triangular all in C++ float64.
      t0 = now_ms_local();
      int sw_status = KFormFactorSolve_SparseSW(
          (uint32_t)m, (uint32_t)n, sym->nnz_K, sym->nnz_L,
          A_indptr_i, A_indices_i, sym->A_values,
          D, rhs,
          K_colptr_i, K_rowidx_i,
          L_colptr_i, L_rowidx_i,
          L_rowptr_i, L_cic_i, L_csc_pos_i,
          K_values_d, L_values_d, Dv_d,
          w_d, flag_i, dy);
      t1 = now_ms_local(); r.prof.dsolve_ms += (t1 - t0);
      // sw_status == -1 means a non-positive pivot was clamped; same
      // numerical guard as the FPGA. dy is still well-defined.
      (void)sw_status;

      t0 = now_ms_local();
      csr_spmv_t(&M->A, dy, Aty);
      t1 = now_ms_local(); r.prof.spmv_t_ms += (t1 - t0);

      t0 = now_ms_local();
      for (int j = 0; j < n; j++) {
        double sinv_rc = x[j] - (p->sigma * mu) / s[j];
        dx[j] = -sinv_rc + D[j] * rd[j] + D[j] * Aty[j];
        ds[j] = -rd[j] - Aty[j];
      }
      double ap = step_to_positive_local(n, x, dx, p->alpha);
      double ad = step_to_positive_local(n, s, ds, p->alpha);
      double a  = (ap < ad) ? ap : ad;
      for (int j = 0; j < n; j++) x[j] += a * dx[j];
      for (int j = 0; j < n; j++) s[j] += a * ds[j];
      for (int i = 0; i < m; i++) y[i] += a * dy[i];
      t1 = now_ms_local(); r.prof.other_ms += (t1 - t0);
    }

    r.prof.total_ms = now_ms_local() - t0_total;
  }

  vec_copy(n, r.x, x);
  r.obj = vec_dot(n, M->c, r.x);

cleanup:
  free(x); free(s); free(y);
  free(rp); free(rd); free(Ax); free(Aty);
  free(D); free(t); free(rhs); free(dy); free(dx); free(ds);
  free(A_indptr_i); free(A_indices_i);
  free(K_colptr_i); free(K_rowidx_i);
  free(L_colptr_i); free(L_rowidx_i);
  free(L_rowptr_i); free(L_cic_i); free(L_csc_pos_i);
  free(K_values_d); free(L_values_d); free(Dv_d);
  free(w_d); free(flag_i);
  return r;
}
