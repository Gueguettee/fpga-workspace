#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <ap_int.h>

#include <hls_task.h>
#include <hls_np_channel.h>

#include "seqMatcher.h"


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void CalcScore(hls::stream<TDataIn> & input, hls::stream<TDataOut> & output)
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
  TDataOut dataOut;
  TDataIn dataIn;

  // Read from input stream
  dataIn = ... // @TODO

  for (uint8_t jj = 0; jj <= ...; ++ jj) // <= because we are adding a 0 on the top and the left @TODO
    M[0][jj] = 0;
  for (uint8_t ii = 0; ii <= ...; ++ ii) // @TODO
    M[ii][0] = 0;

  tableMax = -128;
  for (uint8_t ii = 1; ii <= ...; ++ ii) { // Use <= because we have in M one extra zero on the top and the left. @TODO
    for (uint8_t jj = 1; jj <= ...; ++ jj) { // @TODO
      int8_t hitValue, top, left, max;
      hitValue = M[ii-1][jj-1] + ( (...[jj-1] == ...[ii-1]) ? 1 : -1 ); // A and B start on @TODO
      top = M[ii-1][jj] - 1;
      left = M[ii][jj-1] - 1;
      max = hitValue > top ? (hitValue > left ? hitValue : left) : (top > left ? top : left);
      if (max < 0) max = 0;
      if (max > tableMax) {
        tableMax = max;
      }
      M[ii][jj] = max;
    }
  }

  // Write to the output stream
  dataOut.queryID = dataIn.queryID;
  dataOut... = tableMax; // @TODO
  ...(dataOut); //@TODO
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void ReadInputs(uint32_t numDBEntries, uint32_t numSeqsSpecimen,
  char * seqsDB, char * seqsSpecimen, uint8_t * lengthsDB, uint8_t * lengthsSpecimen,
  hls::stream<TDataIn> & inputStream)
{
  uint8_t * pLengthsDB = lengthsDB, * pLengthsSpec;
  char * pDB = seqsDB, * pSpec;
  TDataIn dataIn;
  uint32_t comparisons = 0;

  for (uint32_t iDB = 0; iDB < numDBEntries; ++iDB) {
    memcpy(...); // @TODO
    dataIn.lengthA = *pLengthsDB;
    pLengthsSpec = lengthsSpecimen;
    pSpec = seqsSpecimen;
    // Dispatch the comparison of current DB entry with all specimen entries.
    for (uint32_t iSpec = 0; iSpec < numSeqsSpecimen; ++ iSpec) {
      memcpy(...); // @TODO
      dataIn.lengthB = ... // @TODO
      dataIn.queryID = ... // @TODO
      inputStream.write(...); // @TODO
      ++ comparisons;
      pSpec += *pLengthsSpec++;
    }
    pDB += *pLengthsDB++; // Pass to the next sequence in the DB
  }
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
void WriteOutputs(hls::stream<TDataOut> & outputStream, int8_t * scores,
  uint32_t numDBEntries, uint32_t numSeqsSpecimen)
{
  for (uint32_t ii = 0; ii < numDBEntries * numSeqsSpecimen; ++ ii) {
    TDataOut output = ...; // @TODO
    scores[output.queryID] = ...; // @TODO
  }
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


  hls_thread_local hls::split::round_robin<...> workerInputs; // @TODO
  hls_thread_local hls::merge::round_robin<...> workerOutputs; // @TODO
  hls_thread_local hls::task workers[...]; // @TODO

  #pragma HLS dataflow
  ReadInputs(numDBEntries, numSeqsSpecimen, seqsDB, seqsSpecimen, lengthsDB, lengthsSpecimen, ...); // @TODO

  workers_gen: for (uint32_t ii = 0; ii < NUM_WORKERS; ++ ii) {
  #pragma HLS unroll
    workers[ii](); // @TODO
  }

  WriteOutputs(...); // @TODO

  return numDBEntries * numSeqsSpecimen;
}

