#include "fft.h"

unsigned int reverse_bits(unsigned int input, int num_stages) {
	int i, rev = 0;
	for (i = 0; i < MAX_NSTAGES; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
        if (i >= num_stages) break;
		rev = (rev << 1) | (input & 1);
		input = input >> 1;
	}
	return rev;
}

void bit_reverse(FXP_TYPE *X_real, FXP_TYPE *X_imag, int nfft, int num_stages, FXP_TYPE *OUT_real, FXP_TYPE *OUT_imag) {
    for (int i = 0; i < MAX_NFFT; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        if (i >= nfft) break;
        int reversed = reverse_bits(i, num_stages);
        OUT_real[reversed] = X_real[i];
        OUT_imag[reversed] = X_imag[i];
    }
}

void fft_stage(int stage, FXP_TYPE *X_real, FXP_TYPE *X_imag, int nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {
    int DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
    int numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
    FXP_TYPE temp_Out_real[MAX_NFFT];   // TODO could be optimized
    FXP_TYPE temp_Out_imag[MAX_NFFT];   // TODO could be optimized
    // Perform butterflies for j-th stage
    for (int j = 0; j < 1<<(MAX_NSTAGES-1); j++) {
    #pragma HLS LOOP_TRIPCOUNT min=(1<<(MAX_NSTAGES-1)) max=(1<<(MAX_NSTAGES-1))
        if (j >= numBF) break;
        // Can be computed once as a look-up table (for the last stage)
        int twiddle_idx = j << (MAX_NSTAGES-stage);
        FXP_TYPE c = twiddle_real[twiddle_idx];
        int twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;
        if (twiddle_idx_imag >= MAX_TWIDDLES) {
            twiddle_idx_imag -= MAX_TWIDDLES;
        }
        FXP_TYPE s = twiddle_real[twiddle_idx_imag];
        if (s > 0) {
            s = -s;
        }
        // Compute butterflies that use same W**k
        for (int i = j; i < MAX_NFFT; i += DFTpts) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
            if (i >= nfft) break;
            int i_lower = i + numBF; // index of lower point in butterfly
            FXP_TYPE temp_real = c * X_real[i_lower] - s * X_imag[i_lower];
            FXP_TYPE temp_imag = c * X_imag[i_lower] + s * X_real[i_lower];
            //printf("temp: %.2f \n", (float)temp_real);
            Out_real[i_lower] = (X_real[i] - temp_real) >> 1;
            Out_imag[i_lower] = (X_imag[i] - temp_imag) >> 1;
            temp_Out_real[i] = (X_real[i] + temp_real) >> 1;
            temp_Out_imag[i] = (X_imag[i] + temp_imag) >> 1;
        }
        for (int i = j; i < MAX_NFFT; i += DFTpts) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
            if (i >= nfft) break;
            Out_real[i] = temp_Out_real[i];
            Out_imag[i] = temp_Out_imag[i];
        }
    }
}

void fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_imag offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_imag offset=slave

	// setbuf(stdout, NULL); // For debugging purpose

    int nstages = log2_nfft;
    int nfft = (1 << nstages); // NFFT = 2^NStages

    FXP_TYPE Stage_real[2][MAX_NFFT];
    //#pragma HLS bind_storage variable=Stage_real type=ram_t2p
    #pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_real type=cyclic factor=4 dim=2
	FXP_TYPE Stage_imag[2][MAX_NFFT];
    //#pragma HLS bind_storage variable=Stage_imag type=ram_t2p
    #pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_imag type=cyclic factor=4 dim=2

    ap_uint<1> stageFlipFlop = 0;

    FXP_TYPE temp_In_real[MAX_NFFT];
    FXP_TYPE temp_In_imag[MAX_NFFT];

    FXP_TYPE temp_Out_real[MAX_NFFT];
    FXP_TYPE temp_Out_imag[MAX_NFFT];

    for (int i = 0; i < MAX_NFFT; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        if (i >= nfft) break;
        temp_In_real[i] = In_real[i];
    }
    for (int i = 0; i < MAX_NFFT; i++) {
	#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        if (i >= nfft) break;
		temp_In_imag[i] = In_imag[i];
	}

    bit_reverse(temp_In_real, temp_In_imag, nfft, nstages, Stage_real[0], Stage_imag[0]);

    for (int stage = 1; stage < nstages; stage++) { // Do M-1 stages of butterflies
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
        fft_stage(stage, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], nfft, Stage_real[(int)(stageFlipFlop^1)], Stage_imag[(int)(stageFlipFlop^1)]);
        stageFlipFlop++;
    }
    fft_stage(nstages, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], nfft, temp_Out_real, temp_Out_imag);

    for (int i = 0; i < MAX_NFFT; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        if (i >= nfft) break;
        Out_real[i] = temp_Out_real[i];
    }
    for (int i = 0; i < MAX_NFFT; i++) {
	#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        if (i >= nfft) break;
		Out_imag[i] = temp_Out_imag[i];
	}
}
