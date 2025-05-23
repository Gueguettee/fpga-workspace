#ifndef SEQMATCHER_H
#define SEQMATCHER_H

#define MAX_SEQ_LENGTH 32

// Uncomment the following line to get an indication of the app progress. Comment to measure times!
#define PRINT_PROGRESS

typedef int8_t TPathMatrix[MAX_SEQ_LENGTH+1][MAX_SEQ_LENGTH+1];

///////////////////////////////////////////////////////////////////////////////
int8_t CalcScore(char * A, uint8_t lengthA, char * B, uint8_t lengthB);
uint32_t ReadLines(char * dest, uint8_t * lengths, const char * fileName, uint32_t numLines);
bool DumpScores(int8_t * scores, uint32_t numScores, const char * fileName);

uint32_t SeqMatcher(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
    int8_t * scores, uint64_t & elapsedTime, double & cpuUtilization);


#endif // SEQMATCHER_H

