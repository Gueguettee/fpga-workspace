#include "conv2d.h"

TFXP FXP_Mult(TFXP a, TFXP b, TFXP decimalBits)
{
  //return a*b;
  TFXP_MULT res = (TFXP_MULT)a * (TFXP_MULT)b;
  res = res >> decimalBits;
  return (TFXP)res;
}

void Conv2D_HW(TFXP *input, TFXP *output, TFXP *filters,// TFXP *biases,
  TFXP numChannels, TFXP numFilters,
  TFXP inputWidth, TFXP inputHeight,
  TFXP convWidth, TFXP convHeight) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=numChannels
#pragma HLS INTERFACE s_axilite port=numFilters
#pragma HLS INTERFACE s_axilite port=inputWidth
#pragma HLS INTERFACE s_axilite port=inputHeight
#pragma HLS INTERFACE s_axilite port=convWidth
#pragma HLS INTERFACE s_axilite port=convHeight
#pragma HLS INTERFACE m_axi depth=1032256 port=input offset=slave //1032256, MAX_WIDTH * MAX_HEIGHT * MAX_CHANNELS
#pragma HLS INTERFACE m_axi depth=4129024 port=output offset=slave //num_write_outstanding=N_UNROLL_OUTPUT //4129024, MAX_WIDTH * MAX_HEIGHT * MAX_FILTERS
#pragma HLS INTERFACE m_axi depth=(MAX_CHANNELS * MAX_FILTERS * COEFFS_MULTIPLICATOR) port=filters offset=slave
//#pragma HLS INTERFACE m_axi depth=MAX_CHANNELS port=biases offset=slave

	TFXP tempFilters[MAX_CHANNELS][9*N_UNROLL_OUTPUT];
  #pragma HLS array_partition variable=tempFilters type=cyclic factor=9*N_UNROLL_OUTPUT dim=2
  //#pragma HLS array_partition variable=tempFilters type=cyclic factor=9 dim=3

	TFXP tempInput[3][4064];
  #pragma HLS array_partition variable=tempInput type=cyclic factor=3 dim=1

  TFXP acc[N_UNROLL_OUTPUT];
  #pragma HLS array_partition variable=acc type=cyclic factor=N_UNROLL_OUTPUT dim=0

  for (TFXP iFilter = 0; iFilter < numFilters; iFilter += N_UNROLL_OUTPUT) {
  #pragma HLS LOOP_TRIPCOUNT min=MAX_FILTERS max=MAX_FILTERS
    for (TFXP iChannel = 0; iChannel < numChannels; ++ iChannel) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
      for (TFXP cxy = 0; cxy < 9; ++cxy) {
      #pragma HLS LOOP_TRIPCOUNT min=9 max=9
      #pragma HLS unroll factor=9
        for (TFXP iF = 0; iF < N_UNROLL_OUTPUT; ++iF) {
        #pragma HLS LOOP_TRIPCOUNT min=N_UNROLL_OUTPUT max=N_UNROLL_OUTPUT
        #pragma HLS unroll factor=N_UNROLL_OUTPUT
          tempFilters[iChannel][cxy + iF*9] = *(filters + (iFilter + iF) * numChannels * 9 + iChannel * 9 + cxy);
        }
      }
      for (TFXP cy = 0; cy < 3; ++ cy) {
      #pragma HLS LOOP_TRIPCOUNT min=3 max=3
      #pragma HLS unroll factor=3
        for (TFXP x = 0; x < inputWidth; ++x) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_WIDTH max=MAX_WIDTH
          tempInput[cy][iChannel*inputWidth + x] = *(input + iChannel*inputHeight*inputWidth + cy*inputWidth + x);
        }
      }
    }
    TFXP iCy = 0;
    for (TFXP y = 0; y < (inputHeight-2); ++y) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_HEIGHT-2 max=MAX_HEIGHT-2
      for (TFXP x = 0; x < (inputWidth-2); ++ x) {
      #pragma HLS LOOP_TRIPCOUNT min=MAX_WIDTH-2 max=MAX_WIDTH-2
        for (TFXP iF = 0; iF < N_UNROLL_OUTPUT; ++iF) {
        #pragma HLS LOOP_TRIPCOUNT min=N_UNROLL_OUTPUT max=N_UNROLL_OUTPUT
        #pragma HLS unroll factor=N_UNROLL_OUTPUT
          acc[iF] = 0;
        }
        for (TFXP iChannel = 0; iChannel < numChannels; ++iChannel) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
          for (TFXP cxyf = 0; cxyf < 9*N_UNROLL_OUTPUT; ++cxyf) {
          #pragma HLS LOOP_TRIPCOUNT min=9*N_UNROLL_OUTPUT max=9*N_UNROLL_OUTPUT
          #pragma HLS unroll factor=9*N_UNROLL_OUTPUT
            TFXP cxy = cxyf % 9;
            TFXP iF = cxyf / 9;
            TFXP v = tempInput[(cxy / 3 + iCy) % 3][iChannel * inputWidth + x + cxy % 3];
            acc[iF] += FXP_Mult(tempFilters[iChannel][cxy + iF * 9], v, DECIMALS);
          }
        }
        for (TFXP iF = 0; iF < N_UNROLL_OUTPUT; ++iF) {
        #pragma HLS LOOP_TRIPCOUNT min=N_UNROLL_OUTPUT max=N_UNROLL_OUTPUT
        #pragma HLS unroll factor=N_UNROLL_OUTPUT
          *(output + (iFilter + iF) * (inputHeight - 2) * (inputWidth - 2) + y * (inputWidth - 2) + x) = acc[iF];
        }
      }
      for (TFXP iChannel = 0; iChannel < numChannels; ++ iChannel) {
      #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
        for (TFXP x = 0; x < inputWidth; ++x) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_WIDTH max=MAX_WIDTH
          tempInput[iCy][iChannel*inputWidth + x] = *(input + iChannel*inputHeight*inputWidth + (y+3)*inputWidth + x);
        }
      }
      iCy += 1;
      if (iCy == 3) {
        iCy = 0;
      }
    }
  }
  /*for (TFXP iChannel = 0; iChannel < numChannels; ++ iChannel) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
    for (TFXP iPixel = 0; iPixel < inputWidth*inputHeight; ++ iPixel) {
      #pragma HLS LOOP_TRIPCOUNT min=MAX_HEIGHT*MAX_WIDTH max=MAX_HEIGHT*MAX_WIDTH
      *input = *input + *biases;
      if ( *input & 0x80000000 ) {
        *input = 0;
      }
      ++ input;
    }
    ++ biases;
  }*/
}
