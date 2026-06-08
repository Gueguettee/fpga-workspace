/*
  lp_ipm_hw.cpp

  FPGA-accelerated version of lp_ipm.c.

  Identical to the CPU version except the kform+dsolve block is replaced
  with a single call to the DenseSolve FPGA IP which performs both
  K-formation and Gaussian elimination in fixed-point (Q9.23).

  FXP conversion overhead is profiled separately via prof.conv_ms.
*/

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// linalg.c and utils.c are compiled as C++ (g++ compiles .c files),
// so no extern "C" needed — they share C++ linkage.
#include "opt.h"
#include "utils.h"

#include "CAccelProxy.hpp"
#include "CDenseSolveProxy.hpp"
#include "fxp_utils.h"
#include "constants.h"

#include "opt_hw.h"

static double step_to_positive(int n, const double *v, const double *dv, double alpha) {
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

static void csr_to_dense(const Csr *A, double *Ad) {
  for (int i = 0; i < A->m; i++) {
    for (int k = A->row_ptr[i]; k < A->row_ptr[i+1]; k++) {
      Ad[i*A->n + A->col_ind[k]] = A->val[k];
    }
  }
}

Result lp_solve_ipm_hw(const LPStd *M, const LPParams *p,
                       CDenseSolveProxy *solver,
                       TFXP *inputHW, TFXP *outputHW) {
  const int m = M->m;
  const int n = M->n;

  Result r;
  r.status = OPT_MAXIT;
  r.iters = 0;
  r.obj = 0.0;
  r.prim_inf = 0.0;
  r.dual_inf = 0.0;
  memset(&r.prof, 0, sizeof(Profile));
  r.x = (double*)calloc((size_t)n, sizeof(double));
  if (!r.x) { r.status = OPT_NUMERR; return r; }

  // Check dimensions fit FPGA limits
  if (m > DENSE_MAX_M || n > DENSE_MAX_N) {
    printf("ERROR: m=%d or n=%d exceeds FPGA limits (%d, %d)\n",
           m, n, DENSE_MAX_M, DENSE_MAX_N);
    r.status = OPT_NUMERR;
    return r;
  }

  // Working vectors
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
  double *Ad = (double*)calloc((size_t)m * (size_t)n, sizeof(double));

  if (!x||!s||!y||!rp||!rd||!Ax||!Aty||!D||!t||!rhs||!dy||!dx||!ds||!Ad) {
    r.status = OPT_NUMERR;
    goto cleanup;
  }

  // Build dense A once and convert to FXP (sent to FPGA only on first iteration)
  csr_to_dense(&M->A, Ad);
  for (int i = 0; i < m; i++)
    for (int j = 0; j < n; j++)
      inputHW[i * n + j] = Double2Fxp(Ad[i * n + j]);

  // Initialization
  vec_set(n, x, 1.0);
  vec_set(m, y, 0.0);

  {
    double cmin = M->c[0];
    for (int j = 1; j < n; j++) if (M->c[j] < cmin) cmin = M->c[j];
    for (int j = 0; j < n; j++) s[j] = M->c[j] - cmin + 1.0;
  }

  {
    double t0_total = now_ms();

    for (int it = 0; it < p->max_iter; it++) {
      double t0, t1;
      r.iters = it + 1;

      // rp = A x - b
      t0 = now_ms();
      csr_spmv(&M->A, x, Ax);
      for (int i = 0; i < m; i++) rp[i] = Ax[i] - M->b[i];
      t1 = now_ms();
      r.prof.spmv_ms += (t1 - t0);

      // rd = A^T y + s - c
      t0 = now_ms();
      csr_spmv_t(&M->A, y, Aty);
      t1 = now_ms();
      r.prof.spmv_t_ms += (t1 - t0);

      // mu = (x^T s)/n
      t0 = now_ms();
      for (int j = 0; j < n; j++) rd[j] = Aty[j] + s[j] - M->c[j];
      double mu = vec_dot(n, x, s) / (double)n;

      r.prim_inf = vec_norm_inf(m, rp);
      r.dual_inf = vec_norm_inf(n, rd);
      t1 = now_ms();
      r.prof.vecops_ms += (t1 - t0);

      if (p->conv_log) {
        double obj_cur = vec_dot(n, M->c, x);
        fprintf(p->conv_log, "%s,%s,%d,%.6e,%.6e,%.6e,%.6e\n",
                p->conv_fixture ? p->conv_fixture : "?",
                p->conv_solver ? p->conv_solver : "?",
                r.iters, r.prim_inf, r.dual_inf, mu, obj_cur);
      }

      if (r.prim_inf < p->tol && r.dual_inf < p->tol && mu < p->tol) {
        r.status = OPT_OK;
        break;
      }

      // D = x ./ s, form t and rhs
      t0 = now_ms();
      for (int j = 0; j < n; j++) D[j] = x[j] / s[j];

      for (int j = 0; j < n; j++) {
        double sinv_rc = x[j] - (p->sigma * mu) / s[j];
        t[j] = sinv_rc - D[j] * rd[j];
      }

      // rhs = -rp + A*t
      for (int i = 0; i < m; i++) {
        double sum = 0.0;
        for (int j = 0; j < n; j++) sum += Ad[i*n + j] * t[j];
        rhs[i] = -rp[i] + sum;
      }
      t1 = now_ms();
      r.prof.other_ms += (t1 - t0);

      // ===== FPGA: kform + dsolve =====
      // Convert D, rhs from double to FXP (Ad already in buffer)
      t0 = now_ms();
      for (int j = 0; j < n; j++)
        inputHW[m * n + j] = Double2Fxp(D[j]);
      for (int i = 0; i < m; i++)
        inputHW[m * n + n + i] = Double2Fxp(rhs[i]);
      t1 = now_ms();
      r.prof.conv_ms += (t1 - t0);

      // FPGA execution: K-formation + solve
      // First iteration loads Ad into FPGA BRAM; subsequent iterations reuse it
      t0 = now_ms();
      uint32_t heightFlag = (uint32_t)m | ((it > 0) ? (1u << 16) : 0u);
      solver->DenseSolve_HW(inputHW, outputHW, (uint32_t)n, heightFlag);
      t1 = now_ms();
      r.prof.dsolve_ms += (t1 - t0);

      // Convert dy from FXP back to double
      t0 = now_ms();
      for (int i = 0; i < m; i++)
        dy[i] = Fxp2Double(outputHW[i]);
      t1 = now_ms();
      r.prof.conv_ms += (t1 - t0);
      // ===== END FPGA =====

      // Recover dx, ds
      t0 = now_ms();
      csr_spmv_t(&M->A, dy, Aty);
      t1 = now_ms();
      r.prof.spmv_t_ms += (t1 - t0);
      t0 = now_ms();
      for (int j = 0; j < n; j++) {
        double sinv_rc = x[j] - (p->sigma * mu) / s[j];
        dx[j] = -sinv_rc + D[j] * rd[j] + D[j] * Aty[j];
        ds[j] = -rd[j] - Aty[j];
      }

      double ap = step_to_positive(n, x, dx, p->alpha);
      double ad = step_to_positive(n, s, ds, p->alpha);
      double a = (ap < ad) ? ap : ad;

      for (int j = 0; j < n; j++) x[j] += a * dx[j];
      for (int j = 0; j < n; j++) s[j] += a * ds[j];
      for (int i = 0; i < m; i++) y[i] += a * dy[i];
      t1 = now_ms();
      r.prof.other_ms += (t1 - t0);
    }

    r.prof.total_ms = now_ms() - t0_total;
  }

  // output solution
  vec_copy(n, r.x, x);
  r.obj = vec_dot(n, M->c, r.x);

cleanup:
  free(x); free(s); free(y);
  free(rp); free(rd); free(Ax); free(Aty);
  free(D); free(t); free(rhs);
  free(dy); free(dx); free(ds);
  free(Ad);
  return r;
}
