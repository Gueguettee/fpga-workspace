#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <time.h>
#include "utils.h"

double now_ms(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1e6;
}

void print_profile(const char *label, int m, int n, const Profile *p) {
  double total = p->total_ms;
  if (total < 1e-9) total = 1e-9; // avoid division by zero
  printf("\n--- %s profile (m=%d, n=%d) ---\n", label, m, n);
  printf("  spmv:      %8.3f ms  (%5.1f%%)\n", p->spmv_ms,   100.0*p->spmv_ms/total);
  printf("  spmv_t:    %8.3f ms  (%5.1f%%)\n", p->spmv_t_ms, 100.0*p->spmv_t_ms/total);
  printf("  vecops:    %8.3f ms  (%5.1f%%)\n", p->vecops_ms, 100.0*p->vecops_ms/total);
  printf("  kform:     %8.3f ms  (%5.1f%%)\n", p->kform_ms,  100.0*p->kform_ms/total);
  printf("  dsolve:    %8.3f ms  (%5.1f%%)\n", p->dsolve_ms, 100.0*p->dsolve_ms/total);
  printf("  conv:      %8.3f ms  (%5.1f%%)\n", p->conv_ms,   100.0*p->conv_ms/total);
  printf("  other:     %8.3f ms  (%5.1f%%)\n", p->other_ms,  100.0*p->other_ms/total);
  printf("  TOTAL:     %8.3f ms\n", p->total_ms);
}
