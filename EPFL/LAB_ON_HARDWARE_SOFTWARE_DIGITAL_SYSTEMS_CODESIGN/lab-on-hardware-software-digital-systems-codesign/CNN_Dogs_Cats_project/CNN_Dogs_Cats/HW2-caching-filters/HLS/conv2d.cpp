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
#pragma HLS INTERFACE m_axi depth=4129024 port=output offset=slave //4129024, MAX_WIDTH * MAX_HEIGHT * MAX_FILTERS
#pragma HLS INTERFACE m_axi depth=(MAX_CHANNELS * MAX_FILTERS * COEFFS_MULTIPLICATOR) port=filters offset=slave
//#pragma HLS INTERFACE m_axi depth=MAX_CHANNELS port=biases offset=slave

  for (TFXP iFilter = 0; iFilter < numFilters; ++ iFilter) {
  #pragma HLS LOOP_TRIPCOUNT min=MAX_FILTERS max=MAX_FILTERS
    TFXP tempFilters[MAX_CHANNELS][3][3];
    for (TFXP iChannel = 0; iChannel < numChannels; ++ iChannel) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
      for (TFXP cy = 0; cy < convHeight; ++ cy) {
      #pragma HLS LOOP_TRIPCOUNT min=3 max=3
        for (TFXP cx = 0; cx < convWidth; ++cx) {
        #pragma HLS LOOP_TRIPCOUNT min=3 max=3
          tempFilters[iChannel][cy][cx] = *filters;
          ++filters;
        }
      }
    }
    for (TFXP y = 0; y < (inputHeight-2); ++y) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_HEIGHT-2 max=MAX_HEIGHT-2
      for (TFXP x = 0; x < (inputWidth-2); ++ x) {
      #pragma HLS LOOP_TRIPCOUNT min=MAX_WIDTH-2 max=MAX_WIDTH-2
        TFXP acc;
        acc = 0;
        for (TFXP iChannel = 0; iChannel < numChannels; ++ iChannel) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_CHANNELS max=MAX_CHANNELS
          for (TFXP cy = 0; cy < convHeight; ++ cy) {
          #pragma HLS LOOP_TRIPCOUNT min=3 max=3
            for (TFXP cx = 0; cx < convWidth; ++cx) {
            #pragma HLS LOOP_TRIPCOUNT min=3 max=3
              //acc += filters[iFilter][iChannel][cy][cx] * input[iChannel][y+cy][x+cx];
              TFXP v, f;
              f = tempFilters[iChannel][cy][cx];
              //f = *(filters + iFilter*numChannels*convHeight*convWidth + iChannel*convHeight*convWidth + cy*convWidth + cx);
              //v = tempInput[iChannel][y + cy][x + cx];
              v = *(input + iChannel*inputWidth*inputHeight + (y+cy)*inputWidth + (x+cx));
              acc += FXP_Mult(f, v, DECIMALS);
            }
          }
        }
        //output[iFilter][y][x] = acc;
        *(output + iFilter * (inputHeight-2)*(inputWidth-2) + y*(inputWidth-2) + x) = acc;
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
