#ifndef OPT_H
#define OPT_H
// LP + MILP testbed API. LP in standard form (min c^T x s.t. Ax=b, x>=0);
// MILP adds binary x_j in {0,1} via depth-first branch-and-bound (no cuts).
// FPGA entry points: csr_spmv, csr_spmv_t, dense_solve (CPU baseline).

#include <stdint.h>
#include <stdio.h>

typedef struct {
  int m, n, nnz;
  int *row_ptr;   // size m+1
  int *col_ind;   // size nnz
  double *val;    // size nnz
} Csr;

typedef struct {
  int m, n;
  Csr A;
  double *b;  // m
  double *c;  // n
} LPStd;

// MILP: same relaxation, but some variables are binary (0/1)
typedef struct {
  LPStd lp;
  int8_t *vtype; // n: 0=continuous, 2=binary
} MILPStd;

typedef enum {
  OPT_OK=0,
  OPT_INFEAS=1,
  OPT_UNBOUNDED=2,
  OPT_MAXIT=3,
  OPT_NUMERR=4
} OptStatus;

typedef struct {
  double spmv_ms;     // csr_spmv time
  double spmv_t_ms;   // csr_spmv_t time (both calls combined)
  double vecops_ms;   // vec_dot, vec_norm_inf, scalar loops
  double kform_ms;    // K = A*diag(D)*A^T formation (0 when FPGA does kform+dsolve)
  double dsolve_ms;   // dense_solve (FPGA: includes kform+dsolve)
  double conv_ms;     // FXP conversion overhead (0 for CPU-only path)
  double other_ms;    // step computation, updates, etc.
  double total_ms;    // wall-clock total
} Profile;

typedef struct {
  OptStatus status;
  int iters;       // for LP: IPM iterations; for MILP: last LP iters (kept minimal)
  double obj;      // objective value of returned solution
  double prim_inf; // ||Ax-b||_inf
  double dual_inf; // ||A^T y + s - c||_inf (for LP; MILP returns 0s here)
  double *x;       // size n (allocated by solver; must free via result_free)
  Profile prof;    // per-kernel timing breakdown (LP only)
} Result;

typedef struct {
  // If conv_log non-NULL, impl appends one row per iter:
  // fixture,solver,iter,prim_inf,dual_inf,mu,obj. Caller owns the FILE*
  // (impl does not fclose); zero-init disables logging.
  int max_iter;
  double tol;
  double sigma;
  double alpha;
  FILE       *conv_log;
  const char *conv_fixture;
  const char *conv_solver;
} LPParams;

typedef struct {
  /*
    Minimal B&B parameters.
    - max_nodes, max_depth bound the search.
    - int_tol: integrality tolerance for binaries.
    - prune_eps: prune if LP bound >= incumbent - prune_eps
  */
  int max_nodes;
  int max_depth;
  double int_tol;
  double prune_eps;
} MILPParams;

void csr_spmv(const Csr *A, const double *x, double *y);    // y = A x
void csr_spmv_t(const Csr *A, const double *y, double *x);  // x = A^T y
double vec_norm_inf(int n, const double *a);
double vec_dot(int n, const double *a, const double *b);
void vec_set(int n, double *a, double v);
void vec_copy(int n, double *dst, const double *src);

// Dense solve Kx = rhs (CPU baseline).
int dense_solve(int n, double *K, const double *rhs, double *x);

// ----- solvers -----
Result lp_solve_ipm(const LPStd *M, const LPParams *p);
Result milp_solve_bnb(const MILPStd *M, const LPParams *lp, const MILPParams *mp);
void result_free(Result *r);

#endif // OPT_H

