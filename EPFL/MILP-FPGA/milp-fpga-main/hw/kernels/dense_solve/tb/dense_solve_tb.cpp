#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>

#include "dense_solve.h"
#include "constants.h"

// Relative tolerance for SW (double) vs HW (fixed-point) comparison
static const double REL_TOL = 0.50;  // 50% — Q12.20 Gauss elimination accumulates error
static const double ABS_TOL = 2.0;   // absolute tolerance — ignore errors on small values
static const double MIN_SNR_DB = 15.0;  // minimum acceptable SNR

TFXP_WIRE input[DENSE_MAX_M * DENSE_MAX_N + DENSE_MAX_N + DENSE_MAX_M];
double outputSW[DENSE_MAX_M];
TFXP_WIRE outputHW[DENSE_MAX_M];
// Scratch for SW reference (file-scope to keep large arrays out of the stack)
double Ksw[DENSE_MAX_M * DENSE_MAX_M];
double Ad_sw[DENSE_MAX_M * DENSE_MAX_N];
double D_sw[DENSE_MAX_N];
double b_sw[DENSE_MAX_M];

///////////////////////////////////////////////////////////////////////////////
// Combines multiple rand() calls because RAND_MAX is only 32767 on Windows.
static int64_t FullRangeRand(int64_t range)
{
  uint64_t r = ((uint64_t)rand() << 45) ^ ((uint64_t)rand() << 30) ^
               ((uint64_t)rand() << 15) ^ (uint64_t)rand();
  return (int64_t)(r % (uint64_t)range);
}

///////////////////////////////////////////////////////////////////////////////
void InitRandom(TFXP_WIRE *data, uint32_t size)
{
  for (uint32_t i = 0; i < size; i++) {
    int64_t raw = FullRangeRand((int64_t)2 << DECIMALS) - ((int64_t)1 << DECIMALS);
    data[i] = (TFXP_WIRE)raw;
  }
}

///////////////////////////////////////////////////////////////////////////////
// D strictly positive makes K SPD; range tightened so LDL^T intermediates stay
// in range at large n.
void InitDPositive(TFXP_WIRE *data, uint32_t size)
{
  for (uint32_t i = 0; i < size; i++) {
    int64_t raw = FullRangeRand((int64_t)2 << (DECIMALS - 2)) + ((int64_t)1 << (DECIMALS - 3));
    data[i] = (TFXP_WIRE)raw;
  }
}

///////////////////////////////////////////////////////////////////////////////
// SW reference: K-formation then Gaussian elimination solve (double precision)
void KFormAndSolve_SW(TFXP_WIRE *in, double *dy, uint32_t n, uint32_t m)
{
  TFXP_WIRE *AdFxp  = in;
  TFXP_WIRE *DFxp   = in + m * n;
  TFXP_WIRE *rhsFxp = in + m * n + n;

  double *Ad = Ad_sw;
  double *D  = D_sw;
  double *b  = b_sw;

  for (uint32_t i = 0; i < m * n; i++) Ad[i] = Fxp2Double((TFXP)AdFxp[i]);
  for (uint32_t j = 0; j < n; j++)     D[j]  = Fxp2Double((TFXP)DFxp[j]);
  for (uint32_t i = 0; i < m; i++)     b[i]  = Fxp2Double((TFXP)rhsFxp[i]);

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
bool CompareVectors(double *sw, TFXP_WIRE *hw, uint32_t size)
{
  bool ok = true;
  double maxRelErr = 0.0;
  double sumSqErr = 0.0;
  double sumSqRef = 0.0;

  for (uint32_t i = 0; i < size; i++) {
    double hwVal = Fxp2Double((TFXP)hw[i]);
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

  return ok;
}

///////////////////////////////////////////////////////////////////////////////
int main(int /*argc*/, char ** /*argv*/)
{
  // Test sizes: {n, m} — n=columns of A, m=rows of A (n >= m for well-posed K)
  uint32_t sizes[][2] = { {4, 3}, {8, 6}, {16, 12}, {32, 24}, {64, 48}, {128, 96}, {256, 192}, {256, 224} }; //, {512, 384}, {512, 480} };
  uint32_t numSizes = sizeof(sizes) / (sizeof(uint32_t) * 2);
  bool errors = false;

  srand(42);

  for (uint32_t iTest = 0; iTest < numSizes; ++iTest) {
    uint32_t n = sizes[iTest][0];
    uint32_t m = sizes[iTest][1];

    printf("K-form + solve %" PRIu32 "x%" PRIu32 " (m=%" PRIu32 ", n=%" PRIu32 ")\n", m, n, m, n);

    // Fill Ad with random, D with positive values, rhs with random
    InitRandom(input, m * n);              // Ad
    InitDPositive(input + m * n, n);       // D (positive for SPD K)
    InitRandom(input + m * n + n, m);      // rhs

    for (uint32_t i = 0; i < m; i++) outputSW[i] = 0.0;
    memset(outputHW, 0, m * sizeof(TFXP_WIRE));

    printf("  SW\n");
    KFormAndSolve_SW(input, outputSW, n, m);
    printf("  HW\n");
    DenseSolve(input, outputHW, n, m);

    if (!CompareVectors(outputSW, outputHW, m)) {
      printf("\n====== ERROR ======\n\n");
      errors = true;
    } else {
      printf("  --> OK!\n");
    }
  }
  printf("\n");

  return errors ? -1 : 0;
}
