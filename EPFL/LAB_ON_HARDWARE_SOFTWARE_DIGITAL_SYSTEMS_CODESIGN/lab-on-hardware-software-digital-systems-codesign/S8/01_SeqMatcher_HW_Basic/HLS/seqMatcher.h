#ifndef SEQMATCHER_H
#define SEQMATCHER_H

#define MAX_SEQ_LENGTH 32
typedef int8_t TPathMatrix[MAX_SEQ_LENGTH+1][MAX_SEQ_LENGTH+1];

////////////////////////////////
int8_t CalcScore(char * A, uint8_t lengthA, char * B, uint8_t lengthB);

uint32_t SeqMatcher_HW(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
    int8_t * scores);


#endif // SEQMATCHER_H

