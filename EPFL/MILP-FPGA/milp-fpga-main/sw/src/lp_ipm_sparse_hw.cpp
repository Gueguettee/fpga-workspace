// HW sparse IPM driver: per-iter K·dy = rhs runs on the FPGA SparseSolve
// kernel. Orderings: A/b permuted; x/s/c original; y/dy/rp permuted.
//
// Mode strategy: first call MODE_SETUP loads A + K/L patterns (cached on-chip
// + DDR); each IPM iter MODE_SOLVE writes only D and rhs, then kform → factor
// → triangular → dy.

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "opt.h"
#include "fxp_utils.h"
#include "CSparseSolveProxy.hpp"   // MODE_SETUP / MODE_SOLVE constants
#include "lp_ipm_sparse.h"         // shared API for HW + SW IPM drivers

// linalg.c is compiled by g++ under the Makefile (same pattern as
// sparseSolveTestbench.cpp). Both translation units use C++ name mangling,
// so no extern "C" is needed.
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

// Pack the static (pattern + A_values) half of the SparseSolve input buffer
// once per fixture. Layout follows sparse_solve.cpp:97-203 exactly.
//
// Returns: byte offset of D within inputHW (in TFXP units), and offset of b.
void pack_ipm_static_inputs(TFXP *inputHW,
                            uint32_t m, uint32_t n,
                            uint32_t nnz_A, uint32_t nnz_K, uint32_t nnz_L,
                            const uint32_t *A_indptr,  const uint16_t *A_indices,
                            const double  *A_values,
                            const uint32_t *K_colptr, const uint16_t *K_rowidx,
                            const uint32_t *L_colptr, const uint16_t *L_rowidx_csc,
                            const uint32_t *L_rowptr, const uint16_t *L_colidx_csr,
                            const uint32_t *L_csr_pos,
                            uint32_t *off_D_out, uint32_t *off_b_out)
{
  uint32_t off = 0;
  for (uint32_t i = 0; i < m + 1; i++) inputHW[off + i] = (TFXP)(int64_t)A_indptr[i];
  off += m + 1;
  for (uint32_t k = 0; k < nnz_A; k++) inputHW[off + k] = (TFXP)(int64_t)A_indices[k];
  off += nnz_A;
  for (uint32_t k = 0; k < nnz_A; k++) inputHW[off + k] = Double2Fxp(A_values[k]);
  off += nnz_A;
  *off_D_out = off;             // D slot
  off += n;
  for (uint32_t i = 0; i < m + 1; i++) inputHW[off + i] = (TFXP)(int64_t)K_colptr[i];
  off += m + 1;
  for (uint32_t k = 0; k < nnz_K; k++) inputHW[off + k] = (TFXP)(int64_t)K_rowidx[k];
  off += nnz_K;
  for (uint32_t i = 0; i < m + 1; i++) inputHW[off + i] = (TFXP)(int64_t)L_colptr[i];
  off += m + 1;
  for (uint32_t k = 0; k < nnz_L; k++) inputHW[off + k] = (TFXP)(int64_t)L_rowidx_csc[k];
  off += nnz_L;
  for (uint32_t i = 0; i < m + 1; i++) inputHW[off + i] = (TFXP)(int64_t)L_rowptr[i];
  off += m + 1;
  for (uint32_t k = 0; k < nnz_L; k++) inputHW[off + k] = (TFXP)(int64_t)L_colidx_csr[k];
  off += nnz_L;
  for (uint32_t k = 0; k < nnz_L; k++) inputHW[off + k] = (TFXP)(int64_t)L_csr_pos[k];
  off += nnz_L;
  *off_b_out = off;             // b slot
}

Result lp_solve_ipm_sparse_hw(const LPStd *M, const LPParams *p,
                              const IpmSymbolic *sym,
                              CSparseSolveProxy *solver,
                              const IpmHwBuffers *bufs)
{
  const int m = M->m;
  const int n = M->n;

  Result r;
  r.status = OPT_MAXIT;
  r.iters = 0; r.obj = 0.0; r.prim_inf = 0.0; r.dual_inf = 0.0;
  memset(&r.prof, 0, sizeof(Profile));
  r.x = (double*)calloc((size_t)n, sizeof(double));
  if (!r.x) { r.status = OPT_NUMERR; return r; }

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
  if (!x||!s||!y||!rp||!rd||!Ax||!Aty||!D||!t||!rhs||!dy||!dx||!ds) {
    r.status = OPT_NUMERR; goto cleanup;
  }

  // Pack the static (pattern + A_values) half of inputHW once. D and b slots
  // are written each IPM iteration before MODE_SOLVE.
  uint32_t off_D, off_b;
  pack_ipm_static_inputs(bufs->inputHW, (uint32_t)m, (uint32_t)n,
                         sym->nnz_A, sym->nnz_K, sym->nnz_L,
                         sym->A_indptr, sym->A_indices, sym->A_values,
                         sym->K_colptr, sym->K_rowidx,
                         sym->L_colptr, sym->L_rowidx_csc,
                         sym->L_rowptr, sym->L_colidx_csr,
                         sym->L_csr_pos,
                         &off_D, &off_b);

  // MODE_SETUP: writes patterns to on-chip + L_*_ddr backing buffers. D and
  // b in inputHW are uninitialised for this call but won't be read.
  {
    uint32_t st = solver->SparseSolve_HW(
        bufs->inputHW, bufs->outputHW,
        (uint32_t)m, (uint32_t)n, sym->nnz_A, sym->nnz_K, sym->nnz_L,
        CSparseSolveProxy::MODE_SETUP);
    if (st != 0) { r.status = OPT_NUMERR; goto cleanup; }
  }

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

      // rp = A x - b  (in permuted constraint space)
      t0 = now_ms_local();
      csr_spmv(&M->A, x, Ax);
      for (int i = 0; i < m; i++) rp[i] = Ax[i] - M->b[i];
      t1 = now_ms_local(); r.prof.spmv_ms += (t1 - t0);

      // rd = A^T y + s - c  (in variable space)
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

      // D = x ./ s ; t = S^{-1} rc - D rd ; rhs = -rp + A t
      t0 = now_ms_local();
      for (int j = 0; j < n; j++) D[j] = x[j] / s[j];
      for (int j = 0; j < n; j++) {
        double sinv_rc = x[j] - (p->sigma * mu) / s[j];
        t[j] = sinv_rc - D[j] * rd[j];
      }
      csr_spmv(&M->A, t, Ax);
      for (int i = 0; i < m; i++) rhs[i] = -rp[i] + Ax[i];
      t1 = now_ms_local(); r.prof.other_ms += (t1 - t0);

      // FXP-pack D and rhs into the SparseSolve input buffer
      t0 = now_ms_local();
      for (int j = 0; j < n; j++) bufs->inputHW[off_D + j] = Double2Fxp(D[j]);
      for (int i = 0; i < m; i++) bufs->inputHW[off_b + i] = Double2Fxp(rhs[i]);
      t1 = now_ms_local(); r.prof.conv_ms += (t1 - t0);

      // SparseSolve_HW MODE_SOLVE: kform → factor → triangular → dy in outputHW
      t0 = now_ms_local();
      uint32_t st = solver->SparseSolve_HW(
          bufs->inputHW, bufs->outputHW,
          (uint32_t)m, (uint32_t)n, sym->nnz_A, sym->nnz_K, sym->nnz_L,
          CSparseSolveProxy::MODE_SOLVE);
      t1 = now_ms_local(); r.prof.dsolve_ms += (t1 - t0);
      if (st != 0) { r.status = OPT_NUMERR; break; }

      t0 = now_ms_local();
      for (int i = 0; i < m; i++) dy[i] = Fxp2Double(bufs->outputHW[i]);
      t1 = now_ms_local(); r.prof.conv_ms += (t1 - t0);


      // Recover dx, ds and step
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

      // Q17.54-precision-induced divergence guard. The Q17.54 dy returned
      // by SparseSolve carries a small per-iter relative error (~1e-6
      // with cond(K)~1e6) which compounds over IPM iterations. At larger m
      // and after D spreads enough, x runs away. Bail out and report the
      // best-effort point — better than letting x reach 1e+9.
      if (vec_norm_inf(n, x) > 1e3) {
        r.status = OPT_NUMERR;
        break;
      }
    }

    r.prof.total_ms = now_ms_local() - t0_total;
  }

  vec_copy(n, r.x, x);
  r.obj = vec_dot(n, M->c, r.x);

cleanup:
  free(x); free(s); free(y);
  free(rp); free(rd); free(Ax); free(Aty);
  free(D); free(t); free(rhs);
  free(dy); free(dx); free(ds);
  return r;
}
