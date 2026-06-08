// MILP pipeline profiling: runs the CPU-only and FPGA-accelerated solvers on
// the same instances back-to-back for a direct SW vs HW comparison.

#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include <vector>

#include "opt.h"
#include "utils.h"

#include "CAccelProxy.hpp"
#include "CDenseSolveProxy.hpp"
#include "fxp_utils.h"
#include "constants.h"
#include "opt_hw.h"
#include "pmt_power_meter.h"
#include "measure_helpers.h"

#define DENSE_SOLVE_HW_ADDR 0xA0000000
#define MAP_SIZE (64*1024)
#define MAX_INPUT_SIZE  (DENSE_MAX_M * DENSE_MAX_N + DENSE_MAX_N + DENSE_MAX_M)
#define MAX_OUTPUT_SIZE (DENSE_MAX_M)

// Deterministic RNG
static unsigned rng_state = 1u;
static unsigned xorshift32(void) {
  unsigned x = rng_state;
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  rng_state = x;
  return x;
}
static double urand(void) {
  return (xorshift32() / 4294967296.0);
}

static Csr make_random_csr_A(int m, int n, double density) {
  double *Ad = (double*)calloc((size_t)m*(size_t)n, sizeof(double));
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      if (urand() < density) {
        double v = (double)((int)(urand()*5.0) + 1);
        Ad[i*n + j] = v;
      }
    }
    int has = 0;
    for (int j = 0; j < n; j++) if (Ad[i*n + j] != 0.0) { has=1; break; }
    if (!has) Ad[i*n + (i % n)] = 1.0;
  }

  int nnz = 0;
  for (int i = 0; i < m*n; i++) if (Ad[i] != 0.0) nnz++;

  int *row_ptr = (int*)malloc((size_t)(m+1)*sizeof(int));
  int *col_ind = (int*)malloc((size_t)nnz*sizeof(int));
  double *val  = (double*)malloc((size_t)nnz*sizeof(double));

  int pos = 0;
  row_ptr[0] = 0;
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      double a = Ad[i*n + j];
      if (a != 0.0) {
        col_ind[pos] = j;
        val[pos] = a;
        pos++;
      }
    }
    row_ptr[i+1] = pos;
  }

  free(Ad);

  Csr A;
  A.m = m; A.n = n; A.nnz = nnz;
  A.row_ptr = row_ptr;
  A.col_ind = col_ind;
  A.val = val;
  return A;
}

static void free_csr(Csr *A) {
  free(A->row_ptr);
  free(A->col_ind);
  free(A->val);
}

static LPStd make_lp_instance(int m, int n, double density) {
  LPStd M;
  M.m = m; M.n = n;
  M.A = make_random_csr_A(m, n, density);
  M.b = (double*)malloc((size_t)m * sizeof(double));
  M.c = (double*)malloc((size_t)n * sizeof(double));

  for (int j = 0; j < n; j++) M.c[j] = 0.5 + 5.0 * urand();

  double *ones = (double*)malloc((size_t)n * sizeof(double));
  for (int j = 0; j < n; j++) ones[j] = 1.0;
  csr_spmv(&M.A, ones, M.b);
  free(ones);

  return M;
}

static void free_lp(LPStd *M) {
  free_csr(&M->A);
  free(M->b);
  free(M->c);
}

static MILPStd make_milp_instance(int m, int n, int nbinary, double density) {
  MILPStd M;
  M.lp = make_lp_instance(m, n, density);
  M.vtype = (int8_t*)malloc((size_t)n * sizeof(int8_t));
  for (int j = 0; j < n; j++) M.vtype[j] = 0;
  for (int j = 0; j < nbinary && j < n; j++) M.vtype[j] = 2;
  return M;
}

static void free_milp(MILPStd *M) {
  free_lp(&M->lp);
  free(M->vtype);
}

static void print_lp_row(const char *tag, int k, int m, int n, int nnz,
                         double wall_ms, const Result *r,
                         double energy_j, double avg_w) {
  printf("  %4d  %-2s  %3d  %3d  %4d    %3d  %8.3f  %16.10f  %8.2e  %9.2e  %6d  %8.4f  %6.2f\n",
         k, tag, m, n, nnz, r->iters, wall_ms, r->obj,
         r->prim_inf, r->dual_inf, r->status, energy_j, avg_w);
}

static void print_milp_row(const char *tag, int k, int m, int n, int nnz,
                           double wall_ms, const Result *r,
                           double energy_j, double avg_w) {
  printf("  %4d  %-2s  %3d  %3d  %4d    %3d  %8.3f  %16.10f  %6d  %8.4f  %6.2f\n",
         k, tag, m, n, nnz, r->iters, wall_ms, r->obj, r->status,
         energy_j, avg_w);
}

static void print_prof_row(const char *tag, int m, int n, int nnz, const Result *r,
                           double energy_j, double avg_w) {
  double tot = r->prof.total_ms;
  if (tot < 1e-9) tot = 1e-9;
  // "kform" for SW, "conv" for HW share the slot — label picked by caller via tag.
  double mid_ms = (r->prof.kform_ms > 0.0) ? r->prof.kform_ms : r->prof.conv_ms;
  printf("  %3d  %-2s  %3d  %4d    %3d  %9.3f  %5.1f%%  %6.1f%%  %5.1f%%  %5.1f%%  %6.1f%%  %5.1f%%  %8.4f  %6.2f\n",
         m, tag, n, nnz, r->iters, r->prof.total_ms,
         100.0*r->prof.spmv_ms/tot, 100.0*r->prof.spmv_t_ms/tot,
         100.0*r->prof.vecops_ms/tot, 100.0*mid_ms/tot,
         100.0*r->prof.dsolve_ms/tot, 100.0*r->prof.other_ms/tot,
         energy_j, avg_w);
  printf("       raw_ms: spmv=%.4f spmv_t=%.4f vecops=%.4f kf/cv=%.4f dsolve=%.4f other=%.4f\n",
         r->prof.spmv_ms, r->prof.spmv_t_ms, r->prof.vecops_ms, mid_ms,
         r->prof.dsolve_ms, r->prof.other_ms);
}

struct ScalingRow {
  double density;
  int    m;
  int    n;
  int    nnz;
  int    sw_iters;
  int    hw_iters;
  double sw_time_s;
  double hw_time_s;
  double sw_energy_j;
  double hw_energy_j;
  double sw_avg_w;
  double hw_avg_w;
  // Final residuals (added 2026-05-19 to align with sparse report schema).
  double sw_prim_inf;
  double sw_dual_inf;
  double sw_obj;
  double hw_prim_inf;
  double hw_dual_inf;
  double hw_obj;
  // Per-call solve time (added for per-iteration kernel-throughput comparison).
  // Totals over all IPM iters; per-iteration = total / iters.
  double sw_solve_ms;    // CPU kform + dense solve
  double hw_dsolve_ms;   // FPGA kform + factor + tri-solve
  bool   hw_skipped;
};

int main(int argc, char **argv) {
  int single_m = 0, single_n = 0, single_seed = 1;
  double single_density = 0.0, aspect = 1.6;
  const char *csv_suffix = "";
  bool single_mode = false;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--m") && i+1 < argc)        { single_m = atoi(argv[++i]); single_mode = true; }
    else if (!strcmp(argv[i], "--n") && i+1 < argc)   { single_n = atoi(argv[++i]); }
    else if (!strcmp(argv[i], "--density") && i+1 < argc) { single_density = atof(argv[++i]); }
    else if (!strcmp(argv[i], "--seed") && i+1 < argc)    { single_seed = atoi(argv[++i]); }
    else if (!strcmp(argv[i], "--aspect") && i+1 < argc)  { aspect = atof(argv[++i]); }
    else if (!strcmp(argv[i], "--csv-suffix") && i+1 < argc) { csv_suffix = argv[++i]; }
  }
  if (single_mode && single_n == 0) single_n = (int)(single_m * aspect);
  if (single_mode && csv_suffix[0] == '\0') csv_suffix = "_item4";

  printf("\n=== MILP Pipeline Profiling: SW vs FPGA DenseSolve ===\n\n");
  if (single_mode) {
    printf("Single-instance mode: m=%d n=%d density=%.3f seed=%d\n",
           single_m, single_n, single_density, single_seed);
  }
  printf("Initializing FPGA...\n");
  printf("This program requires that the bitstream is loaded and must run with sudo.\n\n");

  CDenseSolveProxy solver(false);
  if (solver.Open(DENSE_SOLVE_HW_ADDR, MAP_SIZE) != CAccelProxy::OK) {
    printf("Error mapping FPGA at 0x%08X\n", DENSE_SOLVE_HW_ADDR);
    return -1;
  }
  printf("FPGA mapped successfully.\n");

  TFXP *inputHW  = (TFXP*)solver.AllocDMACompatible(MAX_INPUT_SIZE  * sizeof(TFXP));
  TFXP *outputHW = (TFXP*)solver.AllocDMACompatible(MAX_OUTPUT_SIZE * sizeof(TFXP));
  if (!inputHW || !outputHW) {
    printf("Error allocating DMA memory.\n");
    return -1;
  }
  printf("DMA memory allocated.\n\n");

  PmtPowerMeter pwr;
  bool powerOk = pwr.Probe();
  if (powerOk) {
    printf("PMT: %zu rail(s) detected\n", pwr.Rails().size());
    for (const auto& r : pwr.Rails())
      printf("  - %s (%s)\n", r.name.c_str(), r.path.c_str());
  } else {
    printf("PMT: no hwmon rails detected — energy columns will be 0\n");
  }
  printf("\n");

  rng_state = (unsigned)single_seed;

  LPParams lp = { 80, 1e-8, 0.1, 0.99, NULL, NULL, NULL };
  MILPParams mp = { 256, 64, 1e-6, 1e-12 };

  char conv_csv_path[256];
  snprintf(conv_csv_path, sizeof(conv_csv_path),
           "../data/milp_bnb_convergence%s.csv", csv_suffix);
  FILE *conv_csv = fopen(conv_csv_path, single_mode ? "a" : "w");
  if (conv_csv) {
    if (!single_mode || ftell(conv_csv) == 0) {
      fprintf(conv_csv, "fixture,solver,iter,prim_inf,dual_inf,mu,obj\n");
    }
    fflush(conv_csv);
  } else {
    printf("warning: could not open %s (no logging)\n", conv_csv_path);
  }

  // ---------- LP sanity block (small sizes) ----------
  if (!single_mode) {
  printf("=== LP instances (SW vs HW) ===\n\n");
  printf("  inst  bk    m    n   nnz  iters  time_ms        obj          prim_inf   dual_inf  status  energy_J  avg_W\n");
  printf("  ----  --   ---  ---  ----  -----  --------  ----------------  --------  ---------  ------  --------  ------\n");

  for (int k = 0; k < 3; k++) {
    int m = 6 + 2*k;
    int n = 10 + 3*k;
    double density = 0.30;

    LPStd M = make_lp_instance(m, n, density);

    if (powerOk) pwr.Start();
    double t0 = now_ms();
    Result rSW = lp_solve_ipm(&M, &lp);
    double t1 = now_ms();
    if (powerOk) pwr.Stop();
    double e_sw = powerOk ? pwr.TotalEnergyJ() : 0.0;
    double w_sw = powerOk ? pwr.AvgPowerW()    : 0.0;

    if (powerOk) pwr.Start();
    Result rHW = lp_solve_ipm_hw(&M, &lp, &solver, inputHW, outputHW);
    double t2 = now_ms();
    if (powerOk) pwr.Stop();
    double e_hw = powerOk ? pwr.TotalEnergyJ() : 0.0;
    double w_hw = powerOk ? pwr.AvgPowerW()    : 0.0;

    print_lp_row("SW", k, m, n, M.A.nnz, t1 - t0, &rSW, e_sw, w_sw);
    print_lp_row("HW", k, m, n, M.A.nnz, t2 - t1, &rHW, e_hw, w_hw);

    result_free(&rSW);
    result_free(&rHW);
    free_lp(&M);
  }

  // ---------- MILP sanity block ----------
  printf("\n=== MILP instances (SW vs HW) ===\n\n");
  printf("  inst  bk    m    n   nnz  iters  time_ms        obj         status  energy_J  avg_W\n");
  printf("  ----  --   ---  ---  ----  -----  --------  ----------------  ------  --------  ------\n");

  for (int k = 0; k < 2; k++) {
    int m = 6 + 2*k;
    int n = 10 + 3*k;
    int nb = 5 + k;
    double density = 0.30;

    MILPStd M = make_milp_instance(m, n, nb, density);

    if (powerOk) pwr.Start();
    double t0 = now_ms();
    Result rSW = milp_solve_bnb(&M, &lp, &mp);
    double t1 = now_ms();
    if (powerOk) pwr.Stop();
    double e_sw = powerOk ? pwr.TotalEnergyJ() : 0.0;
    double w_sw = powerOk ? pwr.AvgPowerW()    : 0.0;

    if (powerOk) pwr.Start();
    Result rHW = milp_solve_bnb_hw(&M, &lp, &mp, &solver, inputHW, outputHW);
    double t2 = now_ms();
    if (powerOk) pwr.Stop();
    double e_hw = powerOk ? pwr.TotalEnergyJ() : 0.0;
    double w_hw = powerOk ? pwr.AvgPowerW()    : 0.0;

    print_milp_row("SW", k, m, n, M.lp.A.nnz, t1 - t0, &rSW, e_sw, w_sw);
    print_milp_row("HW", k, m, n, M.lp.A.nnz, t2 - t1, &rHW, e_hw, w_hw);

    result_free(&rSW);
    result_free(&rHW);
    free_milp(&M);
  }
  }  // end !single_mode (LP+MILP sanity)

  std::vector<ScalingRow> sweep;

  // ---------- Scaling sweep: dense ----------
  printf("\n\n=== LP timing profiling SW vs HW (density=0.30, n/m=1.6) ===\n\n");
  printf("   m   bk    n    nnz  iters   total_ms   spmv%%  spmv_t%%  vecops%%  kf/cv%%  dsolve%%  other%%  energy_J  avg_W\n");
  printf("  ---  --   ---  ----  -----  ---------  ------  -------  ------  ------  -------  ------  --------  ------\n");

  int default_scale_m[] = {10, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240};
  int *scale_m = single_mode ? &single_m : default_scale_m;
  int n_scales = single_mode ? 1 : (int)(sizeof(default_scale_m) / sizeof(default_scale_m[0]));

  for (int k = 0; k < n_scales; k++) {
    int m = scale_m[k];
    int n = single_mode ? single_n : (int)(m * 1.6);
    double density = single_mode ? single_density : 0.30;

    LPStd M = make_lp_instance(m, n, density);

    char fixture_name[64];
    snprintf(fixture_name, sizeof(fixture_name),
             "dense_m%03d_d%03d_s%02d",
             m, (int)round(density*100), single_seed);

    lp.conv_log     = conv_csv;
    lp.conv_fixture = fixture_name;
    lp.conv_solver  = "dense_sw";
    Result rSW = {};
    double cum_sw_s = 0.0;
    uint32_t reps_sw = measure_adaptive(pwr, [&](uint32_t rep) {
      if (rep > 0) { result_free(&rSW); lp.conv_log = nullptr; }
      rSW = lp_solve_ipm(&M, &lp);
    }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_sw_s);
    if (conv_csv) fflush(conv_csv);
    double e_sw = powerOk ? pwr.TotalEnergyJ() / reps_sw : 0.0;
    double w_sw = powerOk ? pwr.AvgPowerW() : 0.0;
    print_prof_row("SW", m, n, M.A.nnz, &rSW, e_sw, w_sw);

    ScalingRow row{};
    row.density   = density;
    row.m = m; row.n = n; row.nnz = M.A.nnz;
    row.sw_iters  = rSW.iters;
    row.sw_time_s = cum_sw_s / reps_sw;
    row.sw_energy_j = e_sw;
    row.sw_avg_w  = w_sw;
    row.sw_prim_inf = rSW.prim_inf;
    row.sw_dual_inf = rSW.dual_inf;
    row.sw_obj      = rSW.obj;
    row.sw_solve_ms = rSW.prof.kform_ms + rSW.prof.dsolve_ms;
    result_free(&rSW);

    if (m > DENSE_MAX_M || n > DENSE_MAX_N) {
      printf("  %3d  HW  %3d  ----  -----  SKIPPED (exceeds FPGA limits)\n", m, n);
      row.hw_skipped = true;
    } else {
      lp.conv_log     = conv_csv;
      lp.conv_fixture = fixture_name;
      lp.conv_solver  = "dense_hw";
      Result rHW = {};
      double cum_hw_s = 0.0;
      uint32_t reps_hw = measure_adaptive(pwr, [&](uint32_t rep) {
        if (rep > 0) { result_free(&rHW); lp.conv_log = nullptr; }
        rHW = lp_solve_ipm_hw(&M, &lp, &solver, inputHW, outputHW);
      }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_hw_s);
      if (conv_csv) fflush(conv_csv);
      double e_hw = powerOk ? pwr.TotalEnergyJ() / reps_hw : 0.0;
      double w_hw = powerOk ? pwr.AvgPowerW() : 0.0;
      print_prof_row("HW", m, n, M.A.nnz, &rHW, e_hw, w_hw);
      row.hw_iters  = rHW.iters;
      row.hw_time_s = cum_hw_s / reps_hw;
      row.hw_energy_j = e_hw;
      row.hw_avg_w  = w_hw;
      row.hw_prim_inf = rHW.prim_inf;
      row.hw_dual_inf = rHW.dual_inf;
      row.hw_obj      = rHW.obj;
      row.hw_dsolve_ms = rHW.prof.dsolve_ms;
      row.hw_skipped = false;
      result_free(&rHW);
    }

    sweep.push_back(row);
    free_lp(&M);
  }

  // ---------- Scaling sweep: sparse ----------
  if (!single_mode) {
  printf("\n\n=== LP timing profiling SW vs HW (density=0.02, n/m=1.05) ===\n\n");
  printf("   m   bk    n    nnz  iters   total_ms   spmv%%  spmv_t%%  vecops%%  kf/cv%%  dsolve%%  other%%  energy_J  avg_W\n");
  printf("  ---  --   ---  ----  -----  ---------  ------  -------  ------  ------  -------  ------  --------  ------\n");

  for (int k = 0; k < n_scales; k++) {
    int m = scale_m[k];
    int n = (int)(m * 1.05);
    if (n < m + 1) n = m + 1;
    double density = 0.02;

    LPStd M = make_lp_instance(m, n, density);

    char fixture_name[64];
    snprintf(fixture_name, sizeof(fixture_name), "sparse_m%03d_d002", m);

    lp.conv_log     = conv_csv;
    lp.conv_fixture = fixture_name;
    lp.conv_solver  = "dense_sw";
    Result rSW = {};
    double cum_sw_s = 0.0;
    uint32_t reps_sw = measure_adaptive(pwr, [&](uint32_t rep) {
      if (rep > 0) { result_free(&rSW); lp.conv_log = nullptr; }
      rSW = lp_solve_ipm(&M, &lp);
    }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_sw_s);
    if (conv_csv) fflush(conv_csv);
    double e_sw = powerOk ? pwr.TotalEnergyJ() / reps_sw : 0.0;
    double w_sw = powerOk ? pwr.AvgPowerW() : 0.0;
    print_prof_row("SW", m, n, M.A.nnz, &rSW, e_sw, w_sw);

    ScalingRow row{};
    row.density   = density;
    row.m = m; row.n = n; row.nnz = M.A.nnz;
    row.sw_iters  = rSW.iters;
    row.sw_time_s = cum_sw_s / reps_sw;
    row.sw_energy_j = e_sw;
    row.sw_avg_w  = w_sw;
    row.sw_prim_inf = rSW.prim_inf;
    row.sw_dual_inf = rSW.dual_inf;
    row.sw_obj      = rSW.obj;
    row.sw_solve_ms = rSW.prof.kform_ms + rSW.prof.dsolve_ms;
    result_free(&rSW);

    if (m > DENSE_MAX_M || n > DENSE_MAX_N) {
      printf("  %3d  HW  %3d  ----  -----  SKIPPED (exceeds FPGA limits)\n", m, n);
      row.hw_skipped = true;
    } else {
      lp.conv_log     = conv_csv;
      lp.conv_fixture = fixture_name;
      lp.conv_solver  = "dense_hw";
      Result rHW = {};
      double cum_hw_s = 0.0;
      uint32_t reps_hw = measure_adaptive(pwr, [&](uint32_t rep) {
        if (rep > 0) { result_free(&rHW); lp.conv_log = nullptr; }
        rHW = lp_solve_ipm_hw(&M, &lp, &solver, inputHW, outputHW);
      }, MEAS_IPM_MIN_REPS, MEAS_IPM_MIN_SEC, MEAS_IPM_MAX_REPS, &cum_hw_s);
      if (conv_csv) fflush(conv_csv);
      double e_hw = powerOk ? pwr.TotalEnergyJ() / reps_hw : 0.0;
      double w_hw = powerOk ? pwr.AvgPowerW() : 0.0;
      print_prof_row("HW", m, n, M.A.nnz, &rHW, e_hw, w_hw);
      row.hw_iters  = rHW.iters;
      row.hw_time_s = cum_hw_s / reps_hw;
      row.hw_energy_j = e_hw;
      row.hw_avg_w  = w_hw;
      row.hw_prim_inf = rHW.prim_inf;
      row.hw_dual_inf = rHW.dual_inf;
      row.hw_obj      = rHW.obj;
      row.hw_dsolve_ms = rHW.prof.dsolve_ms;
      row.hw_skipped = false;
      result_free(&rHW);
    }

    sweep.push_back(row);
    free_lp(&M);
  }
  }  // end !single_mode (sparse sweep)

  printf("\n");

  char energy_csv_path[256];
  snprintf(energy_csv_path, sizeof(energy_csv_path),
           "../data/milp_bnb_energy%s.csv", csv_suffix);
  if (powerOk) {
    bool append = single_mode;
    FILE *csv = fopen(energy_csv_path, append ? "a" : "w");
    if (csv) {
      if (!append || ftell(csv) == 0) {
        fprintf(csv, "density,m,n,nnz,sw_iters,hw_iters,sw_time_s,hw_time_s,"
                     "sw_energy_J,hw_energy_J,sw_avgP_W,hw_avgP_W,energy_HW_per_SW,"
                     "sw_prim_inf,sw_dual_inf,sw_obj,hw_prim_inf,hw_dual_inf,hw_obj,"
                     "sw_solve_ms,hw_dsolve_ms\n");
      }
      for (const auto &r : sweep) {
        double ratio = (r.sw_energy_j > 0.0 && !r.hw_skipped)
                       ? (r.hw_energy_j / r.sw_energy_j)
                       : 0.0;
        fprintf(csv, "%.3f,%d,%d,%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.3f,%.3f,%.4f,"
                     "%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6f,%.6f\n",
                r.density, r.m, r.n, r.nnz,
                r.sw_iters, r.hw_iters,
                r.sw_time_s, r.hw_skipped ? 0.0 : r.hw_time_s,
                r.sw_energy_j, r.hw_skipped ? 0.0 : r.hw_energy_j,
                r.sw_avg_w, r.hw_skipped ? 0.0 : r.hw_avg_w,
                ratio,
                r.sw_prim_inf, r.sw_dual_inf, r.sw_obj,
                r.hw_skipped ? 0.0 : r.hw_prim_inf,
                r.hw_skipped ? 0.0 : r.hw_dual_inf,
                r.hw_skipped ? 0.0 : r.hw_obj,
                r.sw_solve_ms, r.hw_skipped ? 0.0 : r.hw_dsolve_ms);
      }
      fclose(csv);
      printf("CSV report written to %s\n", energy_csv_path);
    } else {
      printf("WARN: could not write %s\n", energy_csv_path);
    }
  }

  if (conv_csv) {
    fclose(conv_csv);
    printf("Convergence CSV written to %s\n", conv_csv_path);
  }

  if (inputHW)  solver.FreeDMACompatible(inputHW);
  if (outputHW) solver.FreeDMACompatible(outputHW);

  return 0;
}
