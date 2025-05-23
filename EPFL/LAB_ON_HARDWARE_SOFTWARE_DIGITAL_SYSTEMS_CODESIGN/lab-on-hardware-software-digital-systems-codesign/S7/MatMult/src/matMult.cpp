// Test of squared matrix multiplication.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <stdint.h>
#include "util.hpp"

typedef uint32_t TDATA;
const uint32_t MAX_SIZE = 1024;

#define NUM_REPS_SHORT 10
#define NUM_REPS_LONG 3
#define NUM_REPS_LIMIT  512

//const uint32_t NUM_SIZES = 7;
//uint32_t sizes[NUM_SIZES] = {16, 32, 64, 128, 256, 512, 1024};
const uint32_t NUM_SIZES = 13;
uint32_t sizes[NUM_SIZES] = {8, 16, 24, 32, 40, 48, 56, 64, 128, 192, 256, 512, 1024};

TDATA * matrix1[NUM_SIZES], * matrix2[NUM_SIZES]; // Initialized to NULL by default.
TDATA * transp[NUM_SIZES]; // Initialized to NULL by default.
TDATA output[MAX_SIZE * MAX_SIZE];

uint64_t times[NUM_SIZES];

///////////////////////////////////////////////////////////////////////////////
void FreeMatrices()
{
  for (uint32_t ii = 0; ii < NUM_SIZES; ++ ii) {
    if (matrix1[ii] != NULL) { free(matrix1[ii]); matrix1[ii] = NULL; }
    if (matrix2[ii] != NULL) { free(matrix2[ii]); matrix2[ii] = NULL; }
    if (transp[ii] != NULL) { free(transp[ii]); transp[ii] = NULL; }
  }
}


///////////////////////////////////////////////////////////////////////////////
bool AllocMatrices()
{
  bool res = true;

  for (uint32_t ii = 0; ii < NUM_SIZES; ++ ii) {
    if (sizes[ii] > MAX_SIZE) {
      printf("Size number %" PRIu32 " is larger than the maximum (%" PRIu32 " vs. %" PRIu32 ")\n", ii, sizes[ii], MAX_SIZE);
    }
  }

  for (uint32_t ii = 0; res && (ii < NUM_SIZES); ++ ii) {
    res = (matrix1[ii] = (TDATA *)malloc(sizes[ii] * sizes[ii] * sizeof(TDATA))) != NULL;
    res = res && ((matrix2[ii] = (TDATA *)malloc(sizes[ii] * sizes[ii] * sizeof(TDATA))) != NULL);
    res = res && ((transp[ii] = (TDATA *)malloc(sizes[ii] * sizes[ii] * sizeof(TDATA))) != NULL);
  }

  if (!res)
    FreeMatrices();
  return res;
}


///////////////////////////////////////////////////////////////////////////////
void InitSquaredMatrix(TDATA * matrix, uint32_t size)
{
  for (uint32_t h = 0; h < size; ++ h) {
    for (uint32_t w = 0; w < size; ++ w) {
      //matrix[h*size + w] = rand() % 65536;
      matrix[h*size + w] = h*size+w;
    }
  }
}


///////////////////////////////////////////////////////////////////////////////
void InitMatrices()
{
  for (uint32_t ii = 0; ii < NUM_SIZES; ++ ii) {
    InitSquaredMatrix(matrix1[ii], sizes[ii]);
    InitSquaredMatrix(matrix2[ii], sizes[ii]);
  }
}


///////////////////////////////////////////////////////////////////////////////
bool SquaredMatMult(TDATA * matrix1, TDATA * matrix2, TDATA * output, uint32_t size)
{
  for (uint32_t h = 0; h < size; ++ h) {
    for (uint32_t w = 0; w < size; ++ w) {
      TDATA acc = 0;
      for (uint32_t ii = 0; ii < size; ++ ii) {
        acc += matrix1[h*size + ii] * matrix2[ii*size + w];
      }
      output[h*size+w] = acc;
    }
  }

  return true;
}

///////////////////////////////////////////////////////////////////////////////
bool SquaredMatMultTransposed(TDATA * matrix1, TDATA * matrix2, TDATA * transp, TDATA * output, uint32_t size)
{
  for (uint32_t h = 0; h < size; ++ h) {
    for (uint32_t w = 0; w < size; ++ w)
      transp[h*size+w] = matrix2[w*size+h];
  }

  for (uint32_t h = 0; h < size; ++ h) {
    for (uint32_t w = 0; w < size; ++ w) {
      TDATA acc = 0;
      for (uint32_t ii = 0; ii < size; ++ ii) {
        acc += matrix1[h*size + ii] * transp[w*size + ii];
      }
      output[h*size+w] = acc;
    }
  }

  return true;
}


///////////////////////////////////////////////////////////////////////////////
bool PrintMatrix(TDATA * matrix, uint32_t size, const char * header)
{
  if (size > 16)
    return false;

  printf("------\n%s\n------\n", header);
  for (uint32_t h = 0; h < size; ++ h) {
    for (uint32_t w = 0; w < size; ++ w) {
      printf("%" PRIu16 " ", matrix[h*size+w]);
    }
    printf("\n");
  }
  printf("------\n\n");
  return true;
}


///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
  struct timespec start, end;

  srand(time(NULL));

  if (!AllocMatrices()) {
    printf("Error allocating memory.\n");
    return -1;
  }

  InitMatrices();

  for (uint32_t iSize = 0; iSize < NUM_SIZES; ++ iSize) {
    uint32_t size = sizes[iSize];

    printf("\n------\n");
    printf("Measuring time for %" PRIu32 "x%" PRIu32 "\n", size, size);    
    fflush(stdout); 
    memset(output, 0, size * size * sizeof(TDATA));
    // First repetition to warm up cache, discard time.
    SquaredMatMult(matrix1[iSize], matrix2[iSize], output, size);
    //SquaredMatMultTransposed(matrix1[iSize], matrix2[iSize], transp[iSize], output, size);
    // Measure time with potentially warm cache.
    uint32_t numReps = sizes[iSize] < NUM_REPS_LIMIT ? NUM_REPS_SHORT : NUM_REPS_LONG;
    clock_gettime(CLOCK_MONOTONIC_RAW, &start);
    for (uint32_t rep = 0; rep < numReps; ++ rep)
      SquaredMatMult(matrix1[iSize], matrix2[iSize], output, size);
      //SquaredMatMultTransposed(matrix1[iSize], matrix2[iSize], transp[iSize], output, size);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end);
    times[iSize] = CalcTimeDiff(end, start) / numReps;
    printf("Matrix size %" PRIu32 "x%" PRIu32 " --> %0.3lf s (%" PRIu64 " ns)\n", size, size, (times[iSize]/1e9), times[iSize]);
    fflush(stdout);
  }

  printf("SIZExSIZE,time.\n");
  for (uint32_t ii = 0; ii < NUM_SIZES; ++ ii)
    printf("%" PRIu32 ",%" PRIu64 "\n", sizes[ii], times[ii]);

  FreeMatrices();
  return 0;
}

