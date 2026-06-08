#ifndef MEASURE_HELPERS_H
#define MEASURE_HELPERS_H
// Adaptive-repetition energy/latency helper: loops the per-rep body in
// PmtPowerMeter Start/Stop until T_win > min_sec (and >= min_reps, capped at
// max_reps) so the dynamic-energy estimate clears PMT's noise floor (the
// 1/sqrt(T_win) noise on P_idle*T_win otherwise clamps short windows to zero).

#include "pmt_power_meter.h"
#include <stdint.h>
#include <time.h>

constexpr uint32_t MEAS_KERNEL_MIN_REPS = 20u;
constexpr double   MEAS_KERNEL_MIN_SEC  = 0.1;
constexpr uint32_t MEAS_KERNEL_MAX_REPS = 200000u;

constexpr uint32_t MEAS_IPM_MIN_REPS = 1u;
constexpr double   MEAS_IPM_MIN_SEC  = 0.1;
constexpr uint32_t MEAS_IPM_MAX_REPS = 200u;

template<typename F>
inline uint32_t measure_adaptive(PmtPowerMeter& pwr, F&& body,
                                 uint32_t min_reps, double min_sec,
                                 uint32_t max_reps,
                                 double* out_total_sec = nullptr) {
  pwr.Reset();
  pwr.Start();
  struct timespec t0, tnow;
  clock_gettime(CLOCK_MONOTONIC, &t0);
  uint32_t reps = 0;
  double cum_s = 0.0;
  while ((reps < min_reps || cum_s < min_sec) && reps < max_reps) {
    body(reps);
    reps++;
    clock_gettime(CLOCK_MONOTONIC, &tnow);
    cum_s = (tnow.tv_sec - t0.tv_sec) + (tnow.tv_nsec - t0.tv_nsec) * 1e-9;
  }
  pwr.Stop();
  if (out_total_sec) *out_total_sec = cum_s;
  return reps;
}

#endif // MEASURE_HELPERS_H
