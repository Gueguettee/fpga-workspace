// On-board sparse-IPM benchmark: load SPLI fixtures, run three IPM drivers per
// fixture (HW SparseSolve, SW sparse same-algo, SW dense Gaussian for m<=256).
//
// The kform dy_expected golden does not apply here (D changes every iter), so
// correctness is verified by 3-way agreement on the final objective.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <time.h>

#include "CAccelProxy.hpp"
#include "CSparseSolveProxy.hpp"
#include "util.hpp"

#include "fxp_utils.h"
#include "constants.h"
#include "pmt_power_meter.h"
#include "opt.h"
#include "lp_ipm_sparse.h"
#include "measure_helpers.h"

// lp_ipm.c is compiled by g++ under the Makefile, so no extern "C".
Result lp_solve_ipm(const LPStd *M, const LPParams *p);   // dense baseline (lp_ipm.c)

#define SPARSE_SOLVE_HW_ADDR 0xA0000000
#define MAP_SIZE             (64 * 1024)

static const uint32_t FIX_MAGIC_IPM = 0x53504C49u;  // "SPLI"
static const uint32_t FIX_VERSION   = 1u;

// Buffer sizing matches sparseSolveTestbench.cpp.
#define MAX_INPUT_WORDS (4 * (SPARSE_MAX_M + 1) + 2 * SPARSE_MAX_NNZ_A         \
                         + SPARSE_MAX_N + SPARSE_MAX_NNZ_K                     \
                         + 3 * SPARSE_MAX_NNZ_L + SPARSE_MAX_M)
#define MAX_OUTPUT_WORDS SPARSE_MAX_M

// Scaling fixtures (l_T6..xl_T36) absent from older fixture trees, so
// load_ipm_fixture's "cannot find" error is benign for boards that haven't
// been re-deployed with the larger fixtures.
#define NUM_DEFAULT_FIXTURES 19
static const char *g_default_fixtures[NUM_DEFAULT_FIXTURES] = {
  "ipm_uc_micro_T6.bin",
  "ipm_uc_micro_T12.bin",
  "ipm_uc_xs_T6.bin",
  "ipm_uc_xs_T12.bin",
  "ipm_uc_xs_T24.bin",
  "ipm_uc_s_T12.bin",
  "ipm_uc_s_T24.bin",
  "ipm_uc_m_T12.bin",
  "ipm_uc_m_T24.bin",
  "ipm_uc_l_T6.bin",
  "ipm_uc_l_T12.bin",
  "ipm_uc_l_T18.bin",
  "ipm_uc_l_T24.bin",
  "ipm_uc_l_T28.bin",
  "ipm_uc_l_T30.bin",
  "ipm_uc_l_T36.bin",
  "ipm_uc_l_T48.bin",
  "ipm_uc_xl_T24.bin",
  "ipm_uc_xl_T36.bin",
};

static const uint32_t SW_DENSE_MAX_M = 256;

// CMA Device-type memory rejects NEON 128-bit stores from glibc memset on
// aarch64 (same trick the dense + sparse testbenches use).
static void ZeroFill32(void *dst, size_t bytes) {
  volatile uint32_t *p = (volatile uint32_t *)dst;
  size_t count = bytes / sizeof(uint32_t);
  for (size_t i = 0; i < count; ++i) p[i] = 0;
}

static int read_exact(FILE *f, void *buf, size_t n) {
  return fread(buf, 1, n, f) == n ? 0 : -1;
}

static FILE *open_fixture(const char *name) {
  static const char *prefixes[] = {
    "../hw/sparse_solve/fixtures/",
    "./fixtures/",
    "../fixtures/",
    "/home/xilinx/milp-fpga/hw/sparse_solve/fixtures/",
  };
  char buf[1024];
  for (size_t i = 0; i < sizeof(prefixes) / sizeof(prefixes[0]); i++) {
    snprintf(buf, sizeof(buf), "%s%s", prefixes[i], name);
    FILE *f = fopen(buf, "rb");
    if (f) {
      printf("  (loaded from %s)\n", buf);
      return f;
    }
  }
  return NULL;
}

static int read_uint16_padded(FILE *f, uint16_t *dst, uint32_t n) {
  if (read_exact(f, dst, sizeof(uint16_t) * (size_t)n)) return -1;
  size_t pad = (-(sizeof(uint16_t) * (size_t)n)) & 3;
  if (pad) {
    char dummy[4];
    if (read_exact(f, dummy, pad)) return -1;
  }
  return 0;
}

// All fixture pattern arrays + double-form A values + b + c. Allocated once
// per fixture, freed at the end of each iteration.
struct FixtureData {
  uint32_t m, n, nnz_A, nnz_K, nnz_L;

  // Pattern arrays in fixture-native widths (u32/u16).
  uint32_t *A_indptr;       // m + 1
  uint16_t *A_indices;      // nnz_A
  double   *A_values;       // nnz_A (converted from int128 Q17.54 on load)
  uint32_t *K_colptr;       // m + 1
  uint16_t *K_rowidx;       // nnz_K
  uint32_t *L_colptr;       // m + 1
  uint16_t *L_rowidx_csc;   // nnz_L
  uint32_t *L_rowptr;       // m + 1
  uint16_t *L_colidx_csr;   // nnz_L
  uint32_t *L_csc_pos;      // nnz_L
  uint32_t *L_csr_pos;      // nnz_L
  double   *b;              // m  (LP RHS, permuted)
  double   *c;              // n  (LP cost)

  // Int-form CSR view of A for the IPM's csr_spmv (linalg.c uses int).
  int *A_row_ptr_i;         // m + 1
  int *A_col_ind_i;         // nnz_A
};

static void free_fixture(FixtureData *fx) {
  free(fx->A_indptr); free(fx->A_indices); free(fx->A_values);
  free(fx->K_colptr); free(fx->K_rowidx);
  free(fx->L_colptr); free(fx->L_rowidx_csc);
  free(fx->L_rowptr); free(fx->L_colidx_csr);
  free(fx->L_csc_pos); free(fx->L_csr_pos);
  free(fx->b); free(fx->c);
  free(fx->A_row_ptr_i); free(fx->A_col_ind_i);
  memset(fx, 0, sizeof(*fx));
}

static int load_ipm_fixture(const char *name, FixtureData *fx) {
  FILE *f = open_fixture(name);
  if (!f) { printf("  ERROR: cannot find fixture %s\n", name); return -1; }
  memset(fx, 0, sizeof(*fx));

  uint32_t magic, version, m, n, nnz_A, nnz_K, nnz_L;
  if (read_exact(f, &magic, 4) || read_exact(f, &version, 4) ||
      read_exact(f, &m, 4)     || read_exact(f, &n, 4) ||
      read_exact(f, &nnz_A, 4) || read_exact(f, &nnz_K, 4) ||
      read_exact(f, &nnz_L, 4)) {
    fclose(f); return -1;
  }
  if (magic != FIX_MAGIC_IPM || version != FIX_VERSION) {
    printf("  ERROR: bad magic 0x%08x or version %u\n", magic, version);
    fclose(f); return -1;
  }
  if (m > SPARSE_MAX_M || n > SPARSE_MAX_N || nnz_A > SPARSE_MAX_NNZ_A ||
      nnz_K > SPARSE_MAX_NNZ_K || nnz_L > SPARSE_MAX_NNZ_L) {
    printf("  ERROR: fixture exceeds SPARSE_MAX_*\n");
    fclose(f); return -1;
  }
  fx->m = m; fx->n = n;
  fx->nnz_A = nnz_A; fx->nnz_K = nnz_K; fx->nnz_L = nnz_L;

  // Allocate pattern arrays.
  fx->A_indptr     = (uint32_t*)malloc((size_t)(m + 1) * sizeof(uint32_t));
  fx->A_indices    = (uint16_t*)malloc((size_t)nnz_A   * sizeof(uint16_t));
  fx->A_values     = (double*)  malloc((size_t)nnz_A   * sizeof(double));
  fx->K_colptr     = (uint32_t*)malloc((size_t)(m + 1) * sizeof(uint32_t));
  fx->K_rowidx     = (uint16_t*)malloc((size_t)nnz_K   * sizeof(uint16_t));
  fx->L_colptr     = (uint32_t*)malloc((size_t)(m + 1) * sizeof(uint32_t));
  fx->L_rowidx_csc = (uint16_t*)malloc((size_t)nnz_L   * sizeof(uint16_t));
  fx->L_rowptr     = (uint32_t*)malloc((size_t)(m + 1) * sizeof(uint32_t));
  fx->L_colidx_csr = (uint16_t*)malloc((size_t)nnz_L   * sizeof(uint16_t));
  fx->L_csc_pos    = (uint32_t*)malloc((size_t)nnz_L   * sizeof(uint32_t));
  fx->L_csr_pos    = (uint32_t*)malloc((size_t)nnz_L   * sizeof(uint32_t));
  fx->b            = (double*)  malloc((size_t)m       * sizeof(double));
  fx->c            = (double*)  malloc((size_t)n       * sizeof(double));
  fx->A_row_ptr_i  = (int*)     malloc((size_t)(m + 1) * sizeof(int));
  fx->A_col_ind_i  = (int*)     malloc((size_t)nnz_A   * sizeof(int));
  if (!fx->A_indptr||!fx->A_indices||!fx->A_values||
      !fx->K_colptr||!fx->K_rowidx||
      !fx->L_colptr||!fx->L_rowidx_csc||
      !fx->L_rowptr||!fx->L_colidx_csr||
      !fx->L_csc_pos||!fx->L_csr_pos||
      !fx->b||!fx->c||!fx->A_row_ptr_i||!fx->A_col_ind_i) {
    printf("  ERROR: fixture alloc failed\n"); fclose(f); free_fixture(fx); return -1;
  }

  if (read_exact(f, fx->A_indptr, sizeof(uint32_t) * (size_t)(m + 1))) goto bad;
  if (read_uint16_padded(f, fx->A_indices, nnz_A)) goto bad;
  for (uint32_t k = 0; k < nnz_A; k++) {
    int64_t lo, hi;
    if (read_exact(f, &lo, sizeof(lo))) goto bad;
    if (read_exact(f, &hi, sizeof(hi))) goto bad;
    (void)hi;
    fx->A_values[k] = Fxp2Double((TFXP)lo);
  }
  if (read_exact(f, fx->K_colptr, sizeof(uint32_t) * (size_t)(m + 1))) goto bad;
  if (read_uint16_padded(f, fx->K_rowidx, nnz_K)) goto bad;
  if (read_exact(f, fx->L_colptr, sizeof(uint32_t) * (size_t)(m + 1))) goto bad;
  if (read_uint16_padded(f, fx->L_rowidx_csc, nnz_L)) goto bad;
  if (read_exact(f, fx->L_rowptr, sizeof(uint32_t) * (size_t)(m + 1))) goto bad;
  if (read_uint16_padded(f, fx->L_colidx_csr, nnz_L)) goto bad;
  if (read_exact(f, fx->L_csc_pos, sizeof(uint32_t) * (size_t)nnz_L)) goto bad;
  if (read_exact(f, fx->L_csr_pos, sizeof(uint32_t) * (size_t)nnz_L)) goto bad;
  if (read_exact(f, fx->b, sizeof(double) * (size_t)m)) goto bad;
  if (read_exact(f, fx->c, sizeof(double) * (size_t)n)) goto bad;

  // int-form CSR view for csr_spmv (the linalg.c API expects int).
  for (uint32_t i = 0; i < m + 1; i++) fx->A_row_ptr_i[i] = (int)fx->A_indptr[i];
  for (uint32_t k = 0; k < nnz_A; k++) fx->A_col_ind_i[k] = (int)fx->A_indices[k];

  fclose(f);
  return 0;
bad:
  printf("  ERROR: fixture read failed\n"); fclose(f); free_fixture(fx); return -1;
}

static void make_LPStd(const FixtureData *fx, LPStd *M) {
  M->m = (int)fx->m;
  M->n = (int)fx->n;
  M->A.m = M->m;
  M->A.n = M->n;
  M->A.nnz = (int)fx->nnz_A;
  M->A.row_ptr = fx->A_row_ptr_i;
  M->A.col_ind = fx->A_col_ind_i;
  M->A.val = fx->A_values;
  M->b = fx->b;
  M->c = fx->c;
}

static void make_IpmSymbolic(const FixtureData *fx, IpmSymbolic *sym) {
  sym->nnz_A = fx->nnz_A;
  sym->nnz_K = fx->nnz_K;
  sym->nnz_L = fx->nnz_L;
  sym->A_indptr     = fx->A_indptr;
  sym->A_indices    = fx->A_indices;
  sym->A_values     = fx->A_values;
  sym->K_colptr     = fx->K_colptr;
  sym->K_rowidx     = fx->K_rowidx;
  sym->L_colptr     = fx->L_colptr;
  sym->L_rowidx_csc = fx->L_rowidx_csc;
  sym->L_rowptr     = fx->L_rowptr;
  sym->L_colidx_csr = fx->L_colidx_csr;
  sym->L_csc_pos    = fx->L_csc_pos;
  sym->L_csr_pos    = fx->L_csr_pos;
}

struct PerFixtureResult {
  const char *name;
  uint32_t m, n, nnz_K, nnz_L;
  // HW IPM
  double hw_total_s; int hw_iters; double hw_solve_ms_avg; double hw_obj;
  double hw_prim_inf, hw_dual_inf; OptStatus hw_status;
  double hw_energy_j;
  // SW sparse IPM
  double swsp_total_s; int swsp_iters; double swsp_solve_ms_avg; double swsp_obj;
  double swsp_prim_inf, swsp_dual_inf; OptStatus swsp_status;
  double swsp_energy_j;
  // SW dense IPM (only for m ≤ SW_DENSE_MAX_M)
  bool swd_run;
  double swd_total_s; int swd_iters; double swd_obj;
  double swd_prim_inf, swd_dual_inf; OptStatus swd_status;
  double swd_energy_j;
  // 3-way agreement
  double obj_rel_gap_hw_vs_swsp;
  double obj_rel_gap_hw_vs_swd;
};

static const char *status_str(OptStatus s) {
  switch (s) {
    case OPT_OK: return "OK";
    case OPT_INFEAS: return "INFEAS";
    case OPT_UNBOUNDED: return "UNBOUND";
    case OPT_MAXIT: return "MAXITER";
    case OPT_NUMERR: return "NUMERR";
  }
  return "?";
}

static bool InitDevice(CSparseSolveProxy &solver, IpmHwBuffers *bufs) {
  printf("\nThis program requires the SparseSolve bitstream to be loaded.\n");
  printf("Run with sudo.\n\n");
  if (solver.Open(SPARSE_SOLVE_HW_ADDR, MAP_SIZE) != CAccelProxy::OK) {
    printf("Error mapping device at 0x%08X\n", SPARSE_SOLVE_HW_ADDR);
    return false;
  }
  printf("Device mapped at 0x%08X\n", SPARSE_SOLVE_HW_ADDR);

  bufs->inputHW    = (TFXP*)solver.AllocDMACompatible(MAX_INPUT_WORDS  * sizeof(TFXP));
  bufs->outputHW   = (TFXP*)solver.AllocDMACompatible(MAX_OUTPUT_WORDS * sizeof(TFXP));
  if (!bufs->inputHW||!bufs->outputHW) {
    printf("Error allocating DMA memory\n"); return false;
  }
  printf("DMA buffers allocated.\n");
  return true;
}

int main(int argc, char **argv) {
  CSparseSolveProxy solver(/*Logging=*/false);
  IpmHwBuffers bufs;
  memset(&bufs, 0, sizeof(bufs));
  if (!InitDevice(solver, &bufs)) return 1;

  PmtPowerMeter pwr;
  bool powerOk = pwr.Probe();
  if (powerOk) printf("PMT: %zu rail(s) detected\n", pwr.Rails().size());
  else         printf("PMT: no rails detected — energy columns will be 0\n");

  // Fixture list: argv overrides default. Names are normalised like the
  // sparse_solve testbench.
  const char *fixture_list[NUM_DEFAULT_FIXTURES + 16];
  static char arg_bufs[16][256];
  int num_fixtures = 0;
  if (argc > 1) {
    int max_argv = (argc - 1 > 16) ? 16 : (argc - 1);
    for (int i = 0; i < max_argv; i++) {
      const char *raw = argv[1 + i];
      if (strncmp(raw, "ipm_", 4) != 0)
        snprintf(arg_bufs[i], sizeof(arg_bufs[i]), "ipm_%s", raw);
      else
        snprintf(arg_bufs[i], sizeof(arg_bufs[i]), "%s", raw);
      size_t len = strlen(arg_bufs[i]);
      if (len < 4 || strcmp(arg_bufs[i] + len - 4, ".bin") != 0)
        snprintf(arg_bufs[i] + len, sizeof(arg_bufs[i]) - len, ".bin");
      fixture_list[num_fixtures++] = arg_bufs[i];
    }
  } else {
    for (int i = 0; i < NUM_DEFAULT_FIXTURES; i++)
      fixture_list[num_fixtures++] = g_default_fixtures[i];
  }
  printf("Running %d fixture(s).\n", num_fixtures);

  PerFixtureResult *res = (PerFixtureResult*)calloc(num_fixtures, sizeof(PerFixtureResult));
  bool any_fail = false;

  LPParams params;
  params.max_iter = 50;
  params.tol      = 1e-4;          // Q17.54 dynamic range struggles to hit 1e-6 at large m.
  params.sigma    = 0.1;
  params.alpha    = 0.99;
  params.conv_log = NULL;          // set per (fixture, solver) below
  params.conv_fixture = NULL;
  params.conv_solver  = NULL;

  // Convergence log: one row per IPM iteration across all (fixture, solver)
  // pairs. Built for the Q-format precision sweep (Item 5).
  FILE *conv_csv = fopen("../data/lp_ipm_sparse_convergence.csv", "w");
  if (conv_csv) {
    fprintf(conv_csv, "fixture,solver,iter,prim_inf,dual_inf,mu,obj\n");
    fflush(conv_csv);
  } else {
    fprintf(stderr, "warning: could not open ../data/lp_ipm_sparse_convergence.csv (no logging)\n");
  }

  for (int fi = 0; fi < num_fixtures; fi++) {
    const char *name = fixture_list[fi];
    printf("\n=== fixture %s ===\n", name);

    FixtureData fx;
    if (load_ipm_fixture(name, &fx)) {
      // Fixture missing or unreadable — leave row zero-filled, skip without
      // failing the run. Lets newer testbench binaries coexist with older
      // fixture trees that don't have the scaling fixtures yet.
      res[fi].name = name;
      printf("  (skipped — fixture not available on this board)\n");
      continue;
    }
    printf("  m=%u n=%u nnz_A=%u nnz_K=%u nnz_L=%u\n",
           fx.m, fx.n, fx.nnz_A, fx.nnz_K, fx.nnz_L);

    LPStd M; make_LPStd(&fx, &M);
    IpmSymbolic sym; make_IpmSymbolic(&fx, &sym);

    res[fi].name = name;
    res[fi].m = fx.m; res[fi].n = fx.n;
    res[fi].nnz_K = fx.nnz_K; res[fi].nnz_L = fx.nnz_L;

    // ---- HW IPM ---------------------------------------------------------
    params.conv_log     = conv_csv;
    params.conv_fixture = name;
    params.conv_solver  = "sparse_hw";
    Result rh = {};
    double cum_hw_s = 0.0;
    uint32_t reps_hw = measure_adaptive(pwr, [&](uint32_t rep) {
      if (rep > 0) { result_free(&rh); params.conv_log = nullptr; }
      ZeroFill32(bufs.outputHW, MAX_OUTPUT_WORDS * sizeof(TFXP));
      rh = lp_solve_ipm_sparse_hw(&M, &params, &sym, &solver, &bufs);
    }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_hw_s);
    if (conv_csv) fflush(conv_csv);
    res[fi].hw_total_s        = cum_hw_s / reps_hw;
    res[fi].hw_iters          = rh.iters;
    res[fi].hw_solve_ms_avg   = rh.iters > 0 ? rh.prof.dsolve_ms / rh.iters : 0.0;
    res[fi].hw_obj            = rh.obj;
    res[fi].hw_prim_inf       = rh.prim_inf;
    res[fi].hw_dual_inf       = rh.dual_inf;
    res[fi].hw_status         = rh.status;
    res[fi].hw_energy_j       = pwr.TotalEnergyJ() / reps_hw;
    printf("  (HW   IPM) status=%s iters=%d obj=%.6e prim=%.2e dual=%.2e  "
           "total %.3f s [%u reps]  solve_avg %.2f ms  energy %.3f J\n",
           status_str(rh.status), rh.iters, rh.obj, rh.prim_inf, rh.dual_inf,
           res[fi].hw_total_s, reps_hw, res[fi].hw_solve_ms_avg, res[fi].hw_energy_j);

    double *x_hw_snr = (double*)malloc((size_t)M.n * sizeof(double));
    if (x_hw_snr && rh.x) vec_copy(M.n, x_hw_snr, rh.x);
    result_free(&rh);
    if (rh.status != OPT_OK) any_fail = true;

    // ---- SW sparse IPM (same algo on ARM) -------------------------------
    params.conv_log     = conv_csv;
    params.conv_fixture = name;
    params.conv_solver  = "sparse_sw";
    Result rs = {};
    double cum_sp_s = 0.0;
    uint32_t reps_sp = measure_adaptive(pwr, [&](uint32_t rep) {
      if (rep > 0) { result_free(&rs); params.conv_log = nullptr; }
      rs = lp_solve_ipm_sparse_sw(&M, &params, &sym);
    }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_sp_s);
    if (conv_csv) fflush(conv_csv);
    res[fi].swsp_total_s      = cum_sp_s / reps_sp;
    res[fi].swsp_iters        = rs.iters;
    res[fi].swsp_solve_ms_avg = rs.iters > 0 ? rs.prof.dsolve_ms / rs.iters : 0.0;
    res[fi].swsp_obj          = rs.obj;
    res[fi].swsp_prim_inf     = rs.prim_inf;
    res[fi].swsp_dual_inf     = rs.dual_inf;
    res[fi].swsp_status       = rs.status;
    res[fi].swsp_energy_j     = pwr.TotalEnergyJ() / reps_sp;
    printf("  (SW sp IPM) status=%s iters=%d obj=%.6e prim=%.2e dual=%.2e  "
           "total %.3f s [%u reps]  solve_avg %.2f ms  energy %.3f J\n",
           status_str(rs.status), rs.iters, rs.obj, rs.prim_inf, rs.dual_inf,
           res[fi].swsp_total_s, reps_sp, res[fi].swsp_solve_ms_avg, res[fi].swsp_energy_j);
    // End-to-end SNR
    {
      double sumSqRef = 0.0, sumSqErr = 0.0;
      for (int j = 0; j < M.n; j++) {
        double ref = rs.x ? rs.x[j] : 0.0;
        double err = ref - (x_hw_snr ? x_hw_snr[j] : 0.0);
        sumSqRef += ref * ref;
        sumSqErr += err * err;
      }
      double snr_db = (sumSqErr > 0.0) ? 10.0 * log10(sumSqRef / sumSqErr) : INFINITY;
      printf("  (SNR hw-vs-sw) %.1f dB\n", snr_db);
    }
    free(x_hw_snr);
    result_free(&rs);

    // ---- SW dense IPM (m ≤ DENSE_MAX_M only) ---------------------------
    res[fi].swd_run = (fx.m <= SW_DENSE_MAX_M);
    if (res[fi].swd_run) {
      params.conv_log     = conv_csv;
      params.conv_fixture = name;
      params.conv_solver  = "dense_sw";
      Result rd = {};
      double cum_d_s = 0.0;
      uint32_t reps_d = measure_adaptive(pwr, [&](uint32_t rep) {
        if (rep > 0) { result_free(&rd); params.conv_log = nullptr; }
        rd = lp_solve_ipm(&M, &params);
      }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_d_s);
      if (conv_csv) fflush(conv_csv);
      res[fi].swd_total_s  = cum_d_s / reps_d;
      res[fi].swd_iters    = rd.iters;
      res[fi].swd_obj      = rd.obj;
      res[fi].swd_prim_inf = rd.prim_inf;
      res[fi].swd_dual_inf = rd.dual_inf;
      res[fi].swd_status   = rd.status;
      res[fi].swd_energy_j = pwr.TotalEnergyJ() / reps_d;
      printf("  (SW d  IPM) status=%s iters=%d obj=%.6e prim=%.2e dual=%.2e  "
             "total %.3f s [%u reps]  energy %.3f J\n",
             status_str(rd.status), rd.iters, rd.obj, rd.prim_inf, rd.dual_inf,
             res[fi].swd_total_s, reps_d, res[fi].swd_energy_j);
      result_free(&rd);
    } else {
      printf("  (SW d  IPM) SKIPPED (m=%u > %u)\n", fx.m, SW_DENSE_MAX_M);
    }

    // 3-way obj agreement
    double swsp_abs = fabs(res[fi].swsp_obj);
    res[fi].obj_rel_gap_hw_vs_swsp =
        (swsp_abs > 1e-12) ? fabs(res[fi].hw_obj - res[fi].swsp_obj) / swsp_abs
                           : fabs(res[fi].hw_obj - res[fi].swsp_obj);
    if (res[fi].swd_run) {
      double swd_abs = fabs(res[fi].swd_obj);
      res[fi].obj_rel_gap_hw_vs_swd =
          (swd_abs > 1e-12) ? fabs(res[fi].hw_obj - res[fi].swd_obj) / swd_abs
                            : fabs(res[fi].hw_obj - res[fi].swd_obj);
    }
    printf("  obj_rel_gap HW vs SW_sp = %.2e", res[fi].obj_rel_gap_hw_vs_swsp);
    if (res[fi].swd_run)
      printf("    HW vs SW_d = %.2e", res[fi].obj_rel_gap_hw_vs_swd);
    printf("\n");

    free_fixture(&fx);
  }

  // Summary table.
  printf("\n========================================================== SUMMARY ==========================================================\n");
  printf(" %-22s %5s %5s %7s %7s %4s %9s %9s %4s %9s %9s %4s %9s %9s\n",
         "fixture", "m", "n", "nnz_K", "nnz_L",
         "HW_it", "HW_s", "HW_solve_ms",
         "Sp_it", "Sp_s", "Sp_solve_ms",
         "Dn_it", "Dn_s", "obj_gap_hw_sp");
  for (int fi = 0; fi < num_fixtures; fi++) {
    const PerFixtureResult &r = res[fi];
    printf(" %-22s %5u %5u %7u %7u %4d %9.3f %9.3f %4d %9.3f %9.3f %4s %9s %9.2e\n",
           r.name, r.m, r.n, r.nnz_K, r.nnz_L,
           r.hw_iters, r.hw_total_s, r.hw_solve_ms_avg,
           r.swsp_iters, r.swsp_total_s, r.swsp_solve_ms_avg,
           r.swd_run ? std::to_string(r.swd_iters).c_str() : "—",
           r.swd_run ? std::to_string(r.swd_total_s).c_str() : "—",
           r.obj_rel_gap_hw_vs_swsp);
  }
  printf("==============================================================================================================================\n");

  // CSV report.
  FILE *csv = fopen("../data/lp_ipm_sparse_report.csv", "w");
  if (csv) {
    fprintf(csv,
            "fixture,m,n,nnz_K,nnz_L,"
            "HW_status,HW_total_s,HW_iters,HW_solve_ms_avg,HW_obj,HW_prim_inf,HW_dual_inf,HW_energy_J,"
            "SW_sp_status,SW_sp_total_s,SW_sp_iters,SW_sp_solve_ms_avg,SW_sp_obj,SW_sp_prim_inf,SW_sp_dual_inf,SW_sp_energy_J,"
            "SW_d_run,SW_d_status,SW_d_total_s,SW_d_iters,SW_d_obj,SW_d_prim_inf,SW_d_dual_inf,SW_d_energy_J,"
            "obj_rel_gap_hw_vs_sw_sp,obj_rel_gap_hw_vs_sw_d\n");
    for (int fi = 0; fi < num_fixtures; fi++) {
      const PerFixtureResult &r = res[fi];
      fprintf(csv,
              "%s,%u,%u,%u,%u,"
              "%s,%.6f,%d,%.6f,%.6e,%.6e,%.6e,%.6f,"
              "%s,%.6f,%d,%.6f,%.6e,%.6e,%.6e,%.6f,"
              "%d,%s,%.6f,%d,%.6e,%.6e,%.6e,%.6f,"
              "%.6e,%.6e\n",
              r.name, r.m, r.n, r.nnz_K, r.nnz_L,
              status_str(r.hw_status), r.hw_total_s, r.hw_iters,
              r.hw_solve_ms_avg, r.hw_obj, r.hw_prim_inf, r.hw_dual_inf, r.hw_energy_j,
              status_str(r.swsp_status), r.swsp_total_s, r.swsp_iters,
              r.swsp_solve_ms_avg, r.swsp_obj, r.swsp_prim_inf, r.swsp_dual_inf, r.swsp_energy_j,
              r.swd_run ? 1 : 0, r.swd_run ? status_str(r.swd_status) : "—",
              r.swd_total_s, r.swd_iters, r.swd_obj,
              r.swd_prim_inf, r.swd_dual_inf, r.swd_energy_j,
              r.obj_rel_gap_hw_vs_swsp, r.obj_rel_gap_hw_vs_swd);
    }
    fclose(csv);
    printf("CSV report: ../data/lp_ipm_sparse_report.csv\n");
  } else {
    printf("WARN: could not write ../data/lp_ipm_sparse_report.csv\n");
  }

  if (conv_csv) fclose(conv_csv);
  free(res);
  return any_fail ? 1 : 0;
}
