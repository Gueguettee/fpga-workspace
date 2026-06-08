#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "opt.h"
#include "utils.h"

/*
  lp_ipm.c

  Minimal primal-dual interior-point method (IPM) for standard-form LP:

      minimize   c^T x
      subject to A x = b
                 x >= 0

  Variables (standard primal-dual form):
    x : primal variables (>=0)
    y : dual variables for equality constraints
    s : dual slacks (>=0) for x>=0

  KKT conditions:
    Ax = b
    A^T y + s = c
    X S e = 0  (complementarity)
    x,s >= 0

  IPM relaxes complementarity to:
    X S e = sigma * mu * e
  and uses Newton steps.

  In this minimal implementation:
  - We build a dense A once (from CSR) for simplicity.
  - We form normal equations: K = A * diag(D) * A^T where D = x./s
  - Solve K dy = rhs (dense_solve baseline)
  - Recover dx, ds, then take a step that keeps x,s positive.

  ⚠️ Important: We assume a strictly-feasible start x=1 is feasible.
  The provided testbench constructs b = A*1 so x=1 is feasible.
*/

static double step_to_positive(int n, const double *v, const double *dv, double alpha) {
  // Find max step a in [0,1] such that v + a*dv remains positive.
  // alpha (e.g. 0.99) keeps strictly positive: v + a*dv >= (1-alpha)*v
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
  // Ad is row-major m*n, assumed zeroed by caller
  for (int i = 0; i < A->m; i++) {
    for (int k = A->row_ptr[i]; k < A->row_ptr[i+1]; k++) {
      Ad[i*A->n + A->col_ind[k]] = A->val[k];
    }
  }
}

Result lp_solve_ipm(const LPStd *M, const LPParams *p) {
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

  // Working vectors
  double *x  = (double*)malloc((size_t)n * sizeof(double));
  double *s  = (double*)malloc((size_t)n * sizeof(double));
  double *y  = (double*)malloc((size_t)m * sizeof(double));
  double *rp = (double*)malloc((size_t)m * sizeof(double));
  double *rd = (double*)malloc((size_t)n * sizeof(double));
  double *Ax = (double*)malloc((size_t)m * sizeof(double));
  double *Aty= (double*)malloc((size_t)n * sizeof(double));
  double *D  = (double*)malloc((size_t)n * sizeof(double)); // x ./ s
  double *t  = (double*)malloc((size_t)n * sizeof(double));
  double *rhs= (double*)malloc((size_t)m * sizeof(double));
  double *dy = (double*)malloc((size_t)m * sizeof(double));
  double *dx = (double*)malloc((size_t)n * sizeof(double));
  double *ds = (double*)malloc((size_t)n * sizeof(double));
  double *K  = (double*)malloc((size_t)m * (size_t)m * sizeof(double));
  double *Ad = (double*)calloc((size_t)m * (size_t)n, sizeof(double));

  if (!x||!s||!y||!rp||!rd||!Ax||!Aty||!D||!t||!rhs||!dy||!dx||!ds||!K||!Ad) {
    r.status = OPT_NUMERR;
    goto cleanup;
  }

  {
  // Build dense A once (keeps code minimal; later you can replace with sparse construction)
  csr_to_dense(&M->A, Ad);

  // Initialization
  // - x = 1 (strictly positive)
  // - y = 0
  // - s positive derived from c (to avoid starting at s=0)
  vec_set(n, x, 1.0);
  vec_set(m, y, 0.0);

  double cmin = M->c[0];
  for (int j = 1; j < n; j++) if (M->c[j] < cmin) cmin = M->c[j];
  for (int j = 0; j < n; j++) s[j] = M->c[j] - cmin + 1.0;

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

    // Stop when primal residual, dual residual, and complementarity are small.
    if (r.prim_inf < p->tol && r.dual_inf < p->tol && mu < p->tol) {
      r.status = OPT_OK;
      break;
    }

    // D = x ./ s
    t0 = now_ms();
    for (int j = 0; j < n; j++) D[j] = x[j] / s[j];

    // Form rhs:
    // rc = x*s - sigma*mu  (elementwise)
    // S^{-1} rc = x - sigma*mu*(1/s)
    // t = (S^{-1} rc) - D*rd
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

    // Build K = A*diag(D)*A^T (dense m x m)
    t0 = now_ms();
    for (int i = 0; i < m*m; i++) K[i] = 0.0;
    for (int i = 0; i < m; i++) {
      for (int k2 = 0; k2 < m; k2++) {
        double sum = 0.0;
        for (int j = 0; j < n; j++) {
          double aij = Ad[i*n + j];
          double akj = Ad[k2*n + j];
          if (aij == 0.0 || akj == 0.0) continue;
          sum += aij * D[j] * akj;
        }
        K[i*m + k2] = sum;
      }
    }
    t1 = now_ms();
    r.prof.kform_ms += (t1 - t0);

    // Solve K dy = rhs
    t0 = now_ms();
    double *Kcopy = (double*)malloc((size_t)m*(size_t)m*sizeof(double));
    if (!Kcopy) { r.status = OPT_NUMERR; break; }
    memcpy(Kcopy, K, (size_t)m*(size_t)m*sizeof(double));
    int ok = dense_solve(m, Kcopy, rhs, dy);
    free(Kcopy);
    t1 = now_ms();
    r.prof.dsolve_ms += (t1 - t0);
    if (ok != 0) { r.status = OPT_NUMERR; break; }

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

  vec_copy(n, r.x, x);
  r.obj = vec_dot(n, M->c, r.x);
  }

cleanup:
  free(x); free(s); free(y);
  free(rp); free(rd); free(Ax); free(Aty);
  free(D); free(t); free(rhs);
  free(dy); free(dx); free(ds);
  free(K); free(Ad);
  return r;
}

void result_free(Result *r) {
  if (!r) return;
  free(r->x);
  r->x = NULL;
}
