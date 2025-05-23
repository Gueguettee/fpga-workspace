// Test of squared matrix multiplication.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <stdint.h>
#include "util.hpp"

typedef uint32_t TDATA;
const uint32_t MAX_VECTOR_LENGTH = 1*1024*1024;
const uint32_t MAX_RESULTS = 256;

#define NUM_REPS 5
#define MAX_VECTORS 32

TDATA vector[MAX_VECTORS + 1][MAX_VECTOR_LENGTH]; // 1 extra vector to trash the cache.
uint64_t firstTimes[MAX_RESULTS], otherTimes[MAX_RESULTS];
uint32_t sizes[MAX_RESULTS];
uint32_t results1[MAX_RESULTS], results2[MAX_RESULTS];

///////////////////////////////////////////////////////////////////////////////
void InitVector(TDATA * vector, uint32_t size)
{
  for (uint32_t ii = 0; ii < size; ++ ii) {
      //vector[ii] = rand() % 65536;
      vector[ii] = ii;
  }
}

///////////////////////////////////////////////////////////////////////////////
void TrashCache()
{
  for (uint32_t ii = 0; ii < MAX_VECTOR_LENGTH; ++ ii)
    vector[MAX_VECTORS][ii] = ii;
}

///////////////////////////////////////////////////////////////////////////////
uint32_t AddVectors(uint32_t numVectors, uint32_t size)
{
  // Add the vectors accessing the same element from each vector each time, so 
  // that we generate collisions in the cache ways.
  uint32_t res = 0;
  for (uint32_t ii = 0; ii < size; ++ ii)
    for (uint32_t vv = 0; vv < numVectors; ++ vv)
      res += vector[vv][ii];
  return res;
}


///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
  struct timespec start, end;
  uint64_t elapsedTime;
  uint32_t index;
  uint32_t numVectors = 0;

  if (argc != 2) {
    printf("Usage: multi_vector <numVectors> with numVectors between 1 and %" PRIu32 ".\n", MAX_VECTORS);
    return 0;
  }
  if ( (sscanf(argv[1], "%u", &numVectors) != 1) || (numVectors < 1) || (numVectors > MAX_VECTORS) ) {
    printf("Usage: multi_vector <numVectors> with numVectors between 1 and %" PRIu32 ".\n", MAX_VECTORS);
    return 0;
  }

  printf("Working with %" PRIu32 " vectors\n", numVectors);

  srand(time(NULL));
  for (uint32_t ii = 0; ii < numVectors; ++ ii)
    InitVector(vector[ii], MAX_VECTOR_LENGTH);

  index = 0;
  for (uint32_t size = 512; (size <= MAX_VECTOR_LENGTH) && (index < MAX_RESULTS); size *= 2, ++ index) {
    sizes[index] = size;
    printf("Measuring time for %" PRIu32 " bytes (%" PRIu32 ")\n", size, index);
    results1[index] = 0;
    results2[index] = 0;

    elapsedTime = 0;
    for (uint32_t rep = 0; rep < NUM_REPS; ++ rep) {
      // Make caches cold before every test.
      TrashCache();
      clock_gettime(CLOCK_MONOTONIC_RAW, &start);
      results1[index] += AddVectors(numVectors, size);
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);
      elapsedTime += CalcTimeDiff(end, start);
    }
    firstTimes[index] = elapsedTime / NUM_REPS;

    // We do not trash the caches here, so even the first repetition has potentially a warm cache.

    clock_gettime(CLOCK_MONOTONIC_RAW, &start);
    for (uint32_t rep = 0; rep < NUM_REPS; ++ rep)
      results2[index] += AddVectors(numVectors, size);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end);
    otherTimes[index] = CalcTimeDiff(end, start) / NUM_REPS;
  }

  printf("SIZE, 1st time, others time.\n");
  for (uint32_t ii = 0; ii < index; ++ ii)
    printf("%" PRIu32 ",%" PRIu64 ",%" PRIu64 "\n", sizes[ii], firstTimes[ii], otherTimes[ii]);

  return 0;
}

