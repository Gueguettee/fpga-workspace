#include "fft.h"

unsigned int reverse_bits(unsigned int input, int num_stages) {
	int i, rev = 0;
	for (i = 0; i < num_stages; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
		rev = (rev << 1) | (input & 1);
		input = input >> 1;
	}
	return rev;
}

void bit_reverse(FFT_TYPE *X_real, FFT_TYPE *X_imag, int nfft, int num_stages, FFT_TYPE *OUT_real, FFT_TYPE *OUT_imag) {
    int reversed;
    FFT_TYPE temp_real, temp_imag;
  
    for (int i = 0; i < nfft; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
	    reversed = reverse_bits(i, num_stages); // Find the bit reversed index
		if (i <= reversed) {
			// Swap the real values
            temp_real = X_real[i];
            temp_imag = X_imag[i];
            OUT_real[i] = X_real[reversed];
            OUT_imag[i] = X_imag[reversed];
            OUT_real[reversed] = temp_real;
            OUT_imag[reversed] = temp_imag;
		}
	}
}

void fft_stage(int stage, FFT_TYPE *X_real, FFT_TYPE *X_imag, int nfft, FFT_TYPE *Out_real, FFT_TYPE *Out_imag) {
    int DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
    int numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
    FFT_TYPE e = -2 * M_PI / DFTpts;
    FFT_TYPE a = 0.0;
    // Perform butterflies for j-th stage
    for (int j = 0; j < numBF; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=(1<<(MAX_NSTAGES-2)) max=(1<<(MAX_NSTAGES-2))
        // Can be computed once as a look-up table (for the last stage)
        FFT_TYPE c = cos(a);
        FFT_TYPE s = sin(a);
        a = a + e;
        // Compute butterflies that use same W**k
        for (int i = j; i < nfft; i += DFTpts) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
            int i_lower = i + numBF; // index of lower point in butterfly
            FFT_TYPE temp_real = c * X_real[i_lower] - s * X_imag[i_lower];
            FFT_TYPE temp_imag = c * X_imag[i_lower] + s * X_real[i_lower];
            Out_real[i_lower] = X_real[i] - temp_real;
            Out_imag[i_lower] = X_imag[i] - temp_imag;
            Out_real[i] = X_real[i] + temp_real;
            Out_imag[i] = X_imag[i] + temp_imag;
        }
    }
}

void fft_hw(FFT_TYPE *In_real, FFT_TYPE *In_imag, int log2_nfft, FFT_TYPE *Out_real, FFT_TYPE *Out_imag) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE m_axi depth=MAX_NFFT/NUM_SEGMENTS port=In_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT/NUM_SEGMENTS port=In_imag offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT/NUM_SEGMENTS port=Out_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT/NUM_SEGMENTS port=Out_imag offset=slave

	// setbuf(stdout, NULL); // For debugging purpose

    int nstages = log2_nfft;
    int nfft = (1 << nstages); // NFFT = 2^NStages
    FFT_TYPE Stage_real[2][MAX_NFFT/NUM_SEGMENTS];
    FFT_TYPE Stage_imag[2][MAX_NFFT/NUM_SEGMENTS];
    int stageFlipFlop = 0;

    bit_reverse(In_real, In_imag, nfft, nstages, Stage_real[0], Stage_imag[0]);

    for (int stage = 1; stage < nstages; stage++) { // Do M-1 stages of butterflies
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
    	//printf("stage: %d \n", stage);
        fft_stage(stage, Stage_real[stageFlipFlop%2], Stage_imag[stageFlipFlop%2], nfft, Stage_real[(stageFlipFlop+1)%2], Stage_imag[(stageFlipFlop+1)%2]);
        stageFlipFlop++;
    }
    fft_stage(nstages, Stage_real[stageFlipFlop%2], Stage_imag[stageFlipFlop%2], nfft, Out_real, Out_imag);
}
