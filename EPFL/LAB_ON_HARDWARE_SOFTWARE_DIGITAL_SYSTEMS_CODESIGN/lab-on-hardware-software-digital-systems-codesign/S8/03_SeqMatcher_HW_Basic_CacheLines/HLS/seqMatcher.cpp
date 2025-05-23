#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <ap_int.h>

#include "seqMatcher.h"


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
int8_t CalcScore(char * A, uint8_t lengthA, char * B, uint8_t lengthB)
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
  int8_t tableMax;
  uint8_t i, j;

  for (j = 0; j <= lengthA; ++ j) // <= because we are adding a 0 on the top and the left
    M[0][j] = 0;
  for (i = 0; i <= lengthB; ++ i)
    M[i][0] = 0;

  tableMax = -128; //tableMax_i = 0; tableMax_j = 0;
  for (i = 1; i <= lengthB; ++ i) { // Use <= because we have in M one extra zero on the top and the left.
    for (j = 1; j <= lengthA; ++ j) {
      int8_t hitValue, top, left, max;
      hitValue = M[i-1][j-1] + ( (A[j-1] == B[i-1]) ? 1 : -1 ); // A and B start on 
      top = M[i-1][j] - 1;
      left = M[i][j-1] - 1;
      max = hitValue > top ? (hitValue > left ? hitValue : left) : (top > left ? top : left);
      if (max < 0) max = 0;
      if (max > tableMax) {
        tableMax = max;
      }
      M[i][j] = max;
    }
  }

  return tableMax;
}


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
uint32_t SeqMatcher_HW(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
    char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
    int8_t * scores)
{
#pragma HLS INTERFACE mode=s_axilite port=numDBEntries
#pragma HLS INTERFACE mode=s_axilite port=numSeqsSpecimen
#pragma HLS INTERFACE mode=s_axilite port=return
#pragma HLS INTERFACE mode=m_axi depth=1024 port=seqsDB offset=slave bundle=masterPort
#pragma HLS INTERFACE mode=m_axi depth=1024 port=seqsSpecimen offset=slave bundle=masterPort
#pragma HLS INTERFACE mode=m_axi depth=1024 port=lengthsDB offset=slave bundle=masterPort
#pragma HLS INTERFACE mode=m_axi depth=1024 port=lengthsSpecimen offset=slave bundle=masterPort
#pragma HLS INTERFACE mode=m_axi depth=1024 port=scores offset=slave bundle=masterPort num_write_outstanding=64 max_write_burst_length=32 latency=30


  uint8_t * pLengthsDB = lengthsDB, * pLengthsSpec;
  int8_t * pScores = scores;
  char * pDB = seqsDB, * pSpec;
  uint32_t comparisons = 0;
  char currentSpec[MAX_SEQ_LENGTH];
  char currentDB[MAX_SEQ_LENGTH];

  for (uint32_t iDB = 0; iDB < numDBEntries; ++iDB) {
    memcpy(...); // @TODO
    pLengthsSpec = lengthsSpecimen;
    pSpec = seqsSpecimen;
    // Compare current DB entry with all specimen entries.
    for (uint32_t iSpec = 0; iSpec < numSeqsSpecimen; ++ iSpec) {
      memcpy(...); // @TODO
      //*pScores++ = CalcScore(pDB, *pLengthsDB, pSpec, *pLengthsSpec);
      ... // @ TODO
      ++ comparisons;
      pSpec += *pLengthsSpec++;
    }
    pDB += *pLengthsDB++; // Pass to the next sequence in the DB
  }

  return comparisons;
}

