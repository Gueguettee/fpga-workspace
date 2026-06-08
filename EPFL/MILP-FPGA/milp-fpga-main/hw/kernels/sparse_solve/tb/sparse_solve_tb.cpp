#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>

#include "sparse_solve.h"
#include "fxp_utils.h"
#include "constants.h"

///////////////////////////////////////////////////////////////////////////////
// Sparse solve testbench. Reads "SPLA" fixtures, packs them into SparseSolve's
// AXI input layout, runs the kernel, and compares dy.
///////////////////////////////////////////////////////////////////////////////

static const double REL_TOL    = 0.50;
static const double ABS_TOL    = 2.0;
static const double MIN_SNR_DB = 15.0;

static const uint32_t FIX_MAGIC_KFORM = 0x53504C41u;  // "SPLA"
static const uint32_t FIX_VERSION     = 1u;

// Worst-case packed input layout:
//   A_indptr[m+1] + A_indices[nnz_A] + A_values[nnz_A] + D[n]
//   + K_colptr[m+1] + K_rowidx[nnz_K]
//   + L_colptr[m+1] + L_rowidx_csc[nnz_L]
//   + L_rowptr[m+1] + L_colidx_csr[nnz_L] + L_csr_pos[nnz_L]
//   + b[m]
#define MAX_INPUT_WORDS (4 * (SPARSE_MAX_M + 1) + 2 * SPARSE_MAX_NNZ_A         \
                          + SPARSE_MAX_N + SPARSE_MAX_NNZ_K                    \
                          + 3 * SPARSE_MAX_NNZ_L + SPARSE_MAX_M)

static TFXP_WIRE g_input[MAX_INPUT_WORDS];
static TFXP_WIRE g_dy_hw[SPARSE_MAX_M];
static double g_dy_expected[SPARSE_MAX_M];
static double g_K_values_expected[SPARSE_MAX_NNZ_K];

static int read_exact(FILE *f, void *buf, size_t n) {
  return fread(buf, 1, n, f) == n ? 0 : -1;
}

static FILE *open_fixture(const char *rel_path) {
  static const char *prefixes[] = {
    "", "../", "../../", "../../../", "../../../../",
    "../../../../kernels/sparse_solve/tb/",
    "../../../../../kernels/sparse_solve/tb/",
    "../../../../../../kernels/sparse_solve/tb/",
    "kernels/sparse_solve/tb/",
    "hw/kernels/sparse_solve/tb/",
  };
  char buf[1024];
  for (size_t i = 0; i < sizeof(prefixes) / sizeof(prefixes[0]); i++) {
    snprintf(buf, sizeof(buf), "%s%s", prefixes[i], rel_path);
    FILE *f = fopen(buf, "rb");
    if (f) {
      printf("  (loaded from %s)\n", buf);
      return f;
    }
  }
  return NULL;
}

static int read_int128_array_to_tfxp(FILE *f, TFXP_WIRE *dst, uint32_t n) {
  for (uint32_t i = 0; i < n; i++) {
    int64_t lo, hi;
    if (read_exact(f, &lo, sizeof(lo))) return -1;
    if (read_exact(f, &hi, sizeof(hi))) return -1;
    TFXP_WIRE val = (TFXP_WIRE)hi;
    val <<= 64;
    val |= (TFXP_WIRE)(uint64_t)lo;
    dst[i] = val;
  }
  return 0;
}

static int load_uint32_into_tfxp(FILE *f, TFXP_WIRE *dst, uint32_t n) {
  uint32_t buf;
  for (uint32_t i = 0; i < n; i++) {
    if (read_exact(f, &buf, sizeof(buf))) return -1;
    dst[i] = (TFXP_WIRE)(int64_t)(uint64_t)buf;
  }
  return 0;
}

static int load_uint16_into_tfxp_padded(FILE *f, TFXP_WIRE *dst, uint32_t n) {
  uint16_t buf;
  for (uint32_t i = 0; i < n; i++) {
    if (read_exact(f, &buf, sizeof(buf))) return -1;
    dst[i] = (TFXP_WIRE)(int64_t)(uint64_t)buf;
  }
  size_t pad = (-(sizeof(uint16_t) * (size_t)n)) & 3;
  if (pad) {
    char dummy[4];
    if (read_exact(f, dummy, pad)) return -1;
  }
  return 0;
}

static int load_kform_fixture_into_input(const char *path,
                                         uint32_t *m_out, uint32_t *n_out,
                                         uint32_t *nnz_A_out,
                                         uint32_t *nnz_K_out,
                                         uint32_t *nnz_L_out)
{
  FILE *f = open_fixture(path);
  if (!f) {
    printf("  ERROR: cannot find %s\n", path);
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
    printf("  ERROR: dimensions exceed SPARSE_MAX_*\n");
    fclose(f); return -1;
  }

  uint32_t off = 0;

  if (load_uint32_into_tfxp(f, &g_input[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &g_input[off], nnz_A)) { fclose(f); return -1; }
  off += nnz_A;
  if (read_int128_array_to_tfxp(f, &g_input[off], nnz_A)) { fclose(f); return -1; }
  off += nnz_A;
  if (read_int128_array_to_tfxp(f, &g_input[off], n)) { fclose(f); return -1; }
  off += n;

  if (load_uint32_into_tfxp(f, &g_input[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &g_input[off], nnz_K)) { fclose(f); return -1; }
  off += nnz_K;

  if (load_uint32_into_tfxp(f, &g_input[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &g_input[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;

  if (load_uint32_into_tfxp(f, &g_input[off], m + 1)) { fclose(f); return -1; }
  off += (m + 1);
  if (load_uint16_into_tfxp_padded(f, &g_input[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;
  // Skip the fixture's L_csc_pos slot — kernel uses L_csr_pos (next slot).
  if (fseek(f, (long)(sizeof(uint32_t) * nnz_L), SEEK_CUR)) { fclose(f); return -1; }
  if (load_uint32_into_tfxp(f, &g_input[off], nnz_L)) { fclose(f); return -1; }
  off += nnz_L;

  if (read_int128_array_to_tfxp(f, &g_input[off], m)) { fclose(f); return -1; }
  // off += m;

  if (read_exact(f, g_dy_expected, sizeof(double) * m)) { fclose(f); return -1; }
  if (read_exact(f, g_K_values_expected, sizeof(double) * nnz_K)) {
    fclose(f); return -1;
  }

  fclose(f);
  *m_out = m; *n_out = n;
  *nnz_A_out = nnz_A; *nnz_K_out = nnz_K; *nnz_L_out = nnz_L;
  return 0;
}

static bool compare_dy(const double *expected, const TFXP_WIRE *hw, uint32_t m) {
  bool ok = true;
  double maxRelErr = 0.0;
  double sumSqErr = 0.0;
  double sumSqRef = 0.0;

  for (uint32_t i = 0; i < m; i++) {
    double swVal = expected[i];
    TFXP narrow = (TFXP)hw[i];
    double hwVal = Fxp2Double(narrow);
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
  return ok;
}

static int run_one(const char *path) {
  uint32_t m = 0, n = 0, nnz_A = 0, nnz_K = 0, nnz_L = 0;
  if (load_kform_fixture_into_input(path, &m, &n, &nnz_A, &nnz_K, &nnz_L))
    return -1;

  printf("Kform+factor+solve fixture %s  m=%u n=%u nnz_A=%u nnz_K=%u nnz_L=%u\n",
         path, m, n, nnz_A, nnz_K, nnz_L);

  memset(g_dy_hw, 0, sizeof(TFXP_WIRE) * m);
  uint32_t kform_iters = 0, factor_iters = 0, triangular_iters = 0;
  SparseSolve(g_input, g_dy_hw,
              m, n, nnz_A, nnz_K, nnz_L, MODE_SETUP,
              &kform_iters, &factor_iters, &triangular_iters);
  SparseSolve(g_input, g_dy_hw,
              m, n, nnz_A, nnz_K, nnz_L, MODE_SOLVE,
              &kform_iters, &factor_iters, &triangular_iters);

  uint32_t total_iters = kform_iters + factor_iters + triangular_iters;
  printf("  iters: kform=%u factor=%u triangular=%u  total=%u\n",
         kform_iters, factor_iters, triangular_iters, total_iters);
  if (total_iters > 0) {
    printf("         %5.1f%% kform, %5.1f%% factor, %5.1f%% triangular\n",
           100.0 * kform_iters / total_iters,
           100.0 * factor_iters / total_iters,
           100.0 * triangular_iters / total_iters);
  }

  // Surfaces "*** NEAR OVERFLOW ***" if any dy entry approaches Q17.54's ±2^17.
  PrintFxpRange("dy", g_dy_hw, m);

  if (!compare_dy(g_dy_expected, g_dy_hw, m)) {
    printf("  ====== MISMATCH ======\n");
    return -1;
  }
  printf("  --> OK\n");
  return 0;
}

int main(int /*argc*/, char ** /*argv*/) {
  // Random-sparse only at m=256 (pure-random A is singular at larger m); banded
  // owns m=512..4096; kform_uc_* are real UC LP-relaxation matrices.
#ifdef COSIM_PROFILE
  // Cosim is ~1000x slower than csim; two small UC fixtures (m=258, m=924).
  const char *fixtures[] = {
    "fixtures/kform_uc_micro_T6.bin",
    "fixtures/kform_uc_xs_T12.bin",
  };
#else
  const char *fixtures[] = {
    "fixtures/kform_dense_4.bin",
    "fixtures/kform_dense_8.bin",
    "fixtures/kform_dense_16.bin",
    "fixtures/kform_dense_32.bin",
    "fixtures/kform_dense_64.bin",
    "fixtures/kform_dense_128.bin",
    "fixtures/kform_dense_256.bin",
    "fixtures/kform_sparse_256.bin",
    "fixtures/kform_banded_512.bin",
    "fixtures/kform_banded_1024.bin",
    "fixtures/kform_banded_1848.bin",
    "fixtures/kform_uc_micro_T6.bin",
    "fixtures/kform_uc_micro_T12.bin",
    "fixtures/kform_uc_xs_T6.bin",
    "fixtures/kform_uc_xs_T12.bin",
    "fixtures/kform_uc_xs_T24.bin",
    "fixtures/kform_uc_s_T12.bin",
    "fixtures/kform_uc_s_T24.bin",
    "fixtures/kform_uc_m_T12.bin",
    "fixtures/kform_uc_m_T24.bin",
    // kform_uc_l_T24 (n=4800) exceeds SPARSE_MAX_N; re-enable once ceiling bumped.
    // "fixtures/kform_uc_l_T24.bin",
    "fixtures/kform_banded_4096.bin",
  };
#endif
  int n_fixtures = (int)(sizeof(fixtures) / sizeof(fixtures[0]));

  int n_failed = 0;
  for (int i = 0; i < n_fixtures; i++) {
    if (run_one(fixtures[i])) n_failed++;
  }

  printf("\n%d/%d tests passed\n", n_fixtures - n_failed, n_fixtures);
  return n_failed ? 1 : 0;
}
