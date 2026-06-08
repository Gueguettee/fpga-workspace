#ifndef PROFILE_H_INCLUDED
#define PROFILE_H_INCLUDED

#include <stdint.h>

typedef struct {
  uint32_t cycles;
  uint32_t stall;
  uint32_t bus_idle;
} profile_t;

void profile_start(void);
void profile_stop(profile_t *out);
void profile_print(const profile_t *p);

// One-line summary: "<label>: <cycles> cy (~<ms> ms, stalls <%>)"
void profile_print_labeled(const char *label, const profile_t *p);

#endif
