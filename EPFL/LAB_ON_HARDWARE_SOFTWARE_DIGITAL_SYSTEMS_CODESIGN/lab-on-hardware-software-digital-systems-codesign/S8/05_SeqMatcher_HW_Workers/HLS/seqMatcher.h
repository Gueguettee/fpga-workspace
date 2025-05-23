#ifndef SEQMATCHER_H
#define SEQMATCHER_H

#define MAX_SEQ_LENGTH 32
#define NUM_WORKERS 8

typedef int8_t TPathMatrix[MAX_SEQ_LENGTH+1][MAX_SEQ_LENGTH+1];

struct TDataIn {
  ... // @TODO
  uint32_t queryID; // To write outputs in right order
};

struct TDataOut {
  uint32_t queryID;
  ... // @ TODO
};

////////////////////////////////
void CalcScore(hls::stream<TDataIn> & input, hls::stream<TDataOut> & output);

uint32_t SeqMatcher_HW(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
    int8_t * scores);


#endif // SEQMATCHER_H

