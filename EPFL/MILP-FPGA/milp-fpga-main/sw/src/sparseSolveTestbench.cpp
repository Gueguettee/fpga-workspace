// SparseSolve board-side testbench: loads SPLA fixtures, packs them into the
// kernel's AXI input layout (hw/kernels/sparse_solve/src/sparse_solve.h),
// runs the FPGA, and compares dy against the float64 reference in the fixture.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>

#include "CAccelProxy.hpp"
#include "CSparseSolveProxy.hpp"
#include "util.hpp"

#include "fxp_utils.h"
#include "constants.h"
#include "pmt_power_meter.h"
#include "measure_helpers.h"
#include "sparse_sw_ref.h"

// Pure-CPU dense Gaussian-elimination reference (sw/src/linalg.c). Used here
// as the SW baseline for the sparse-HW vs dense-SW comparison on the same
// fixture inputs. linalg.c is compiled by g++ under the same Makefile (no
// extern "C" — both translation units use C++ name mangling, matching how
// lp_ipm.c calls dense_solve in Makefile.milp_bnb).
int dense_solve(int n, double *K, const double *rhs, double *x);

#define SPARSE_SOLVE_HW_ADDR 0xA0000000
#define MAP_SIZE (64 * 1024)

// Same tolerance budget as the dense tb.
static const double REL_TOL    = 0.50;
static const double ABS_TOL    = 2.0;
static const double MIN_SNR_DB = 15.0;

// Fixture format (mirrors python/sparse_solve/fixture_format.py).
static const uint32_t FIX_MAGIC_KFORM = 0x53504C41u;  // "SPLA"
static const uint32_t FIX_VERSION     = 1u;

// Worst-case input buffer at the SPARSE_MAX_* ceilings:
//   4*(m+1) + 2*nnz_A + n + nnz_K + 3*nnz_L + m
#define MAX_INPUT_WORDS (4 * (SPARSE_MAX_M + 1) + 2 * SPARSE_MAX_NNZ_A         \
                          + SPARSE_MAX_N + SPARSE_MAX_NNZ_K                    \
                          + 3 * SPARSE_MAX_NNZ_L + SPARSE_MAX_M)
#define MAX_OUTPUT_WORDS SPARSE_MAX_M

struct TestResult {
  const char *name;
  uint32_t m;
  uint32_t n;
  uint32_t nnz_A;
  uint32_t nnz_K;
  uint32_t nnz_L;
  // HW (FPGA sparse) measurements
  double   hwTime_s;
  double   snr_db;
  double   maxRelErr;
  bool     pass;
  // Per-phase iteration counts read back via AXI-Lite after ap_done.
  // Lower-bound phase time = iters * 5e-9 s @ 200 MHz; actual is higher
  // (pipeline drain + DDR stalls).
  uint32_t kform_iters;
  uint32_t factor_iters;
  uint32_t triangular_iters;
  double   energy_j;
  double   avgPower_w;
  double   peakPower_w;
  double   sampleWindow_s;
  // SW (ARM dense Gaussian) measurements
  double   convTime_s;     // FXP -> double conversion + densify (outside compute)
  double   swTime_s;       // K-form + dense_solve (pure compute)
  double   speedup;        // swTime_s / hwTime_s
  double   fairSpeedup;    // swTime_s / (hwTime_s + convTime_s) — penalises HW for needing FXP-formatted inputs
  double   sw_snr_db;
  double   sw_maxRelErr;
  bool     sw_pass;
  double   sw_energy_j;
  double   sw_avgPower_w;
  double   sw_peakPower_w;
  // SW (ARM sparse simplicial LDL^T — same algorithm as the FPGA kernel) measurements
  double   convSpTime_s;   // FXP -> double + symbolic int extraction
  double   swSpTime_s;     // sparse K-form + factor + triangular solves
  double   speedup_sp;     // swSpTime_s / hwTime_s
  double   sw_sp_snr_db;
  double   sw_sp_maxRelErr;
  bool     sw_sp_pass;
  double   sw_sp_energy_j;
  double   sw_sp_avgPower_w;
  double   sw_sp_peakPower_w;
};

// Reference dy comes back as float64; the tb only needs dy_expected for the
// basic SNR check (the diagnostic L_values_csc_expected / Dv_expected / K_values
// trailing fields in the fixture are skipped on the board).
static double g_dy_expected[SPARSE_MAX_M];


// Default list when no fixtures are passed on the command line. Bisect-friendly
// order: smallest first, square dense (m=n) from 4 to 256 and random sparse only
// at m=256 (pure-random A goes rank-deficient at larger m once density is low
// enough to fit fill), then banded fixtures (UC-like block-bidiagonal structure)
// at m=512/1024/1848/4096 which own the large-m range, then real UC LP-relaxation
// fixtures (rank-filtered host-side) at micro/xs/s scales.
#define NUM_DEFAULT_FIXTURES 30
static const char *g_default_fixtures[NUM_DEFAULT_FIXTURES] = {
  "kform_dense_4.bin",
  "kform_dense_8.bin",
  "kform_dense_16.bin",
  "kform_dense_32.bin",
  "kform_dense_64.bin",
  "kform_dense_128.bin",
  "kform_dense_256.bin",
  "kform_sparse_32.bin",
  "kform_sparse_64.bin",
  "kform_sparse_128.bin",
  "kform_sparse_256.bin",
  "kform_banded_512.bin",
  "kform_banded_1024.bin",
  "kform_banded_1848.bin",
  "kform_banded_4096.bin",
  "kform_uc_micro_T6.bin",
  "kform_uc_micro_T12.bin",
  "kform_uc_xs_T6.bin",
  "kform_uc_xs_T12.bin",
  "kform_uc_xs_T24.bin",
  "kform_uc_s_T12.bin",
  "kform_uc_s_T24.bin",
  "kform_uc_m_T12.bin",
  "kform_uc_m_T24.bin",
  // In-range UC l-scale set (thesis per-iteration kernel speed/energy sweep).
  // l_T28 is omitted (redundant near the crossover) and l_T48 is excluded
  // (n=9600 > SPARSE_MAX_N=8192, will not run in this configuration).
  "kform_uc_l_T6.bin",
  "kform_uc_l_T12.bin",
  "kform_uc_l_T18.bin",
  "kform_uc_l_T24.bin",
  "kform_uc_l_T30.bin",
  "kform_uc_l_T36.bin",
};

///////////////////////////////////////////////////////////////////////////////
// Zero-fill via 32-bit stores; CMA Device-type memory rejects NEON 128-bit
// stores from glibc memset on aarch64. (Same trick the dense tb uses.)
static void ZeroFill32(void *dst, size_t bytes)
{
  volatile uint32_t *p = (volatile uint32_t *)dst;
  size_t count = bytes / sizeof(uint32_t);
  for (size_t i = 0; i < count; ++i) p[i] = 0;
}

static int read_exact(FILE *f, void *buf, size_t n) {
  return fread(buf, 1, n, f) == n ? 0 : -1;
}

// Fixtures live next to the bitstream; deploy.sh syncs them to
// /home/xilinx/milp-fpga/hw/sparse_solve/fixtures/. Try a couple of paths
// so the same binary works whether you're cd'd into sw/ or hw/.
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

// int128-array readers: each value is (int64 low, int64 high). Q17.54 fits
// int64 so the high half is just sign extension; we drop it.
static int read_int128_to_tfxp(FILE *f, TFXP *dst, uint32_t n) {
  for (uint32_t i = 0; i < n; i++) {
    int64_t lo, hi;
    if (read_exact(f, &lo, sizeof(lo))) return -1;
    if (read_exact(f, &hi, sizeof(hi))) return -1;
    (void)hi;
    dst[i] = (TFXP)lo;
  }
  return 0;
}

static int load_uint32_into_tfxp(FILE *f, TFXP *dst, uint32_t n) {
  uint32_t buf;
  for (uint32_t i = 0; i < n; i++) {
    if (read_exact(f, &buf, sizeof(buf))) return -1;
    dst[i] = (TFXP)(int64_t)(uint64_t)buf;
  }
  return 0;
}

static int load_uint16_into_tfxp_padded(FILE *f, TFXP *dst, uint32_t n) {
  uint16_t buf;
  for (uint32_t i = 0; i < n; i++) {
    if (read_exact(f, &buf, sizeof(buf))) return -1;
    dst[i] = (TFXP)(int64_t)(uint64_t)buf;
  }
  size_t pad = (-(sizeof(uint16_t) * (size_t)n)) & 3;
  if (pad) {
    char dummy[4];
    if (read_exact(f, dummy, pad)) return -1;
  }
  return 0;
}

// Read the fixture and pack it directly into the DMA-mapped input buffer in
// the layout the SparseSolve kernel expects (see sparse_solve.cpp).
static int load_kform_fixture_into_input(const char *name,
                                         TFXP *inputHW,
                                         uint32_t *m_out, uint32_t *n_out,
                                         uint32_t *nnz_A_out,
                                         uint32_t *nnz_K_out,
                                         uint32_t *nnz_L_out)
{
  FILE *f = open_fixture(name);
  if (!f) {
    printf("  ERROR: cannot find fixture '%s'\n", name);
    return -1;
  }

  uint32_t magic, version, m, n, nnz_A, nnz_K, nnz_L;
  if (read_exact(f, &magic, 4) || read_exact(f, &version, 4) ||
      read_exact(f, &m, 4) || read_exact(f, &n, 4) ||
      read_exact(f, &nnz_A, 4) || read_exact(f, &nnz_K, 4) ||
      read_exact(f, &nnz_L, 4)) {
    fclose(f); return -1;
  }
  if (magic != FIX_MAGIC_KFORM || version != FIX_VERSION) {
    printf("  ERROR: bad magic 0x%08x or version %u\n", magic, version);
    fclose(f); return -1;
  }
  if (m > SPARSE_MAX_M || n > SPARSE_MAX_N || nnz_A > SPARSE_MAX_NNZ_A ||
      nnz_K > SPARSE_MAX_NNZ_K || nnz_L > SPARSE_MAX_NNZ_L) {
    printf("  ERROR: dimensions exceed SPARSE_MAX_* (rebuild with larger ceilings)\n");
    fclose(f); return -1;
  }

  uint32_t off = 0;

  if (load_uint32_into_tfxp(f, &inputHW[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &inputHW[off], nnz_A)) { fclose(f); return -1; }
  off += nnz_A;
  if (read_int128_to_tfxp(f, &inputHW[off], nnz_A)) { fclose(f); return -1; }
  off += nnz_A;
  if (read_int128_to_tfxp(f, &inputHW[off], n)) { fclose(f); return -1; }
  off += n;

  if (load_uint32_into_tfxp(f, &inputHW[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &inputHW[off], nnz_K)) { fclose(f); return -1; }
  off += nnz_K;

  if (load_uint32_into_tfxp(f, &inputHW[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &inputHW[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;

  if (load_uint32_into_tfxp(f, &inputHW[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &inputHW[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;
  // Skip the fixture's L_csc_pos slot — kernel uses L_csr_pos (next slot).
  if (fseek(f, (long)(sizeof(uint32_t) * nnz_L), SEEK_CUR)) { fclose(f); return -1; }
  if (load_uint32_into_tfxp(f, &inputHW[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;

  if (read_int128_to_tfxp(f, &inputHW[off], m)) { fclose(f); return -1; }
  // off += m;  // not needed past this point

  // dy_expected (float64) — used for the comparison below.
  if (read_exact(f, g_dy_expected, sizeof(double) * m)) { fclose(f); return -1; }

  // Trailing diagnostic fields (K_values_expected, etc.) are present in the
  // fixture but skipped on the board to keep the host working set small.

  fclose(f);
  *m_out = m; *n_out = n;
  *nnz_A_out = nnz_A; *nnz_K_out = nnz_K; *nnz_L_out = nnz_L;
  return 0;
}

///////////////////////////////////////////////////////////////////////////////
static bool CompareDy(const double *expected, const TFXP *hw, uint32_t m,
                      double &out_snr, double &out_maxRelErr)
{
  bool ok = true;
  double maxRelErr = 0.0;
  double sumSqErr = 0.0;
  double sumSqRef = 0.0;

  for (uint32_t i = 0; i < m; i++) {
    double swVal = expected[i];
    double hwVal = Fxp2Double(hw[i]);
    double diff  = fabs(swVal - hwVal);
    double denom = fabs(swVal);
    double relErr = (denom > ABS_TOL) ? diff / denom : diff;

    sumSqErr += diff * diff;
    sumSqRef += swVal * swVal;
    if (relErr > maxRelErr) maxRelErr = relErr;

    if (diff > ABS_TOL && relErr > REL_TOL) {
      printf("  Mismatch at [%" PRIu32 "]: SW=%.6f HW=%.6f (relErr=%.2f%%)\n",
             i, swVal, hwVal, relErr * 100.0);
      ok = false;
    }
  }

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
// Compare a SW (already-double) dy against the float64 golden reference.
// Mirrors CompareDy but skips the Fxp2Double on the actuals.
static bool CompareDyDouble(const double *expected, const double *sw, uint32_t m,
                            double &out_snr, double &out_maxRelErr)
{
  bool ok = true;
  double maxRelErr = 0.0;
  double sumSqErr = 0.0;
  double sumSqRef = 0.0;

  for (uint32_t i = 0; i < m; i++) {
    double swVal  = expected[i];
    double calVal = sw[i];
    double diff   = fabs(swVal - calVal);
    double denom  = fabs(swVal);
    double relErr = (denom > ABS_TOL) ? diff / denom : diff;

    sumSqErr += diff * diff;
    sumSqRef += swVal * swVal;
    if (relErr > maxRelErr) maxRelErr = relErr;

    if (diff > ABS_TOL && relErr > REL_TOL) {
      printf("  SW Mismatch at [%" PRIu32 "]: ref=%.6f sw=%.6f (relErr=%.2f%%)\n",
             i, swVal, calVal, relErr * 100.0);
      ok = false;
    }
  }

  double snr_db = (sumSqErr > 0.0) ? 10.0 * log10(sumSqRef / sumSqErr) : INFINITY;
  printf("  SW SNR=%.1f dB  maxRelErr=%.2f%%\n", snr_db, maxRelErr * 100.0);
  if (snr_db < MIN_SNR_DB) {
    printf("  SW SNR below %.1f dB threshold!\n", MIN_SNR_DB);
    ok = false;
  }

  out_snr = snr_db;
  out_maxRelErr = maxRelErr;
  return ok;
}

///////////////////////////////////////////////////////////////////////////////
// Re-decode the kform fixture inputs from the packed AXI input buffer into
// the double arrays the SW reference needs:
//   - Ad  : densified A (m * n row-major)
//   - D   : diag(D)            (length n)
//   - b   : RHS                (length m)
//
// Layout matches load_kform_fixture_into_input above:
//   off 0                 : A_indptr[m+1]   (uint32, packed in TFXP)
//   off m+1               : A_indices[nnz_A](uint16, packed in TFXP)
//   off m+1+nnz_A         : A_values[nnz_A] (Q17.54 in TFXP)
//   off m+1+2*nnz_A       : D[n]             (Q17.54 in TFXP)
//   ... K/L symbolic blocks ...
//   off 4*(m+1)+2*nnz_A+n+nnz_K+3*nnz_L : b[m] (Q17.54 in TFXP)
//
// `Ad` is fully zeroed for the m*n window before being filled — densification
// only writes the structural nonzeros.
static void extract_double_inputs_from_fxp(const TFXP *inputHW,
                                           uint32_t m, uint32_t n,
                                           uint32_t nnz_A,
                                           uint32_t nnz_K, uint32_t nnz_L,
                                           double *Ad, double *D, double *b)
{
  const TFXP *p_indptr  = inputHW;
  const TFXP *p_indices = p_indptr + (m + 1);
  const TFXP *p_values  = p_indices + nnz_A;
  const TFXP *p_D       = p_values + nnz_A;

  // b sits past the K and L symbolic blocks (see MAX_INPUT_WORDS above).
  uint32_t b_off = 4u * (m + 1u) + 2u * nnz_A + n + nnz_K + 3u * nnz_L;
  const TFXP *p_b = inputHW + b_off;

  // Densify A: zero the live window, then scatter the nonzeros.
  for (uint32_t i = 0; i < m * n; i++) Ad[i] = 0.0;
  for (uint32_t i = 0; i < m; i++) {
    uint32_t row_start = (uint32_t)(int64_t)p_indptr[i];
    uint32_t row_end   = (uint32_t)(int64_t)p_indptr[i + 1];
    for (uint32_t k = row_start; k < row_end; k++) {
      uint32_t col = (uint32_t)(int64_t)p_indices[k];
      Ad[i * n + col] = Fxp2Double(p_values[k]);
    }
  }

  for (uint32_t j = 0; j < n; j++) D[j] = Fxp2Double(p_D[j]);
  for (uint32_t i = 0; i < m; i++) b[i] = Fxp2Double(p_b[i]);
}

///////////////////////////////////////////////////////////////////////////////
// SW reference: K = A * diag(D) * A^T (m x m dense), then dense_solve.
// Mirrors the sw/src/lp_ipm.c:175-200 pipeline. K is overwritten by
// dense_solve, so callers wanting NUM_REPES > 1 re-run this whole function
// per repetition (which is also what we want — the FPGA pipeline includes
// K-formation, so timing it inside the SW window is the apples-to-apples
// comparison).
static int KFormAndDenseSolve_SW(const double *Ad, const double *D,
                                 const double *b,
                                 uint32_t m, uint32_t n,
                                 double *K, double *dy)
{
  for (uint32_t i = 0; i < m; i++) {
    for (uint32_t k2 = 0; k2 < m; k2++) {
      double sum = 0.0;
      for (uint32_t j = 0; j < n; j++) {
        double aij = Ad[i * n + j];
        double akj = Ad[k2 * n + j];
        if (aij == 0.0 || akj == 0.0) continue;
        sum += aij * D[j] * akj;
      }
      K[i * m + k2] = sum;
    }
  }
  return dense_solve((int)m, K, b, dy);
}

///////////////////////////////////////////////////////////////////////////////
// Re-decode the kform fixture into the int + double arrays the SW *sparse*
// reference needs (CSR A_perm, D, b_perm, K pattern, L pattern + L row-CSR
// view). Same byte layout as load_kform_fixture_into_input — see that
// function for the per-section comments.
static void extract_sparse_inputs_from_fxp(const TFXP *inputHW,
                                           uint32_t m, uint32_t n,
                                           uint32_t nnz_A,
                                           uint32_t nnz_K, uint32_t nnz_L,
                                           int32_t *A_indptr, int32_t *A_indices,
                                           double  *A_values,
                                           double  *D, double *b,
                                           int32_t *K_colptr, int32_t *K_rowidx,
                                           int32_t *L_colptr, int32_t *L_rowidx_csc,
                                           int32_t *L_rowptr, int32_t *L_colidx_csr,
                                           int32_t *L_csc_pos)
{
  const TFXP *p = inputHW;

  for (uint32_t i = 0; i < m + 1; i++) A_indptr[i]  = (int32_t)(int64_t)*p++;
  for (uint32_t k = 0; k < nnz_A; k++) A_indices[k] = (int32_t)(int64_t)*p++;
  for (uint32_t k = 0; k < nnz_A; k++) A_values[k]  = Fxp2Double(*p++);
  for (uint32_t j = 0; j < n;     j++) D[j]         = Fxp2Double(*p++);

  for (uint32_t i = 0; i < m + 1; i++) K_colptr[i]   = (int32_t)(int64_t)*p++;
  for (uint32_t k = 0; k < nnz_K; k++) K_rowidx[k]   = (int32_t)(int64_t)*p++;

  for (uint32_t i = 0; i < m + 1; i++) L_colptr[i]   = (int32_t)(int64_t)*p++;
  for (uint32_t k = 0; k < nnz_L; k++) L_rowidx_csc[k]   = (int32_t)(int64_t)*p++;

  for (uint32_t i = 0; i < m + 1; i++) L_rowptr[i]      = (int32_t)(int64_t)*p++;
  for (uint32_t k = 0; k < nnz_L; k++) L_colidx_csr[k]  = (int32_t)(int64_t)*p++;
  // Input packs L_csr_pos (CSC pos p → CSR slot q); SW reference wants the
  // inverse L_csc_pos (CSR slot q → CSC pos p). Invert here.
  for (uint32_t k = 0; k < nnz_L; k++) {
    int32_t csr_pos = (int32_t)(int64_t)*p++;
    L_csc_pos[csr_pos] = (int32_t)k;
  }

  for (uint32_t i = 0; i < m;     i++) b[i] = Fxp2Double(*p++);
}

// SW sparse reference KFormFactorSolve_SparseSW lives in sparse_sw_ref.{h,cpp}.

///////////////////////////////////////////////////////////////////////////////
static bool InitDevice(CSparseSolveProxy &solver, TFXP* &inputHW,
                       TFXP* &outputHW)
{
  printf("\n\nThis program requires that the bitstream is loaded in the FPGA.\n");
  printf("This program must be run with sudo.\n\n");

  if (solver.Open(SPARSE_SOLVE_HW_ADDR, MAP_SIZE) != CAccelProxy::OK) {
    printf("Error mapping device at physical address 0x%08X\n", SPARSE_SOLVE_HW_ADDR);
    return false;
  }
  printf("Device at 0x%08X mapped into virtual address space\n\n", SPARSE_SOLVE_HW_ADDR);

  printf("Allocating DMA memory...\n");
  inputHW  = (TFXP *)solver.AllocDMACompatible(MAX_INPUT_WORDS  * sizeof(TFXP));
  outputHW = (TFXP *)solver.AllocDMACompatible(MAX_OUTPUT_WORDS * sizeof(TFXP));
  if (!inputHW || !outputHW) {
    printf("Error allocating DMA memory.\n");
    return false;
  }
  printf("DMA memory allocated.\n");
  printf("Input          %p (%zu B)\n", (void*)inputHW,  MAX_INPUT_WORDS  * sizeof(TFXP));
  printf("Output         %p (%zu B)\n", (void*)outputHW, MAX_OUTPUT_WORDS * sizeof(TFXP));
  return true;
}

///////////////////////////////////////////////////////////////////////////////
int main(int argc, char **argv)
{
  struct timespec t0, t1;
  CSparseSolveProxy solver(/*Logging=*/false);
  TFXP *inputHW = NULL;
  TFXP *outputHW = NULL;

  if (!InitDevice(solver, inputHW, outputHW)) return 1;

  PmtPowerMeter pwr;
  bool powerOk = pwr.Probe();
  if (powerOk) {
    printf("PMT: %zu rail(s) detected\n", pwr.Rails().size());
    for (const auto& r : pwr.Rails())
      printf("  - %s (%s)\n", r.name.c_str(), r.path.c_str());
  } else {
    printf("PMT: no hwmon rails detected — energy columns will be 0\n");
  }

  // SW reference workspace (host-RAM doubles). Sized at the SPARSE_MAX_*
  // ceilings so a single allocation covers every fixture in the run.
  // m=256, n=1024 cap → Ad ~2 MB, K ~0.5 MB; trivial on ZCU104.
  double *Ad_d = (double *)calloc((size_t)SPARSE_MAX_M * SPARSE_MAX_N, sizeof(double));
  double *K_d  = (double *)calloc((size_t)SPARSE_MAX_M * SPARSE_MAX_M, sizeof(double));
  double *D_d  = (double *)calloc((size_t)SPARSE_MAX_N, sizeof(double));
  double *b_d  = (double *)calloc((size_t)SPARSE_MAX_M, sizeof(double));
  double *dy_sw = (double *)calloc((size_t)SPARSE_MAX_M, sizeof(double));
  if (!Ad_d || !K_d || !D_d || !b_d || !dy_sw) {
    printf("ERROR: failed to allocate SW dense workspace\n");
    return 1;
  }

  // SW sparse reference workspace (mirrors numeric_reference.py).
  int32_t *A_indptr_i  = (int32_t *)calloc((size_t)SPARSE_MAX_M + 1, sizeof(int32_t));
  int32_t *A_indices_i = (int32_t *)calloc((size_t)SPARSE_MAX_NNZ_A, sizeof(int32_t));
  double  *A_values_d  = (double  *)calloc((size_t)SPARSE_MAX_NNZ_A, sizeof(double));
  int32_t *K_colptr_i  = (int32_t *)calloc((size_t)SPARSE_MAX_M + 1, sizeof(int32_t));
  int32_t *K_rowidx_i  = (int32_t *)calloc((size_t)SPARSE_MAX_NNZ_K, sizeof(int32_t));
  int32_t *L_colptr_i  = (int32_t *)calloc((size_t)SPARSE_MAX_M + 1, sizeof(int32_t));
  int32_t *L_rowidx_i  = (int32_t *)calloc((size_t)SPARSE_MAX_NNZ_L, sizeof(int32_t));
  int32_t *L_rowptr_i  = (int32_t *)calloc((size_t)SPARSE_MAX_M + 1, sizeof(int32_t));
  int32_t *L_cic_i     = (int32_t *)calloc((size_t)SPARSE_MAX_NNZ_L, sizeof(int32_t));
  int32_t *L_vp_i      = (int32_t *)calloc((size_t)SPARSE_MAX_NNZ_L, sizeof(int32_t));
  double  *K_values_d  = (double  *)calloc((size_t)SPARSE_MAX_NNZ_K, sizeof(double));
  double  *L_values_csc_d  = (double  *)calloc((size_t)SPARSE_MAX_NNZ_L, sizeof(double));
  double  *Dv_d        = (double  *)calloc((size_t)SPARSE_MAX_M, sizeof(double));
  double  *dy_sp_sw    = (double  *)calloc((size_t)SPARSE_MAX_M, sizeof(double));
  double  *w_d         = (double  *)calloc((size_t)SPARSE_MAX_M, sizeof(double));
  int32_t *flag_i      = (int32_t *)calloc((size_t)SPARSE_MAX_M, sizeof(int32_t));
  if (!A_indptr_i || !A_indices_i || !A_values_d || !K_colptr_i || !K_rowidx_i ||
      !L_colptr_i || !L_rowidx_i || !L_rowptr_i || !L_cic_i || !L_vp_i ||
      !K_values_d || !L_values_csc_d || !Dv_d || !dy_sp_sw || !w_d || !flag_i) {
    printf("ERROR: failed to allocate SW sparse workspace\n");
    return 1;
  }

  // Pick fixture list from argv or fall back to the default battery.
  // Each argv entry is a fixture base name; we tolerate names with or
  // without the trailing ".bin" and with or without a leading "kform_".
  const char *fixture_list[NUM_DEFAULT_FIXTURES + 16];
  static char arg_bufs[16][256];  // for normalized names from argv
  int num_fixtures = 0;
  if (argc > 1) {
    int max_argv = (argc - 1 > 16) ? 16 : (argc - 1);
    for (int i = 0; i < max_argv; i++) {
      const char *raw = argv[1 + i];
      const char *base = raw;
      // Allow "dense_8" → "kform_dense_8.bin"
      if (strncmp(raw, "kform_", 6) != 0) {
        snprintf(arg_bufs[i], sizeof(arg_bufs[i]), "kform_%s", raw);
      } else {
        snprintf(arg_bufs[i], sizeof(arg_bufs[i]), "%s", raw);
      }
      size_t len = strlen(arg_bufs[i]);
      if (len < 4 || strcmp(arg_bufs[i] + len - 4, ".bin") != 0) {
        snprintf(arg_bufs[i] + len, sizeof(arg_bufs[i]) - len, ".bin");
      }
      fixture_list[num_fixtures++] = arg_bufs[i];
      (void)base;
    }
    printf("Running %d user-selected fixture(s):\n", num_fixtures);
    for (int i = 0; i < num_fixtures; i++)
      printf("  - %s\n", fixture_list[i]);
  } else {
    for (int i = 0; i < NUM_DEFAULT_FIXTURES; i++)
      fixture_list[num_fixtures++] = g_default_fixtures[i];
  }

  TestResult *results = (TestResult *)calloc(num_fixtures, sizeof(TestResult));
  bool any_fail = false;

  for (int fi = 0; fi < num_fixtures; fi++) {
    const char *name = fixture_list[fi];
    printf("\n=== fixture %s ===\n", name);

    // Only wipe outputHW (small, ~4 KB). inputHW gets overwritten by the
    // packing call below, and zeroing the full 4 MB DMA buffer between
    // fixtures was burning ~50 ms per iteration on non-cacheable Device
    // memory for no benefit.
    ZeroFill32(outputHW, MAX_OUTPUT_WORDS * sizeof(TFXP));

    uint32_t m = 0, n = 0, nnz_A = 0, nnz_K = 0, nnz_L = 0;
    if (load_kform_fixture_into_input(name, inputHW,
                                      &m, &n, &nnz_A, &nnz_K, &nnz_L)) {
      results[fi].name = name; results[fi].pass = false;
      any_fail = true; continue;
    }

    printf("  m=%u n=%u nnz_A=%u nnz_K=%u nnz_L=%u\n", m, n, nnz_A, nnz_K, nnz_L);

    // SETUP once per fixture: loads patterns into the kernel's static on-chip
    // arrays + DDR L pattern. Subsequent SOLVE calls reuse them, simulating
    // the per-iter cost of an IPM driver. We time the SOLVE calls only.
    {
      uint32_t st = solver.SparseSolve_HW(inputHW, outputHW,
                                          m, n, nnz_A, nnz_K, nnz_L,
                                          CSparseSolveProxy::MODE_SETUP);
      if (st != CAccelProxy::OK) {
        printf("  ERROR: SparseSolve_HW(SETUP) returned %u\n", st);
        results[fi].name = name; results[fi].pass = false;
        any_fail = true; continue;
      }
    }

    uint32_t kf_it = 0, fc_it = 0, tr_it = 0;
    bool hw_failed = false;
    double cum_hw_s = 0.0;
    uint32_t reps_hw = measure_adaptive(pwr, [&](uint32_t /*rep*/) {
      if (hw_failed) return;
      uint32_t st = solver.SparseSolve_HW(inputHW, outputHW,
                                          m, n, nnz_A, nnz_K, nnz_L,
                                          CSparseSolveProxy::MODE_SOLVE,
                                          &kf_it, &fc_it, &tr_it);
      if (st != CAccelProxy::OK) {
        printf("  ERROR: SparseSolve_HW(SOLVE) returned %u\n", st);
        any_fail = true; hw_failed = true;
      }
    }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS, &cum_hw_s);

    double hw_s = cum_hw_s / reps_hw;
    double energy_j = pwr.TotalEnergyJ() / reps_hw;
    double avgW     = pwr.AvgPowerW();
    double peakW    = pwr.PeakPowerW();
    double window_s = pwr.WindowSeconds();

    double snr = 0.0, maxRel = 0.0;
    bool ok = CompareDy(g_dy_expected, outputHW, m, snr, maxRel);
    if (!ok) any_fail = true;

    results[fi].name = name;
    results[fi].m = m; results[fi].n = n;
    results[fi].nnz_A = nnz_A; results[fi].nnz_K = nnz_K; results[fi].nnz_L = nnz_L;
    results[fi].hwTime_s = hw_s;
    results[fi].snr_db = snr;
    results[fi].maxRelErr = maxRel;
    results[fi].pass = ok;
    results[fi].energy_j = energy_j;
    results[fi].avgPower_w = avgW;
    results[fi].peakPower_w = peakW;
    results[fi].sampleWindow_s = window_s;
    results[fi].kform_iters      = kf_it;
    results[fi].factor_iters     = fc_it;
    results[fi].triangular_iters = tr_it;

    printf("(HW) %s --> %.6f s  |  %.4f J/call  avg %.2f W  peak %.2f W (window %.3f s)\n",
           name, hw_s, energy_j, avgW, peakW, window_s);
    {
      uint64_t total_it = (uint64_t)kf_it + fc_it + tr_it;
      if (total_it > 0) {
        double kf_pct = 100.0 * kf_it / total_it;
        double fc_pct = 100.0 * fc_it / total_it;
        double tr_pct = 100.0 * tr_it / total_it;
        // Idealised lower-bound time @ 200 MHz (5 ns/cycle, II=1).
        double kf_lb_ms = kf_it * 5e-6;
        double fc_lb_ms = fc_it * 5e-6;
        double tr_lb_ms = tr_it * 5e-6;
        double hw_ms    = hw_s * 1000.0;
        printf("     iters: kform=%u (%.1f%%, lb %.3f ms) factor=%u (%.1f%%, lb %.3f ms) "
               "tri=%u (%.1f%%, lb %.3f ms) | total %llu / measured %.3f ms (stall ~%.1fx)\n",
               kf_it, kf_pct, kf_lb_ms,
               fc_it, fc_pct, fc_lb_ms,
               tr_it, tr_pct, tr_lb_ms,
               (unsigned long long)total_it, hw_ms,
               hw_ms / (kf_lb_ms + fc_lb_ms + tr_lb_ms + 1e-9));
      } else {
        printf("     iters: all zero (counter readback may be wrong — verify TRegs offsets)\n");
      }
    }

    // ------------------------------------------------------------------
    // SW reference: ARM Cortex-A53 dense Gaussian-elimination on the same
    // (A, D, b) inputs. K-formation + dense_solve is timed together to
    // mirror the FPGA pipeline (which also includes K-formation).
    // FXP→double conversion is timed separately (Conv_s) — analogue of
    // dense_solve_report.csv's Conv_s/SW_comp_s split.
    // ------------------------------------------------------------------
    clock_gettime(CLOCK_MONOTONIC, &t0);
    extract_double_inputs_from_fxp(inputHW, m, n, nnz_A, nnz_K, nnz_L,
                                   Ad_d, D_d, b_d);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double conv_s = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) * 1e-9;

    // Skip the SW dense LU reference above this m — it's O(m^3) and only
    // used to compute Spd_d (informational); HW correctness comes from the
    // sparse float64 golden in the fixture.
    const uint32_t SW_DENSE_MAX_M = 1024;

    double sw_s = 0.0, sw_energy_j = 0.0, sw_avgW = 0.0, sw_peakW = 0.0;
    double sw_snr = 0.0, sw_maxRel = 0.0;
    bool sw_ok = true;
    int sw_status = 0;
    bool sw_skipped = (m > SW_DENSE_MAX_M);

    if (!sw_skipped) {
      bool sw_failed = false;
      double cum_sw_s = 0.0;
      uint32_t reps_sw = measure_adaptive(pwr, [&](uint32_t /*rep*/) {
        if (sw_failed) return;
        sw_status = KFormAndDenseSolve_SW(Ad_d, D_d, b_d, m, n, K_d, dy_sw);
        if (sw_status != 0) sw_failed = true;
      }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS, &cum_sw_s);

      sw_s = cum_sw_s / reps_sw;
      sw_energy_j = pwr.TotalEnergyJ() / reps_sw;
      sw_avgW     = pwr.AvgPowerW();
      sw_peakW    = pwr.PeakPowerW();

      if (sw_status != 0) {
        printf("  ERROR: dense_solve returned %d (singular K)\n", sw_status);
        any_fail = true;
        sw_ok = false;
      } else {
        sw_ok = CompareDyDouble(g_dy_expected, dy_sw, m, sw_snr, sw_maxRel);
        if (!sw_ok) any_fail = true;
      }
    } else {
      printf("(SW dense ) %s --> SKIPPED (m=%u > %u, O(m^3) too slow)\n",
             name, m, SW_DENSE_MAX_M);
    }

    double speedup     = (hw_s > 0.0)             ? (sw_s / hw_s)            : INFINITY;
    double fairSpeedup = ((hw_s + conv_s) > 0.0)  ? (sw_s / (hw_s + conv_s)) : INFINITY;

    results[fi].convTime_s    = conv_s;
    results[fi].swTime_s      = sw_s;
    results[fi].speedup       = speedup;
    results[fi].fairSpeedup   = fairSpeedup;
    results[fi].sw_snr_db     = sw_snr;
    results[fi].sw_maxRelErr  = sw_maxRel;
    results[fi].sw_pass       = sw_ok;
    results[fi].sw_energy_j   = sw_energy_j;
    results[fi].sw_avgPower_w = sw_avgW;
    results[fi].sw_peakPower_w = sw_peakW;

    if (!sw_skipped) {
      printf("(SW dense ) %s --> conv %.6f s + compute %.6f s  |  speedup %.2fx (fair %.2fx)\n",
             name, conv_s, sw_s, speedup, fairSpeedup);
      if (powerOk) {
        printf("     SW dense energy %.4f J/call  avg %.2f W  peak %.2f W\n",
               sw_energy_j, sw_avgW, sw_peakW);
      }
    }

    // ------------------------------------------------------------------
    // SW *sparse* reference: ARM-side simplicial up-looking LDL^T (same
    // algorithm the FPGA kernel runs, in doubles). This is what tells us
    // how much of the speed-up vs SW-dense comes from "sparsity" alone
    // vs how much comes from the FPGA hardware itself.
    // ------------------------------------------------------------------
    clock_gettime(CLOCK_MONOTONIC, &t0);
    extract_sparse_inputs_from_fxp(inputHW, m, n, nnz_A, nnz_K, nnz_L,
                                   A_indptr_i, A_indices_i, A_values_d,
                                   D_d, b_d,
                                   K_colptr_i, K_rowidx_i,
                                   L_colptr_i, L_rowidx_i,
                                   L_rowptr_i, L_cic_i, L_vp_i);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double conv_sp_s = (t1.tv_sec - t0.tv_sec) + (t1.tv_nsec - t0.tv_nsec) * 1e-9;

    int sw_sp_status = 0;
    double cum_sp_s = 0.0;
    uint32_t reps_sp = measure_adaptive(pwr, [&](uint32_t /*rep*/) {
      sw_sp_status = KFormFactorSolve_SparseSW(
          m, n, nnz_K, nnz_L,
          A_indptr_i, A_indices_i, A_values_d,
          D_d, b_d,
          K_colptr_i, K_rowidx_i,
          L_colptr_i, L_rowidx_i,
          L_rowptr_i, L_cic_i, L_vp_i,
          K_values_d, L_values_csc_d, Dv_d,
          w_d, flag_i,
          dy_sp_sw);
      // sw_sp_status == -1 means a non-positive pivot was clamped — same
      // numerical guard the FPGA factor uses (cholesky_solve.cpp:66), so we
      // still validate dy and let CompareDyDouble decide pass/fail.
    }, MEAS_KERNEL_MIN_REPS, MEAS_KERNEL_MIN_SEC, MEAS_KERNEL_MAX_REPS, &cum_sp_s);

    double sw_sp_s = cum_sp_s / reps_sp;
    double sw_sp_energy_j = pwr.TotalEnergyJ() / reps_sp;
    double sw_sp_avgW     = pwr.AvgPowerW();
    double sw_sp_peakW    = pwr.PeakPowerW();

    double sw_sp_snr = 0.0, sw_sp_maxRel = 0.0;
    bool sw_sp_ok = CompareDyDouble(g_dy_expected, dy_sp_sw, m, sw_sp_snr, sw_sp_maxRel);
    if (!sw_sp_ok) any_fail = true;
    if (sw_sp_status == -1) {
      printf("  (SW sparse) pivot clamp triggered — numerical guard fired\n");
    }

    double speedup_sp = (hw_s > 0.0) ? (sw_sp_s / hw_s) : INFINITY;

    results[fi].convSpTime_s     = conv_sp_s;
    results[fi].swSpTime_s       = sw_sp_s;
    results[fi].speedup_sp       = speedup_sp;
    results[fi].sw_sp_snr_db     = sw_sp_snr;
    results[fi].sw_sp_maxRelErr  = sw_sp_maxRel;
    results[fi].sw_sp_pass       = sw_sp_ok;
    results[fi].sw_sp_energy_j   = sw_sp_energy_j;
    results[fi].sw_sp_avgPower_w = sw_sp_avgW;
    results[fi].sw_sp_peakPower_w = sw_sp_peakW;

    printf("(SW sparse) %s --> conv %.6f s + compute %.6f s  |  speedup %.2fx (HW/SW_sp)\n",
           name, conv_sp_s, sw_sp_s, speedup_sp);
    if (powerOk) {
      printf("     SW sparse energy %.4f J/call  avg %.2f W  peak %.2f W\n",
             sw_sp_energy_j, sw_sp_avgW, sw_sp_peakW);
    }
  }

  // Summary + CSV report (data/sparse_solve_report.{csv,txt}).
  printf("\n=================================================================== SUMMARY ===================================================================\n");
  printf(" %-22s %5s %5s %7s %7s %10s %10s %10s %9s %9s %8s   %-6s   %10s %10s %10s\n",
         "fixture", "m", "n", "nnz_K", "nnz_L",
         "HW(s)", "SW_d(s)", "SW_sp(s)", "Spd_d", "Spd_sp", "SNR_HW", "Status",
         "kf_it", "fc_it", "tr_it");
  for (int fi = 0; fi < num_fixtures; fi++) {
    const TestResult &r = results[fi];
    bool all_pass = r.pass && r.sw_pass && r.sw_sp_pass;
    printf(" %-22s %5u %5u %7u %7u %10.6f %10.6f %10.6f %8.2fx %8.2fx %8.1f   %-6s   %10u %10u %10u\n",
           r.name, r.m, r.n, r.nnz_K, r.nnz_L,
           r.hwTime_s, r.swTime_s, r.swSpTime_s,
           r.speedup, r.speedup_sp, r.snr_db,
           all_pass ? "PASS" : "FAIL",
           r.kform_iters, r.factor_iters, r.triangular_iters);
  }
  printf("===============================================================================================================================================\n");

  // CSV (machine-readable). Three solver groups in column order: HW (FPGA
  // sparse), SW dense (Gaussian on densified K), SW sparse (same simplicial
  // LDL^T algorithm as the FPGA, in doubles).
  FILE *csv = fopen("../data/sparse_solve_report.csv", "w");
  if (csv) {
    fprintf(csv,
            "fixture,m,n,nnz_A,nnz_K,nnz_L,"
            "HW_s,kform_iters,factor_iters,triangular_iters,SNR_HW_dB,MaxRelErr_HW_pct,HW_Energy_J,HW_AvgPower_W,HW_PeakPower_W,SampleWindow_s,Pass_HW,"
            "Conv_s,SW_s,Speedup,Fair_Speedup,"
            "SNR_SW_dB,MaxRelErr_SW_pct,SW_Energy_J,SW_AvgPower_W,SW_PeakPower_W,Pass_SW,"
            "Conv_sp_s,SW_sp_s,Speedup_sp,"
            "SNR_SW_sp_dB,MaxRelErr_SW_sp_pct,SW_sp_Energy_J,SW_sp_AvgPower_W,SW_sp_PeakPower_W,Pass_SW_sp\n");
    for (int fi = 0; fi < num_fixtures; fi++) {
      const TestResult &r = results[fi];
      fprintf(csv,
              "%s,%u,%u,%u,%u,%u,"
              "%.9f,%u,%u,%u,%.2f,%.6f,%.6f,%.4f,%.4f,%.6f,%d,"
              "%.9f,%.9f,%.4f,%.4f,"
              "%.2f,%.6f,%.6f,%.4f,%.4f,%d,"
              "%.9f,%.9f,%.4f,"
              "%.2f,%.6f,%.6f,%.4f,%.4f,%d\n",
              r.name, r.m, r.n, r.nnz_A, r.nnz_K, r.nnz_L,
              r.hwTime_s, r.kform_iters, r.factor_iters, r.triangular_iters,
              r.snr_db, r.maxRelErr * 100.0,
              r.energy_j, r.avgPower_w, r.peakPower_w, r.sampleWindow_s,
              r.pass ? 1 : 0,
              r.convTime_s, r.swTime_s, r.speedup, r.fairSpeedup,
              r.sw_snr_db, r.sw_maxRelErr * 100.0,
              r.sw_energy_j, r.sw_avgPower_w, r.sw_peakPower_w,
              r.sw_pass ? 1 : 0,
              r.convSpTime_s, r.swSpTime_s, r.speedup_sp,
              r.sw_sp_snr_db, r.sw_sp_maxRelErr * 100.0,
              r.sw_sp_energy_j, r.sw_sp_avgPower_w, r.sw_sp_peakPower_w,
              r.sw_sp_pass ? 1 : 0);
    }
    fclose(csv);
    printf("CSV report written to ../data/sparse_solve_report.csv\n");
  }

  FILE *txt = fopen("../data/sparse_solve_report.txt", "w");
  if (txt) {
    fprintf(txt, "%-22s %5s %5s %7s %7s %10s %10s %10s %9s %9s %8s   %-6s   %10s %10s %10s\n",
            "fixture", "m", "n", "nnz_K", "nnz_L",
            "HW(s)", "SW_d(s)", "SW_sp(s)", "Spd_d", "Spd_sp", "SNR_HW", "Status",
            "kf_it", "fc_it", "tr_it");
    for (int fi = 0; fi < num_fixtures; fi++) {
      const TestResult &r = results[fi];
      bool all_pass = r.pass && r.sw_pass && r.sw_sp_pass;
      fprintf(txt, "%-22s %5u %5u %7u %7u %10.6f %10.6f %10.6f %8.2fx %8.2fx %8.1f   %-6s   %10u %10u %10u\n",
              r.name, r.m, r.n, r.nnz_K, r.nnz_L,
              r.hwTime_s, r.swTime_s, r.swSpTime_s,
              r.speedup, r.speedup_sp, r.snr_db,
              all_pass ? "PASS" : "FAIL",
              r.kform_iters, r.factor_iters, r.triangular_iters);
    }
    fclose(txt);
    printf("Text report written to ../data/sparse_solve_report.txt\n");
  }

  free(results);
  free(Ad_d); free(K_d); free(D_d); free(b_d); free(dy_sw);
  free(A_indptr_i); free(A_indices_i); free(A_values_d);
  free(K_colptr_i); free(K_rowidx_i);
  free(L_colptr_i); free(L_rowidx_i); free(L_rowptr_i); free(L_cic_i); free(L_vp_i);
  free(K_values_d); free(L_values_csc_d); free(Dv_d);
  free(dy_sp_sw); free(w_d); free(flag_i);
  return any_fail ? 1 : 0;
}
