#ifndef TB_UTILS_H
#define TB_UTILS_H

#include <stdint.h>
#include <stdlib.h>

inline void InitVector(int32_t *data, uint32_t size)
{
  for (uint32_t i = 0; i < size; ++i)
    data[i] = (rand() % 2) ? rand() : -rand();
}

inline bool CompareVectors(int32_t *a, int32_t *b, uint32_t size)
{
  for (uint32_t i = 0; i < size; ++i)
    if (a[i] != b[i]) return false;
  return true;
}

#endif // TB_UTILS_H
