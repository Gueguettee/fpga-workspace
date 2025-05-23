#include <ap_int.h>

void MovingAvg(ap_uint<32> *input, ap_uint<32> *output, ap_uint<32> length)
{
#pragma HLS INTERFACE s_axilite port=length
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE m_axi depth=1000000 port=input offset=slave
#pragma HLS INTERFACE m_axi depth=1000000 port=output offset=slave

  ap_uint<32> accum = 0;
  ap_uint<32> external, outputIndex;
  for (external = 0; external < 7 - 1; ++ external)
    accum += input[external];

  outputIndex = 0;
  for (external = 7 - 1; external < length; ++ external) {
    accum += input[external];
    output[outputIndex++] = accum / 7;
    accum -= input[external - (7 - 1)];
  }
}
