#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "opt.h"

/*
  milp_bnb.c

  Minimal depth-first Branch-and-Bound (B&B) for binary MILP.

  Problem:
    minimize   c^T x
    subject to A x = b
               x >= 0
               x_j in {0,1} for some variables

  Approach:
    - Solve LP relaxation (ignore integrality).
    - If solution is integer-feasible => incumbent.
    - Else pick a fractional binary var and branch:
        x_j = 0  OR  x_j = 1
    - Each node: we FIX some variables and solve a smaller LP.

  Minimal implementation choice:
    Instead of implementing general bounds constraints, we "fix variables"
    by removing them from the LP and adjusting b:
      If x_j fixed to 1: b := b - A[:,j]
      If x_j fixed to 0: nothing changes
    Then solve reduced LP in standard form again.

  This keeps the LP solver unchanged and the code small.
*/

typedef struct {
  int depth;
  // fixstate for each var: -1 free, 0 fixed to 0, 1 fixed to 1
  int8_t *fix;
} Node;

static int is_integer_feasible(const MILPStd *M, const double *x, double tol) {
  for (int j = 0; j < M->lp.n; j++) {
    if (M->vtype[j] == 2) {
      double v = x[j];
      if (fabs(v - 0.0) <= tol) continue;
      if (fabs(v - 1.0) <= tol) continue;
      return 0;
    }
  }
  return 1;
}

static int pick_branch_var(const MILPStd *M, const double *x, double tol) {
  // minimal: first fractional binary variable
  for (int j = 0; j < M->lp.n; j++) {
    if (M->vtype[j] != 2) continue;
    double v = x[j];
    if (fabs(v - 0.0) > tol && fabs(v - 1.0) > tol) return j;
  }
  return -1;
}

static void free_lp(LPStd *L) {
  free(L->A.row_ptr);
  free(L->A.col_ind);
  free(L->A.val);
  free(L->b);
  free(L->c);
}

static LPStd build_relaxation_fixed(
  const MILPStd *M, const int8_t *fix, int *map_old_to_new, int *new_n_out
) {
  const int m = M->lp.m;
  const int n = M->lp.n;

  // Build mapping from original vars to reduced vars
  int new_n = 0;
  for (int j = 0; j < n; j++) {
    if (fix[j] < 0) map_old_to_new[j] = new_n++;
    else map_old_to_new[j] = -1;
  }
  *new_n_out = new_n;

  // Dense A' for simplicity, then convert to CSR
  double *Ad = (double*)calloc((size_t)m*(size_t)new_n, sizeof(double));
  double *b2 = (double*)malloc((size_t)m * sizeof(double));
  double *c2 = (double*)malloc((size_t)new_n * sizeof(double));
  for (int i = 0; i < m; i++) b2[i] = M->lp.b[i];

  // Adjust b for fixed vars: b2 = b - sum_j A[:,j] * xj_fixed
  for (int i = 0; i < m; i++) {
    for (int k = M->lp.A.row_ptr[i]; k < M->lp.A.row_ptr[i+1]; k++) {
      int j = M->lp.A.col_ind[k];
      double a = M->lp.A.val[k];
      if (fix[j] == 1) {
        b2[i] -= a; // x_j=1
      } else if (fix[j] < 0) {
        int nj = map_old_to_new[j];
        Ad[i*new_n + nj] = a;
      }
      // if fix[j]==0, subtract 0 => nothing
    }
  }

  // Reduced c
  for (int j = 0; j < n; j++) {
    if (fix[j] < 0) c2[map_old_to_new[j]] = M->lp.c[j];
  }

  // Convert dense Ad to CSR
  int nnz = 0;
  for (int i = 0; i < m; i++)
    for (int j = 0; j < new_n; j++)
      if (Ad[i*new_n + j] != 0.0) nnz++;

  int *row_ptr = (int*)malloc((size_t)(m+1)*sizeof(int));
  int *col_ind = (int*)malloc((size_t)nnz*sizeof(int));
  double *val  = (double*)malloc((size_t)nnz*sizeof(double));

  int pos = 0;
  row_ptr[0] = 0;
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < new_n; j++) {
      double a = Ad[i*new_n + j];
      if (a != 0.0) {
        col_ind[pos] = j;
        val[pos] = a;
        pos++;
      }
    }
    row_ptr[i+1] = pos;
  }

  free(Ad);

  LPStd R;
  R.m = m; R.n = new_n;
  R.A.m = m; R.A.n = new_n; R.A.nnz = nnz;
  R.A.row_ptr = row_ptr;
  R.A.col_ind = col_ind;
  R.A.val = val;
  R.b = b2;
  R.c = c2;
  return R;
}

Result milp_solve_bnb(const MILPStd *M, const LPParams *lp, const MILPParams *mp) {
  const int n = M->lp.n;

  Result best;
  best.status = OPT_INFEAS;
  best.iters = 0;
  best.obj = INFINITY;
  best.prim_inf = 0.0;
  best.dual_inf = 0.0;
  best.x = (double*)calloc((size_t)n, sizeof(double));
  if (!best.x) { best.status = OPT_NUMERR; return best; }

  // DFS stack
  Node *stack = (Node*)malloc((size_t)mp->max_nodes * sizeof(Node));
  int top = 0;

  // root node: all vars free
  stack[top].depth = 0;
  stack[top].fix = (int8_t*)malloc((size_t)n * sizeof(int8_t));
  for (int j = 0; j < n; j++) stack[top].fix[j] = -1;
  top++;

  int *map = (int*)malloc((size_t)n * sizeof(int));
  if (!stack || !map) { best.status = OPT_NUMERR; return best; }

  int nodes = 0;

  while (top > 0 && nodes < mp->max_nodes) {
    Node node = stack[--top];
    nodes++;

    // Build reduced relaxation with fixed vars removed
    int new_n = 0;
    LPStd R = build_relaxation_fixed(M, node.fix, map, &new_n);

    // Solve LP relaxation
    Result rr = lp_solve_ipm(&R, lp);

    if (rr.status == OPT_OK) {
      // Objective contribution from fixed vars
      double obj_fixed = 0.0;
      for (int j = 0; j < n; j++) if (node.fix[j] == 1) obj_fixed += M->lp.c[j];

      double bound = obj_fixed + rr.obj;

      // Prune if cannot beat best incumbent
      if (bound < best.obj - mp->prune_eps) {
        // Lift solution back to full x
        double *xfull = (double*)calloc((size_t)n, sizeof(double));
        for (int j = 0; j < n; j++) {
          if (node.fix[j] == 0) xfull[j] = 0.0;
          else if (node.fix[j] == 1) xfull[j] = 1.0;
          else xfull[j] = rr.x[map[j]];
        }

        // If integer feasible => update incumbent
        if (is_integer_feasible(M, xfull, mp->int_tol)) {
          best.status = OPT_OK;
          best.obj = bound;
          memcpy(best.x, xfull, (size_t)n*sizeof(double));
        }
        // Else branch if depth allows
        else if (node.depth < mp->max_depth) {
          int br = pick_branch_var(M, xfull, mp->int_tol);
          if (br >= 0) {
            Node right;
            right.depth = node.depth + 1;
            right.fix = (int8_t*)malloc((size_t)n*sizeof(int8_t));
            memcpy(right.fix, node.fix, (size_t)n*sizeof(int8_t));
            right.fix[br] = 1;

            Node left;
            left.depth = node.depth + 1;
            left.fix = (int8_t*)malloc((size_t)n*sizeof(int8_t));
            memcpy(left.fix, node.fix, (size_t)n*sizeof(int8_t));
            left.fix[br] = 0;

            // Push in order so left explored first (DFS)
            if (top + 2 <= mp->max_nodes) {
              stack[top++] = right;
              stack[top++] = left;
            } else {
              free(right.fix);
              free(left.fix);
            }
          }
        }

        free(xfull);
      }
    }

    result_free(&rr);
    free_lp(&R);
    free(node.fix);

    (void)nodes; // kept minimal; add reporting if desired
  }

  free(stack);
  free(map);

  return best;
}
