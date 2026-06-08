#ifndef UTIL_HPP
#define UTIL_HPP

#include <time.h>
#include <stdint.h>

inline uint64_t CalcTimeDiff(struct timespec end, struct timespec start)
{
  return (uint64_t)(end.tv_sec - start.tv_sec) * 1000000000ULL
       + (uint64_t)(end.tv_nsec - start.tv_nsec);
}

#endif // UTIL_HPP
