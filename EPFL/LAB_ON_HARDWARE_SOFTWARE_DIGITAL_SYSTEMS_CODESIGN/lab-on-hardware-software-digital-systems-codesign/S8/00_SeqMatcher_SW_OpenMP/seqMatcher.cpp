#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h> 
#include <locale.h>
#include <assert.h>
#include <unistd.h>
#include <omp.h>
#include "util.hpp"
#include "seqMatcher.h"

///////////////////////////////////////////////////////////////////////////////
int8_t  CalcScore(char * A, uint8_t lengthA, char * B, uint8_t lengthB)
{
  // tableMax <- Max score computed in the table.
  //
  // Matrix M has one more row and one more column than the maximum size of seq1 and seq2. Therefore, 
  // index M[i][j] corresponds to A[i-1] and B[-1] if we use the indexes of M to access A and B.
  // In the examples, A is laid on top of M left to right, B is laid on the left, vertically.
  // Therefore, seq1=A, seq2=B

// A = ACACACAC
// B = TGTGTGTG
// 
//           <-i->
//             A
//
//          ACACACAC
//         000000000
//       T 0
//       G 0
// |     T 0
// j B   G 0
// |     T 0
//       G 0
//       T 0
//       G 0
  
  TPathMatrix M;
  uint8_t i, j;
  int8_t tableMax = -128;

  for (j = 0; j <= lengthA; ++ j) // <= because we are adding a 0 on the top and the left
    M[0][j] = 0;
  for (i = 0; i <= lengthB; ++ i)
    M[i][0] = 0;

  tableMax = -128;
  for (i = 1; i <= lengthB; ++ i) { // Use <= because we have in M one extra zero on the top and the left.
    for (j = 1; j <= lengthA; ++ j) {
      int8_t hitValue, top, left, max;
      hitValue = M[i-1][j-1] + ( (A[j-1] == B[i-1]) ? 1 : -1 ); // A and B start on 
      top = M[i-1][j] - 1;
      left = M[i][j-1] - 1;
      max = hitValue > top ? (hitValue > left ? hitValue : left) : (top > left ? top : left);
      if (max < 0) max = 0;
      if (max > tableMax)
        tableMax = max;
      M[i][j] = max;
    }
  }

  return tableMax;
}

///////////////////////////////////////////////////////////////////////////////
uint32_t ReadLines(char * dest, uint8_t * lengths, const char * fileName, uint32_t numLines)
{
  FILE * input;
  uint32_t readLines = 0;

  if ( (input = fopen(fileName, "rt")) == NULL ) {
    printf("Error opening file [%s]\n", fileName);
    return 0;
  }

  for (readLines = 0; readLines < numLines; ++ readLines) {
    char line[MAX_SEQ_LENGTH+2];  // + newline + NULL
    if (fgets(line, MAX_SEQ_LENGTH+2, input) == NULL)
      break;
    uint32_t lineSize = strlen(line);
    uint32_t iChar;
    uint8_t length = 0;
    for (iChar = 0; (iChar < lineSize) && (iChar < MAX_SEQ_LENGTH); ++ iChar) {
      if (line[iChar] != '\n') {  // New lines are included in the string by fgets
        *dest++ = line[iChar];
        ++ length;
      }
    }
    *lengths++ = length;
  }

  fclose(input);
  return readLines;
}

///////////////////////////////////////////////////////////////////////////////
bool DumpScores(int8_t * scores, uint32_t numScores, const char * fileName)
{
  FILE * output;

  if ( (output = fopen(fileName, "wb")) == NULL ) {
    printf("Error opening file [%s]\n", fileName);
    return false;
  }

  if ( fwrite(scores, sizeof(int8_t), numScores, output) != numScores )
  {
    printf("Error writing scores.\n");
    return false;
  }

  fclose(output);
  return true;
}

///////////////////////////////////////////////////////////////////////////////
uint32_t SeqMatcher(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
    int8_t * scores, uint64_t & elapsedTime, double & cpuUtilization)
{
  struct timespec start, end;
  struct timespec startCPUTime, endCPUTime;
  uint32_t offsetsDB[NUM_THREADS];
  uint32_t comparisons = 0;

  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, & startCPUTime);
  clock_gettime(CLOCK_MONOTONIC_RAW, &start);

  // Compute the starting point for each thread.
  uint32_t offset = 0, threadIndex = 0, tmp = 0, seqsPerThread = numDBEntries / NUM_THREADS;
  uint8_t * pLengthsDB1 = lengthsDB;
  for (uint32_t ii = 0; ii < numDBEntries; ++ ii) {
    if (tmp == seqsPerThread)
      tmp = 0;
    if (tmp == 0)
      offsetsDB[threadIndex++] = offset;
    offset += *pLengthsDB1++;
    ++ tmp;
  }

#pragma omp parallel reduction(+: comparisons) num_threads(NUM_THREADS)
  {
    int threadID = omp_get_thread_num();
    char * pDB, * pSpec;
    int8_t * pScores;
    uint8_t * pLengthsDB, * pLengthsSpec;

    pLengthsDB = &lengthsDB[threadID*seqsPerThread];
    pDB = seqsDB + (offsetsDB[threadID])*sizeof(char);
    pScores = &scores[threadID*seqsPerThread*numSeqsSpecimen];

    for (uint32_t iDB = 0; iDB < seqsPerThread; ++iDB) {
      #ifdef  PRINT_PROGRESS
      if ( (iDB % 100) == 0 ) { // Beware of this affecting the time measurement!!!!!!
        printf("%1.0f%% of DB entries processed...\r", ((float)iDB/seqsPerThread)*100 );
        fflush(stdout);
      }
      #endif
      pLengthsSpec = lengthsSpecimen;
      pSpec = seqsSpecimen;
      // Compare current DB entry with all specimen entries.
      for (uint32_t iSpec = 0; iSpec < numSeqsSpecimen; ++ iSpec) {
        *pScores++ = CalcScore(pDB, *pLengthsDB, pSpec, *pLengthsSpec);
        ++ comparisons;
        pSpec += *pLengthsSpec++;
      }
      pDB += *pLengthsDB++; // Pass to the next sequence in the DB
    }
  }

  clock_gettime(CLOCK_MONOTONIC_RAW, &end);
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, & endCPUTime);
  elapsedTime = CalcTimeDiff(end, start);
  cpuUtilization = (double)CalcTimeDiff(endCPUTime, startCPUTime) / elapsedTime;

  return comparisons;
}

