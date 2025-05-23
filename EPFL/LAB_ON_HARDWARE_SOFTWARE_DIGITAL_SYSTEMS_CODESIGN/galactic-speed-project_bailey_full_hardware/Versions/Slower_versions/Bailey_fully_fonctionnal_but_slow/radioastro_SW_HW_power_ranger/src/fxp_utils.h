#ifndef FXP_UTILS_H
#define FXP_UTILS_H

#include <inttypes.h>
#include <stdint.h>
#include <iostream>
#include <algorithm>
#include <math.h> // for roundf()

const uint32_t DECIMALS = 28;
typedef int32_t FXP_TYPE;
typedef int64_t FXP_MULT;// Intermmediate results of multiplications
typedef int64_t FXP_ACC; // Moving average accumulator

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

inline FXP_TYPE Float2Fxp(float value, uint32_t decimalBits = DECIMALS)
{
  //return value;
  int32_t scaled = (int32_t)roundf(value * ((uint64_t)1 << decimalBits));
    
  // Clamp to int16_t range
  if (scaled > INT32_MAX) scaled = INT32_MAX;
  if (scaled < INT32_MIN) scaled = INT32_MIN;

  return (int32_t)scaled;
}

inline float Fxp2Float(FXP_TYPE value, uint32_t decimalBits = DECIMALS)
{
  //return value;
  return ((value) / (float)((uint64_t)1 << (decimalBits)));
}

inline FXP_TYPE FXP_Mult(FXP_TYPE a, FXP_TYPE b, uint32_t decimalBits = DECIMALS)
{
  //return a*b;
  FXP_MULT res = (FXP_MULT)a * (FXP_MULT)b;
  res = res >> decimalBits;
  return res;
}

#endif