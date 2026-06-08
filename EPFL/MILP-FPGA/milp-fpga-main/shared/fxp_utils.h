#ifndef FXP_UTILS_H
#define FXP_UTILS_H

#include <stdint.h>
#include <math.h>

#include "constants.h"

#define WIDTH (1 + Q_INT_BITS + Q_FRAC_BITS)
static_assert(Q_INT_BITS  >= 1,  "Q_INT_BITS must be at least 1");
static_assert(Q_FRAC_BITS >= 1,  "Q_FRAC_BITS must be at least 1");
static_assert(WIDTH <= 128,      "TFXP width must fit in __int128 on host (WIDTH <= 128)");

#if defined(__has_include) && __has_include("ap_int.h")
  #include "ap_int.h"
  typedef ap_int<WIDTH>      TFXP;
  typedef ap_int<WIDTH * 2>  TFXP_MULT;
  #if (1 + Q_INT_BITS + Q_FRAC_BITS) == 72 || (1 + Q_INT_BITS + Q_FRAC_BITS) == 128
    typedef ap_int<WIDTH>    TFXP_WIRE;
  #else
    typedef ap_int<128>      TFXP_WIRE;
  #endif
#else
  typedef __int128           TFXP;
  typedef __int128           TFXP_MULT;
  typedef __int128           TFXP_WIRE;
#endif

const uint32_t DECIMALS = Q_FRAC_BITS;
constexpr int   TFXP_BITS = WIDTH;
static const TFXP FXP_ONE = (TFXP)1 << DECIMALS;

///////////////////////////////////////////////////////////////////////////////
// Fixed-point multiplication with configurable decimal precision.
// Widens to TFXP_MULT (2*WIDTH bits) before shifting to avoid overflow.
inline TFXP FXP_Mult(TFXP a, TFXP b, uint32_t decimalBits = DECIMALS)
{
  TFXP_MULT res = (TFXP_MULT)a * (TFXP_MULT)b;
  res = res >> decimalBits;
  return res;
}

///////////////////////////////////////////////////////////////////////////////
// Fixed-point division: a / b in Q(TFXP_BITS-1-DECIMALS).DECIMALS format.
// Widens numerator to TFXP_MULT (2*WIDTH bits) before dividing to preserve precision.
inline TFXP FXP_Div(TFXP a, TFXP b, uint32_t decimalBits = DECIMALS)
{
  TFXP_MULT num = (TFXP_MULT)a << decimalBits;
  return (TFXP)(num / (TFXP_MULT)b);
}

///////////////////////////////////////////////////////////////////////////////
// Newton-Raphson reciprocal
inline TFXP FXP_Recip(TFXP d)
{
  // Find MSB position of d. Loop unrolled to a parallel mux network.
  int msb_pos = 0;
  for (int i = 0; i < TFXP_BITS; i++) {
    #pragma HLS UNROLL
    if (((d >> i) & 1) != 0) msb_pos = i;
  }

  int shift = 2 * (int)DECIMALS - msb_pos - 1;
  if (shift > TFXP_BITS - 2) shift = TFXP_BITS - 2;
  if (shift < 0) shift = 0;
  TFXP x = (TFXP)1 << shift;

  const TFXP TWO_Q = (TFXP)1 << (DECIMALS + 1);
  for (int i = 0; i < 6; i++) {
    #pragma HLS UNROLL
    TFXP dx = FXP_Mult(d, x);
    TFXP correction = TWO_Q - dx;
    x = FXP_Mult(x, correction);
  }
  return x;
}

///////////////////////////////////////////////////////////////////////////////
inline TFXP Double2Fxp(double value, uint32_t decimalBits = DECIMALS)
{
  long double scaled = (long double)value * ldexpl(1.0L, (int)decimalBits);
  return (TFXP)(long long)llroundl(scaled);
}

///////////////////////////////////////////////////////////////////////////////
inline TFXP Float2Fxp(float value, uint32_t decimalBits = DECIMALS)
{
  return Double2Fxp((double)value, decimalBits);
}

// Fxp2{Float,Double}: divide by 2^decimalBits via ldexp(1.0, decimalBits)
// instead of (uint64_t)1<<decimalBits to avoid shift overflow when
// decimalBits >= 64 (hit at Q31.96 and similar wide-frac formats).
#if defined(__has_include) && __has_include("ap_int.h")

inline float Fxp2Float(TFXP value, uint32_t decimalBits = DECIMALS)
{
  return (float)(value / ldexp(1.0, (int)decimalBits));
}

inline double Fxp2Double(TFXP value, uint32_t decimalBits = DECIMALS)
{
  return value / ldexp(1.0, (int)decimalBits);
}

#else

inline float Fxp2Float(TFXP value, uint32_t decimalBits = DECIMALS)
{
  constexpr int shift = 128 - TFXP_BITS;
  value = (value << shift) >> shift;
  return (float)((long double)value / ldexpl(1.0L, (int)decimalBits));
}

inline double Fxp2Double(TFXP value, uint32_t decimalBits = DECIMALS)
{
  constexpr int shift = 128 - TFXP_BITS;
  value = (value << shift) >> shift;
  return (double)((long double)value / ldexpl(1.0L, (int)decimalBits));
}

#endif

///////////////////////////////////////////////////////////////////////////////
#ifndef __SYNTHESIS__
#include <iostream>
#include <cstdio>

template<typename T>
inline void PrintDynamicRange(T* vec, size_t size) {
  if (vec == nullptr) {
    std::cout << "Vector is empty. No dynamic range to display." << std::endl;
    return;
  }

  T minVal = vec[0];
  T maxVal = vec[0];
  for (size_t i = 0; i < size; ++i) {
    if (vec[i] < minVal) minVal = vec[i];
    if (vec[i] > maxVal) maxVal = vec[i];
  }
  std::cout << "Dynamic Range: Min = " << minVal << ", Max = " << maxVal << ", Range = " << maxVal - minVal << std::endl;
}

inline void PrintFxpRange(const char* label, TFXP* vec, size_t size) {
  TFXP minVal = vec[0], maxVal = vec[0];
  for (size_t i = 0; i < size; ++i) {
    if (vec[i] < minVal) minVal = vec[i];
    if (vec[i] > maxVal) maxVal = vec[i];
  }
  double minF = Fxp2Double(minVal);
  double maxF = Fxp2Double(maxVal);
  const double WARN = ldexp(1.0, TFXP_BITS - 1 - (int)DECIMALS) * 0.9;
  const char* warn = (maxF > WARN || minF < -WARN) ? " *** NEAR OVERFLOW ***" : "";
  printf("  [%s] min=%.4f max=%.4f%s\n", label, minF, maxF, warn);
}

#if defined(__has_include) && __has_include("ap_int.h")
#if (1 + Q_INT_BITS + Q_FRAC_BITS) != 72 && (1 + Q_INT_BITS + Q_FRAC_BITS) != 128
inline void PrintFxpRange(const char* label, TFXP_WIRE* vec, size_t size) {
  TFXP minVal = (TFXP)vec[0], maxVal = (TFXP)vec[0];
  for (size_t i = 0; i < size; ++i) {
    TFXP v = (TFXP)vec[i];
    if (v < minVal) minVal = v;
    if (v > maxVal) maxVal = v;
  }
  double minF = Fxp2Double(minVal);
  double maxF = Fxp2Double(maxVal);
  const double WARN = ldexp(1.0, TFXP_BITS - 1 - (int)DECIMALS) * 0.9;
  const char* warn = (maxF > WARN || minF < -WARN) ? " *** NEAR OVERFLOW ***" : "";
  printf("  [%s] min=%.4f max=%.4f%s\n", label, minF, maxF, warn);
}
#endif
#endif

#endif // __SYNTHESIS__

#endif // FXP_UTILS_H
