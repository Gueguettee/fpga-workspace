#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <map>

#include "CAccelProxy.hpp"
#include "CDenseSolveProxy.hpp"
#include "util.hpp"

#include "fxp_utils.h"
#include "constants.h"
#include "pmt_power_meter.h"
#include "measure_helpers.h"

#define DENSE_SOLVE_HW_ADDR 0xA0000000
#define MAP_SIZE 64*1024

// Relative tolerance for SW (double) vs HW (fixed-point) comparison
static const double REL_TOL = 0.50; 
static const double ABS_TOL = 2.0;   // absolute tolerance — ignore errors on small values
static const double MIN_SNR_DB = 50.0;  // minimum acceptable SNR

struct TestResult {
  uint32_t n;
  uint32_t m;
  double   convTime_s;
  double   swTime_s;
  double   swCholTime_s;
  double   hwTime_s;
  double   speedup;
  double   speedup_chol;
  double   fairSpeedup;
  double   snr_db;
  double   maxRelErr;
  bool     pass;
  double   snr_chol_db;
  double   maxRelErr_chol;
  bool     pass_chol;
  double   sw_energy_j;
  double   sw_avgPower_w;
  double   sw_chol_energy_j;
  double   sw_chol_avgPower_w;
  double   sw_chol_peakPower_w;
  double   energy_j;
  double   avgPower_w;
  double   peakPower_w;
  double   sampleWindow_s;
};

// Input: Ad[m*n] + D[n] + rhs[m]
#define MAX_INPUT_SIZE  (DENSE_MAX_M * DENSE_MAX_N + DENSE_MAX_N + DENSE_MAX_M)
// Output: dy[m]
#define MAX_OUTPUT_SIZE (DENSE_MAX_M)

TFXP input[MAX_INPUT_SIZE];
double outputSW[DENSE_MAX_M];
double outputSW_chol[DENSE_MAX_M];
double Ksw[DENSE_MAX_M * DENSE_MAX_M];
double Dv_sw[DENSE_MAX_M];
double v_sw[DENSE_MAX_M];
double Ad_d[DENSE_MAX_M * DENSE_MAX_N];
double D_d[DENSE_MAX_N];
double b_d[DENSE_MAX_M];

static void PrintRailBreakdown(const PmtPowerMeter &s, const char *label)
{
  printf("  [rails %s window=%.4fs]", label, s.WindowSeconds());
  for (const auto &r : s.Rails()) {
    printf("  %s=%.3fW", r.name.c_str(), r.avg_w);
  }
  printf("\n");
}

static void PrintCpufreqState(const char *label)
{
  printf("  [cpufreq %s]", label);
  for (int cpu = 0; cpu < 4; ++cpu) {
    char path[128];
    snprintf(path, sizeof(path),
             "/sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq", cpu);
    FILE *f = fopen(path, "r");
    if (!f) { printf("  cpu%d=N/A", cpu); continue; }
    int khz = 0;
    if (fscanf(f, "%d", &khz) != 1) khz = 0;
    fclose(f);
    snprintf(path, sizeof(path),
             "/sys/devices/system/cpu/cpu%d/cpufreq/scaling_governor", cpu);
    char gov[32] = "?";
    f = fopen(path, "r");
    if (f) { if (fscanf(f, "%31s", gov) != 1) gov[0] = '?'; fclose(f); }
    printf("  cpu%d=%dMHz(%s)", cpu, khz / 1000, gov);
  }
  printf("\n");
}

///////////////////////////////////////////////////////////////////////////////
// Zero-fill using 32-bit stores. glibc memset uses NEON 128-bit stores which
// are illegal on Device-type memory (Cacheable=0 CMA on aarch64).
static void ZeroFill32(void *dst, size_t bytes)
{
  volatile uint32_t *p = (volatile uint32_t *)dst;
  size_t count = bytes / sizeof(uint32_t);
  for (size_t i = 0; i < count; ++i)
    p[i] = 0;
}

///////////////////////////////////////////////////////////////////////////////
// Combine multiple rand() calls to get a full-range random int64_t in [0, range).
// Needed because RAND_MAX is only 32767 on Windows. Returns int64_t (assignable to TFXP).
static int64_t FullRangeRand(int64_t range)
{
  uint64_t r = ((uint64_t)rand() << 45) ^ ((uint64_t)rand() << 30) ^
               ((uint64_t)rand() << 15) ^ (uint64_t)rand();
  return (int64_t)(r % (uint64_t)range);
}

///////////////////////////////////////////////////////////////////////////////
// Fill with random fixed-point values in [-1, 1] range
void InitRandom(TFXP *dst, TFXP *dstHW, uint32_t size)
{
  for (uint32_t i = 0; i < size; i++) {
    int64_t raw = FullRangeRand((int64_t)2 << DECIMALS) - ((int64_t)1 << DECIMALS);
    dst[i] = (TFXP)raw;
    dstHW[i] = (TFXP)raw;
  }
}

///////////////////////////////////////////////////////////////////////////////
// Fill with positive random values for D (ensures K is positive definite).
void InitDPositive(TFXP *dst, TFXP *dstHW, uint32_t size)
{
  for (uint32_t i = 0; i < size; i++) {
    int64_t raw = FullRangeRand((int64_t)2 << (DECIMALS - 2)) + ((int64_t)1 << (DECIMALS - 3));
    dst[i] = (TFXP)raw;
    dstHW[i] = (TFXP)raw;
  }
}

///////////////////////////////////////////////////////////////////////////////
// Convert FXP inputs to double (timed separately from computation)
void ConvertInputs_SW(TFXP *in, double *Ad, double *D, double *b,
                      uint32_t n, uint32_t m)
{
  TFXP *AdFxp  = in;
  TFXP *DFxp   = in + m * n;
  TFXP *rhsFxp = in + m * n + n;

  for (uint32_t i = 0; i < m * n; i++) Ad[i] = Fxp2Double(AdFxp[i]);
  for (uint32_t j = 0; j < n; j++)     D[j]  = Fxp2Double(DFxp[j]);
  for (uint32_t i = 0; i < m; i++)     b[i]  = Fxp2Double(rhsFxp[i]);
}

///////////////////////////////////////////////////////////////////////////////
// SW reference: K-formation then Gaussian elimination solve (double precision)
// Takes pre-converted double inputs (conversion timed separately)
void KFormAndSolve_SW(double *Ad, double *D, double *b, double *dy,
                      uint32_t n, uint32_t m)
{
  // K-formation: K = A * diag(D) * A^T
  for (uint32_t i = 0; i < m; i++) {
    for (uint32_t k2 = 0; k2 < m; k2++) {
      double sum = 0.0;
      for (uint32_t j = 0; j < n; j++) {
        sum += Ad[i * n + j] * D[j] * Ad[k2 * n + j];
      }
      Ksw[i * m + k2] = sum;
    }
  }

  // Gaussian elimination with partial pivoting
  for (uint32_t i = 0; i < m; i++) dy[i] = 0.0;

  for (uint32_t k = 0; k < m; k++) {
    // Partial pivoting
    uint32_t piv = k;
    double best = fabs(Ksw[k * m + k]);
    for (uint32_t i = k + 1; i < m; i++) {
      double v = fabs(Ksw[i * m + k]);
      if (v > best) { best = v; piv = i; }
    }

    if (piv != k) {
      for (uint32_t j = k; j < m; j++) {
        double tmp = Ksw[k * m + j];
        Ksw[k * m + j] = Ksw[piv * m + j];
        Ksw[piv * m + j] = tmp;
      }
      double tb = b[k]; b[k] = b[piv]; b[piv] = tb;
    }

    double diag = Ksw[k * m + k];
    for (uint32_t i = k + 1; i < m; i++) {
      double f = Ksw[i * m + k] / diag;
      Ksw[i * m + k] = 0.0;
      for (uint32_t j = k + 1; j < m; j++) {
        Ksw[i * m + j] -= f * Ksw[k * m + j];
      }
      b[i] -= f * b[k];
    }
  }

  // Back-substitution
  for (int32_t i = (int32_t)m - 1; i >= 0; i--) {
    double s = b[i];
    for (int32_t j = i + 1; j < (int32_t)m; j++) {
      s -= Ksw[i * m + j] * dy[j];
    }
    dy[i] = s / Ksw[i * m + i];
  }
}

///////////////////////////////////////////////////////////////////////////////
// SW reference: K-formation then LDL^T (no sqrt, no pivot), matching the
// HW kernel's cholesky_solve_hw in doubles.
void KFormAndCholeskySolve_SW(const double *Ad, const double *D,
                              const double *b, double *dy,
                              uint32_t n, uint32_t m)
{
  for (uint32_t i = 0; i < m; i++) {
    for (uint32_t k2 = 0; k2 <= i; k2++) {
      double sum = 0.0;
      for (uint32_t j = 0; j < n; j++) {
        sum += Ad[i * n + j] * D[j] * Ad[k2 * n + j];
      }
      Ksw[i * m + k2] = sum;
    }
  }

  for (uint32_t j = 0; j < m; j++) {
    for (uint32_t k = 0; k < j; k++) {
      v_sw[k] = Ksw[j * m + k] * Dv_sw[k];
    }
    double sum_diag = Ksw[j * m + j];
    for (uint32_t k = 0; k < j; k++) {
      sum_diag -= Ksw[j * m + k] * v_sw[k];
    }
    if (sum_diag <= 0.0) sum_diag = 1.0;  // mirrors cholesky_solve.cpp:66
    Dv_sw[j] = sum_diag;
    double inv_dj = 1.0 / sum_diag;

    for (uint32_t i = j + 1; i < m; i++) {
      double sum_off = Ksw[i * m + j];
      for (uint32_t k = 0; k < j; k++) {
        sum_off -= Ksw[i * m + k] * v_sw[k];
      }
      Ksw[i * m + j] = sum_off * inv_dj;
    }
  }

  for (uint32_t i = 0; i < m; i++) {
    double s = b[i];
    for (uint32_t j = 0; j < i; j++) {
      s -= Ksw[i * m + j] * dy[j];
    }
    dy[i] = s;
  }
  for (uint32_t i = 0; i < m; i++) {
    dy[i] /= Dv_sw[i];
  }
  for (int32_t i = (int32_t)m - 1; i >= 0; i--) {
    double s = dy[i];
    for (int32_t j = i + 1; j < (int32_t)m; j++) {
      s -= Ksw[(uint32_t)j * m + (uint32_t)i] * dy[j];
    }
    dy[i] = s;
  }
}

///////////////////////////////////////////////////////////////////////////////
bool CompareVectors(double *sw, TFXP *hw, uint32_t size, double &out_snr, double &out_maxRelErr)
{
  bool ok = true;
  double maxRelErr = 0.0;
  double sumSqErr = 0.0;
  double sumSqRef = 0.0;

  for (uint32_t i = 0; i < size; i++) {
    double hwVal = Fxp2Double(hw[i]);
    double diff = fabs(sw[i] - hwVal);
    double denom = fabs(sw[i]);
    double relErr = (denom > ABS_TOL) ? diff / denom : diff;

    sumSqErr += diff * diff;
    sumSqRef += sw[i] * sw[i];

    if (relErr > maxRelErr) maxRelErr = relErr;

    if (diff > ABS_TOL && relErr > REL_TOL) {
      printf("  Mismatch at [%" PRIu32 "]: SW=%.6f HW=%.6f (relErr=%.2f%%)\n",
             i, sw[i], hwVal, relErr * 100.0);
      ok = false;
    }
  }

  // SNR in dB: 10*log10(signal_power / error_power)
  double snr_db = (sumSqErr > 0.0) ? 10.0 * log10(sumSqRef / sumSqErr) : INFINITY;
  printf("  SNR=%.1f dB  maxRelErr=%.2f%%\n", snr_db, maxRelErr * 100.0);

  if (snr_db < MIN_SNR_DB) {
    printf("  SNR below %.1f dB threshold!\n", MIN_SNR_DB);
    ok = false;
  }

  out_snr = snr_db;
  out_maxRelErr = maxRelErr;

  return ok;
}

///////////////////////////////////////////////////////////////////////////////
bool InitDevice(CDenseSolveProxy &solver, TFXP* &inputHW, TFXP* &outputHW, bool log=true)
{
  printf("\n\nThis program requires that the bitstream is loaded in the FPGA.\n");
  printf("This program has to be run with sudo.\n");
  printf("Press ENTER to confirm that the bitstream is loaded (proceeding without it can crash the board).\n\n");
  // getchar();

  if ( solver.Open(DENSE_SOLVE_HW_ADDR, MAP_SIZE) != CAccelProxy::OK ) {
    if (log)
      printf("Error mapping device at physical address 0x%08X\n", DENSE_SOLVE_HW_ADDR);
    return false;
  }
  if (log)
    printf("Device at physical address 0x%08X successfully mapped into the application virtual address space\n\n",
            DENSE_SOLVE_HW_ADDR);

  if (log)
    printf("Allocating DMA memory...\n");
  inputHW = (TFXP *)solver.AllocDMACompatible(MAX_INPUT_SIZE * sizeof(TFXP));
  outputHW = (TFXP *)solver.AllocDMACompatible(MAX_OUTPUT_SIZE * sizeof(TFXP));
  if (log) {
    printf("DMA memory allocated.\n");
    printf("Input: Virtual address: %p\n", (void *)inputHW);
    printf("Output: Virtual address: %p\n", (void *)outputHW);
  }

  if ( (inputHW == NULL) || (outputHW == NULL) ) {
    if (log)
      printf("Error allocating DMA memory.\n");
    return false;
  }

  return true;
}

///////////////////////////////////////////////////////////////////////////////
int main(int argc, char **argv)
{
  int ila_m = 0;
  for (int i = 1; i < argc - 1; ++i) {
    if (strcmp(argv[i], "--ila") == 0) { ila_m = atoi(argv[i+1]); break; }
  }
  unsigned int seed = 42;
  for (int i = 1; i < argc - 1; ++i) {
    if (strcmp(argv[i], "--seed") == 0) { seed = (unsigned int)strtoul(argv[i+1], NULL, 10); break; }
  }
  if (ila_m > 0) {
    uint32_t m = (uint32_t)ila_m;
    uint32_t n = m;
    if (m > DENSE_MAX_M || n > DENSE_MAX_N) {
      printf("--ila: m=%u exceeds DENSE_MAX_M=%u\n", m, DENSE_MAX_M);
      return -1;
    }
    CDenseSolveProxy solver(true);
    TFXP *inputHW, *outputHW;
    if (!InitDevice(solver, inputHW, outputHW)) return -1;
    srand(seed);
    InitRandom(input, inputHW, m * n);
    InitDPositive(input + m * n, inputHW + m * n, n);
    InitRandom(input + m * n + n, inputHW + m * n + n, m);
    printf("\nILA capture mode: m=n=%u. Arm ILA in Vivado HWM, then press ENTER...\n", m);
    fflush(stdout);
    (void)getchar();
    ZeroFill32(outputHW, m * sizeof(TFXP));
    solver.DenseSolve_HW(inputHW, outputHW, n, m);
    printf("Solve done. ILA should have triggered.\n");
    return 0;
  }

  struct timespec start, end;
  uint64_t elapsedTimeConv, elapsedTimeSW, elapsedTimeHW;
  // Test sizes: {n, m} — n=columns of A, m=rows of A (n >= m for well-posed K)
  uint32_t sizes[][2] = { {4, 4}, {8, 8}, {16, 16}, {32, 32}, {64, 64}, {128, 128}, {256, 256} };
  uint32_t numSizes = sizeof(sizes) / (sizeof(uint32_t) * 2);
  TFXP *inputHW, *outputHW;
  bool errors = false;
  TestResult results[numSizes];

  CDenseSolveProxy solver(true);
  if (!InitDevice(solver, inputHW, outputHW))
    return -1;

  srand(seed);
  printf("Random seed: %u\n", seed);

  PmtPowerMeter sampler;
  bool powerOk = sampler.Probe();
  if (powerOk) {
    printf("PMT: %zu rail(s) detected\n", sampler.Rails().size());
    for (const auto& r : sampler.Rails())
      printf("  - %s (%s)\n", r.name.c_str(), r.path.c_str());
  } else {
    printf("PMT: no hwmon rails detected — energy columns will be 0\n");
  }

  PrintCpufreqState("at-rest");

  // Subtracted from per-test energy so reported numbers reflect dynamic
  // (compute-only) draw — without this the HW window padding dominates.
  double idle_power_w = 0.0;
  if (powerOk) {
    printf("Measuring idle baseline (1.0 s)... ");
    fflush(stdout);
    sampler.Start(20);
    struct timespec idle_dur = {1, 0};
    nanosleep(&idle_dur, NULL);
    sampler.Stop();
    idle_power_w = sampler.AvgPowerW();
    printf("idle = %.2f W (BOARD)\n", idle_power_w);
    PrintRailBreakdown(sampler, "idle");
  }

  for (uint32_t iTest = 0; iTest < numSizes; ++iTest) {
    uint32_t n = sizes[iTest][0];
    uint32_t m = sizes[iTest][1];
    bool diagFixture = (iTest == numSizes - 1);

    // Fill Ad with random, D with positive, rhs with random
    InitRandom(input, inputHW, m * n);                        // Ad
    InitDPositive(input + m * n, inputHW + m * n, n);         // D (positive)
    InitRandom(input + m * n + n, inputHW + m * n + n, m);   // rhs

    printf("K-form+solve %" PRIu32 "x%" PRIu32 " (m=%" PRIu32 ", n=%" PRIu32 ") ", m, n, m, n);
    fflush(stdout);

    uint64_t elapsedTimeChol = 0;
    elapsedTimeConv = 0;
    uint32_t reps_swchol = measure_adaptive(sampler, [&](uint32_t rep) {
      printf("%s", rep % 2 == 0 ? "." : "*"); fflush(stdout);
      for (uint32_t i = 0; i < m; i++) outputSW_chol[i] = 0.0;

      clock_gettime(CLOCK_MONOTONIC_RAW, &start);
      ConvertInputs_SW(input, Ad_d, D_d, b_d, n, m);
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      elapsedTimeConv += CalcTimeDiff(end, start);

      clock_gettime(CLOCK_MONOTONIC_RAW, &start);
      KFormAndCholeskySolve_SW(Ad_d, D_d, b_d, outputSW_chol, n, m);
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      elapsedTimeChol += CalcTimeDiff(end, start);
    }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS);
    double sw_chol_energy_j = 0.0, sw_chol_avgP = 0.0, sw_chol_peakP = 0.0;
    if (powerOk) {
      sampler.Stop();
      double total_J = sampler.TotalEnergyJ();
      double window_s = sampler.WindowSeconds();
      sw_chol_avgP    = sampler.AvgPowerW();
      sw_chol_peakP   = sampler.PeakPowerW();
      double dyn_J = total_J - idle_power_w * window_s;
      if (dyn_J < 0.0) dyn_J = 0.0;
      sw_chol_energy_j = dyn_J / (double)reps_swchol;
      if (diagFixture) {
        PrintRailBreakdown(sampler, "sw_chol");
        PrintCpufreqState("post-sw-chol");
      }
    }
    printf("\r(SW chol)  %" PRIu32 "x%" PRIu32 " (n=%" PRIu32 ") [%u reps] --> conv %0.6lf s + compute %0.6lf s",
      m, n, n, reps_swchol, (elapsedTimeConv/1e9)/reps_swchol, (elapsedTimeChol/1e9)/reps_swchol);
    if (powerOk)
      printf("  |  %.3f J/call  avg %.2f W", sw_chol_energy_j, sw_chol_avgP);
    printf("\n");

    elapsedTimeSW = 0;
    uint32_t reps_swgauss = measure_adaptive(sampler, [&](uint32_t rep) {
      printf("%s", rep % 2 == 0 ? "." : "*"); fflush(stdout);
      for (uint32_t i = 0; i < m; i++) outputSW[i] = 0.0;

      // Refresh b_d — Gaussian destroys it via pivoting.
      ConvertInputs_SW(input, Ad_d, D_d, b_d, n, m);

      clock_gettime(CLOCK_MONOTONIC_RAW, &start);
      KFormAndSolve_SW(Ad_d, D_d, b_d, outputSW, n, m);
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      elapsedTimeSW += CalcTimeDiff(end, start);
    }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS);
    double sw_energy_j = 0.0, sw_avgP = 0.0;
    if (powerOk) {
      sampler.Stop();
      double total_J = sampler.TotalEnergyJ();
      double window_s = sampler.WindowSeconds();
      sw_avgP = sampler.AvgPowerW();
      double dyn_J = total_J - idle_power_w * window_s;
      if (dyn_J < 0.0) dyn_J = 0.0;
      sw_energy_j = dyn_J / (double)reps_swgauss;
      if (diagFixture) {
        PrintRailBreakdown(sampler, "sw_gauss");
        PrintCpufreqState("post-sw-gauss");
      }
    }
    printf("\r(SW gauss) %" PRIu32 "x%" PRIu32 " (n=%" PRIu32 ") [%u reps] --> compute %0.6lf s",
      m, n, n, reps_swgauss, (elapsedTimeSW/1e9)/reps_swgauss);
    if (powerOk)
      printf("  |  %.3f J/call  avg %.2f W", sw_energy_j, sw_avgP);
    printf("\n");

    /**
     * HW execution
    */
    printf("Measuring HW time for %" PRIu32 "x%" PRIu32 " ", n, m);
    fflush(stdout);
    elapsedTimeHW = 0;
    double testSnr = 0.0, testMaxRelErr = 0.0;
    bool testPass = true;
    double testSnrChol = 0.0, testMaxRelErrChol = 0.0;
    bool testPassChol = true;

    uint32_t reps_hw = measure_adaptive(sampler, [&](uint32_t rep) {
      bool verbose = (rep < MEAS_KERNEL_MIN_REPS);
      printf("%s", rep % 2 == 0 ? "." : "*"); fflush(stdout);
      ZeroFill32(outputHW, m * sizeof(TFXP));
      clock_gettime(CLOCK_MONOTONIC_RAW, &start);
      solver.DenseSolve_HW(inputHW, outputHW, n, m);
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      elapsedTimeHW += CalcTimeDiff(end, start);

      double repeSnr, repeMaxRelErr;
      if (verbose) printf(" [vs gauss]");
      bool okGauss = CompareVectors(outputSW, outputHW, m, repeSnr, repeMaxRelErr);
      testSnr = repeSnr;
      testMaxRelErr = repeMaxRelErr;
      if (!okGauss) { errors = true; testPass = false; }

      double repeSnrChol, repeMaxRelErrChol;
      if (verbose) printf(" [vs chol]");
      bool okChol = CompareVectors(outputSW_chol, outputHW, m, repeSnrChol, repeMaxRelErrChol);
      testSnrChol = repeSnrChol;
      testMaxRelErrChol = repeMaxRelErrChol;
      if (!okChol) { errors = true; testPassChol = false; }

      if (verbose) {
        printf(okGauss && okChol ? "  --> OK!\n" : "\n====== ERROR ======\n\n");
      }
    }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS);

    double energy_j = 0.0, avgP = 0.0, peakP = 0.0, window_s = 0.0;
    if (powerOk) {
      sampler.Stop();
      window_s = sampler.WindowSeconds();
      double total_J = sampler.TotalEnergyJ();
      avgP     = sampler.AvgPowerW();
      peakP    = sampler.PeakPowerW();
      double dyn_J = total_J - idle_power_w * window_s;
      if (dyn_J < 0.0) dyn_J = 0.0;
      energy_j = dyn_J / (double)reps_hw;
      if (diagFixture) {
        PrintRailBreakdown(sampler, "hw");
      }
    }

    printf("\r(HW) %" PRIu32 "x%" PRIu32 " (n=%" PRIu32 ") [%u reps] --> %0.6lf s (%" PRIu64 " ns)",
      n, m, n, reps_hw, (elapsedTimeHW/1e9)/reps_hw, elapsedTimeHW/reps_hw);
    if (powerOk)
      printf("  |  %.3f J/call  avg %.2f W  peak %.2f W (window %.3f s)",
             energy_j, avgP, peakP, window_s);
    printf("\n");

    double convTime = (elapsedTimeConv / 1e9) / reps_swchol;
    double swTime = (elapsedTimeSW / 1e9) / reps_swgauss;
    double swCholTime = (elapsedTimeChol / 1e9) / reps_swchol;
    double hwTime = (elapsedTimeHW / 1e9) / reps_hw;
    results[iTest] = { n, m, convTime, swTime, swCholTime, hwTime,
                       (hwTime > 0.0) ? swTime / hwTime : INFINITY,
                       (hwTime > 0.0) ? swCholTime / hwTime : INFINITY,
                       (hwTime > 0.0) ? swTime / (hwTime + convTime) : INFINITY,
                       testSnr, testMaxRelErr, testPass,
                       testSnrChol, testMaxRelErrChol, testPassChol,
                       sw_energy_j, sw_avgP,
                       sw_chol_energy_j, sw_chol_avgP, sw_chol_peakP,
                       energy_j, avgP, peakP, window_s };
  }

  printf("\n");
  printf("==================================================== SUMMARY ====================================================\n");
  printf("%5s %5s %9s %10s %10s %10s %8s %8s %7s %7s %7s %8s %8s %8s\n",
         "n", "m", "Conv(s)", "SW_g(s)", "SW_c(s)", "HW(s)",
         "Spd_g", "Spd_c", "SNR_g", "SNR_c", "Status",
         "SW_g_E", "SW_c_E", "HW_E");
  printf("------------------------------------------------------------------------------------------------------------------\n");
  for (uint32_t i = 0; i < numSizes; ++i) {
    bool allPass = results[i].pass && results[i].pass_chol;
    printf("%5" PRIu32 " %5" PRIu32 " %9.6f %10.6f %10.6f %10.6f %7.2fx %7.2fx %7.1f %7.1f %7s %8.4f %8.4f %8.4f\n",
           results[i].n, results[i].m,
           results[i].convTime_s,
           results[i].swTime_s, results[i].swCholTime_s, results[i].hwTime_s,
           results[i].speedup, results[i].speedup_chol,
           results[i].snr_db, results[i].snr_chol_db,
           allPass ? "PASS" : "FAIL",
           results[i].sw_energy_j, results[i].sw_chol_energy_j, results[i].energy_j);
  }
  printf("==================================================================================================================\n");

  // SW_comp_s and Status kept by name for scripts/fill_results.py.
  {
    FILE *csv = fopen("../data/dense_solve_report.csv", "w");
    if (csv) {
      fprintf(csv, "n,m,Conv_s,SW_comp_s,HW_s,Speedup,Fair_Speedup,SNR_dB,MaxRelErr_pct,Status,"
                   "SW_Energy_J,SW_AvgPower_W,HW_Energy_J,HW_AvgPower_W,HW_PeakPower_W,SampleWindow_s,Energy_HW_per_SW,"
                   "SW_chol_s,Speedup_chol,SNR_chol_dB,MaxRelErr_chol_pct,SW_chol_Energy_J,SW_chol_AvgPower_W,Pass_chol\n");
      for (uint32_t i = 0; i < numSizes; ++i) {
        double e_ratio = (results[i].sw_energy_j > 0.0)
                         ? (results[i].energy_j / results[i].sw_energy_j) : 0.0;
        bool allPass = results[i].pass && results[i].pass_chol;
        fprintf(csv, "%" PRIu32 ",%" PRIu32 ",%.9f,%.9f,%.9f,%.2f,%.2f,%.1f,%.4f,%s,"
                     "%.6f,%.3f,%.6f,%.3f,%.3f,%.6f,%.6f,"
                     "%.9f,%.2f,%.1f,%.4f,%.6f,%.3f,%d\n",
                results[i].n, results[i].m,
                results[i].convTime_s, results[i].swTime_s, results[i].hwTime_s,
                results[i].speedup, results[i].fairSpeedup, results[i].snr_db,
                results[i].maxRelErr * 100.0,
                allPass ? "PASS" : "FAIL",
                results[i].sw_energy_j, results[i].sw_avgPower_w,
                results[i].energy_j, results[i].avgPower_w,
                results[i].peakPower_w, results[i].sampleWindow_s, e_ratio,
                results[i].swCholTime_s, results[i].speedup_chol, results[i].snr_chol_db,
                results[i].maxRelErr_chol * 100.0,
                results[i].sw_chol_energy_j, results[i].sw_chol_avgPower_w,
                results[i].pass_chol ? 1 : 0);
      }
      fclose(csv);
      printf("CSV report written to ../data/dense_solve_report.csv\n");
    } else {
      printf("Warning: could not open ../data/dense_solve_report.csv for writing\n");
    }
  }

  {
    FILE *txt = fopen("../data/dense_solve_report.txt", "w");
    if (txt) {
      fprintf(txt, "==================================================== DENSE SOLVE REPORT ====================================================\n");
      fprintf(txt, "%5s %5s %9s %10s %10s %10s %8s %8s %7s %7s %7s %8s %8s %8s\n",
              "n", "m", "Conv(s)", "SW_g(s)", "SW_c(s)", "HW(s)",
              "Spd_g", "Spd_c", "SNR_g", "SNR_c", "Status",
              "SW_g_E", "SW_c_E", "HW_E");
      fprintf(txt, "----------------------------------------------------------------------------------------------------------------------------\n");
      for (uint32_t i = 0; i < numSizes; ++i) {
        bool allPass = results[i].pass && results[i].pass_chol;
        fprintf(txt, "%5" PRIu32 " %5" PRIu32 " %9.6f %10.6f %10.6f %10.6f %7.2fx %7.2fx %7.1f %7.1f %7s %8.4f %8.4f %8.4f\n",
                results[i].n, results[i].m,
                results[i].convTime_s,
                results[i].swTime_s, results[i].swCholTime_s, results[i].hwTime_s,
                results[i].speedup, results[i].speedup_chol,
                results[i].snr_db, results[i].snr_chol_db,
                allPass ? "PASS" : "FAIL",
                results[i].sw_energy_j, results[i].sw_chol_energy_j, results[i].energy_j);
      }
      fprintf(txt, "============================================================================================================================\n");
      uint32_t passed = 0;
      for (uint32_t i = 0; i < numSizes; ++i)
        if (results[i].pass && results[i].pass_chol) ++passed;
      fprintf(txt, "Total: %" PRIu32 "/%" PRIu32 " passed (HW vs both SW references)\n",
              passed, numSizes);
      fclose(txt);
      printf("Text report written to ../data/dense_solve_report.txt\n");
    } else {
      printf("Warning: could not open ../data/dense_solve_report.txt for writing\n");
    }
  }

  // Free the DMA memory. ---IMPORTANT--- DMA memory is a system-wide resource!!!
  if (inputHW != NULL)
    solver.FreeDMACompatible(inputHW);
  if (outputHW != NULL)
    solver.FreeDMACompatible(outputHW);

  return errors ? -1 : 0;
}
