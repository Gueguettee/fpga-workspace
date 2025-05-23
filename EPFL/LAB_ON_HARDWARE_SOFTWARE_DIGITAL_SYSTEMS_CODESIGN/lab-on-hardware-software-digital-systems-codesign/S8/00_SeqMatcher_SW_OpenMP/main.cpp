#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h> 
#include <locale.h>
#include <assert.h>
#include <omp.h>
#include "util.hpp"
#include "seqMatcher.h"


///////////////////////////////////////////////////////////////////////////////
int main(int argc, char ** argv)
{
  uint32_t numDBEntries;
  uint32_t numSeqsSpecimen;
  char * databaseTitle = NULL;
  char * specimenTitle = NULL;
  char * scoresTitle = NULL;
  char * seqsDB, * seqsSpecimen;
  uint8_t * lengthsDB, * lengthsSpecimen;
  int8_t * scores;
  uint64_t elapsedTime;
  double cpuUtilization;
  bool res = true;
  uint32_t numCores = 0;

  // Obtain arguments from command line.
  setlocale(LC_NUMERIC, "en_US.utf8");  // Enables printing human-readable numbers with %'
  printf("\n");
  if ( (argc != 6) || 
       (sscanf(argv[1], "%u", &numDBEntries) != 1) ||
       (sscanf(argv[2], "%u", &numSeqsSpecimen) != 1) )
  {
    printf("Matches variable-length sequences from one specimen file against a sequence database.\n\n");
    printf("Usage: seqMatcherSW numDBEntries numSeqsSpecimen databaseFile specimenFile scoresFile\n\n");
    printf("Example: ./seqMatcherSW 10000 1000 database.txt specimen.txt scores.bin\n\n");
    return -1;
  }
  databaseTitle = argv[3];
  specimenTitle = argv[4];
  scoresTitle = argv[5];
  printf("Matching %'u DB entries against a specimen with %'u sequences.\n", numDBEntries, numSeqsSpecimen);
  printf("Database file: [%s]\n", databaseTitle);
  printf("Specimen file: [%s]\n", specimenTitle);
  printf("Scores file: [%s]\n", scoresTitle);

  // Allocate memory for all the data arrays
  seqsDB = (char *)malloc(numDBEntries*MAX_SEQ_LENGTH*sizeof(char));
  lengthsDB = (uint8_t *)malloc(numDBEntries*sizeof(uint8_t));
  seqsSpecimen = (char *)malloc(numSeqsSpecimen*MAX_SEQ_LENGTH*sizeof(char));
  lengthsSpecimen = (uint8_t *)malloc(numSeqsSpecimen*sizeof(uint8_t));
  scores = (int8_t *)malloc(numDBEntries*numSeqsSpecimen*sizeof(int8_t));
  if ( (seqsDB == NULL) || (seqsSpecimen == NULL) || (lengthsDB == NULL) || (lengthsSpecimen == NULL) || (scores == NULL) ) {
    printf("Error allocating memory\n");
    res = false;
  }
  
  // Read the database and the specimen file
  if (res) {
    printf("Reading database file [%s]...\n", databaseTitle);
    uint32_t readLines;
    readLines = ReadLines(seqsDB, lengthsDB, databaseTitle, numDBEntries);
    if (readLines != numDBEntries) {
      printf("Error reading database: Read %'u lines instead of %'u\n", readLines, numDBEntries);
      res = false;
    }
    else
      printf("Read %'u lines from the DB\n", readLines);
  }
  if (res) {
    printf("Reading specimen file [%s]...\n", specimenTitle);
    uint32_t readLines;
    readLines = ReadLines(seqsSpecimen, lengthsSpecimen, specimenTitle, numSeqsSpecimen);
    if (readLines != numSeqsSpecimen) {
      printf("Error reading specimen: Read %'u lines instead of %'u\n", readLines, numSeqsSpecimen);
      res = false;
    }
    else
      printf("Read %'u lines from the specimen\n", readLines);
  }

  // Compute the scores
  if (res) {
    numCores = omp_get_num_procs();
    printf("Calculating scores. Num comparisons: %'u * %'u = %'u\n", numDBEntries, numSeqsSpecimen, numDBEntries*numSeqsSpecimen);
    printf("Num cores: %u, Num threads: %u\n", numCores, NUM_THREADS);
    uint32_t comparisons =
      SeqMatcher(numDBEntries, numSeqsSpecimen, seqsDB, seqsSpecimen, lengthsDB, lengthsSpecimen, scores, elapsedTime, cpuUtilization);

    assert(comparisons == numDBEntries * numSeqsSpecimen);
    printf("Calculated %'u scores in %0.3lf s (%'" PRIu64 " ns)\n", comparisons, elapsedTime/1e9, elapsedTime);
    printf("Sequence comparisons per second: %'0.3lf\n", numDBEntries*numSeqsSpecimen / (elapsedTime/1e9) );
    printf("CPU utilization percentage: %0.0lf %%\n", (cpuUtilization * 100) / numCores );

    printf("Dumping scores...\n");
    DumpScores(scores, numDBEntries*numSeqsSpecimen, scoresTitle);
    printf("Scores dumped.\n");
  }

  // Free array memory.
  if (seqsDB != NULL)
    free(seqsDB);
  if (seqsSpecimen != NULL)
    free(seqsSpecimen);
  if (lengthsDB != NULL)
    free(lengthsDB);
  if (lengthsSpecimen != NULL)
    free(lengthsSpecimen);
  if (scores != NULL)
    free(scores);

#ifdef  PRINT_PROGRESS
    printf("\n======\n!!! BEWARE THAT THE TIMINGS MAY BE INCORRECT. COMMENT OUT THE PRINT_PROGRESS DEFINITION IN THE CODE !!!\n======\n");
#endif
 return 0;
}

