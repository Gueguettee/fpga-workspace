#include <ap_int.h>

// output[i] = input1[i] + input2[i] + accum;
void AddVectors(ap_uint<32> * input1, ap_uint<32> * input2, ap_uint<32> * output, ap_uint<32> length, ap_uint<32> accum)
{
#pragma HLS INTERFACE s_axilite port=length
#pragma HLS INTERFACE s_axilite port=accum
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE m_axi depth=1024 port=input1 offset=slave
#pragma HLS INTERFACE m_axi depth=1024 port=input2 offset=slave
#pragma HLS INTERFACE m_axi depth=1024 port=output offset=slave

  if (length > 8*1024*1024)
    length = 8*1024*1024;

  for (ap_uint<32> ii = 0; ii < length; ++ ii) {
    output[ii] = input1[ii] + input2[ii] + accum;
  }
}
