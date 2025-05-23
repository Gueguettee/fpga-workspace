#include "fft.h"

inline FXP_TYPE Float2Fxp(float value)
{
    return (FXP_TYPE)(value);
}

inline float Fxp2Float(FXP_TYPE value)
{
  return (float)(value);
}

INT_BITS_STAGES_TYPE reverse_bits(INT_BITS_STAGES_TYPE input, INT_NSTAGE_TYPE num_stages) {
    INT_BITS_STAGES_TYPE reversed = input.reverse();
    return reversed.range(MAX_NSTAGES - 1, MAX_NSTAGES - num_stages);   // Return only the 'num_stages' least significant bits of the reversed value
}

void bit_reverse(FXP_TYPE *X_real, FXP_TYPE *X_imag, INT_NFFT_TYPE nfft, INT_NSTAGE_TYPE num_stages, FXP_TYPE *OUT_real, FXP_TYPE *OUT_imag) {
    for (INT_NFFT_TYPE i = 0; i < MAX_NFFT_BAILEY; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        if (i >= nfft) break;
        INT_BITS_STAGES_TYPE reversed = reverse_bits(i, num_stages);
        OUT_real[reversed] = X_real[i];
        OUT_imag[reversed] = X_imag[i];
    }
}

void fft_stage(INT_NSTAGE_TYPE stage, FXP_TYPE *X_real, FXP_TYPE *X_imag, INT_NFFT_TYPE nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {
    INT_NFFT_TYPE DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
    INT_NFFT_TYPE numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
    FXP_TYPE temp_Out_real[MAX_NFFT_BAILEY];   // TODO could be optimized
    FXP_TYPE temp_Out_imag[MAX_NFFT_BAILEY];   // TODO could be optimized
    // Perform butterflies for j-th stage
    for (INT_NFFT_TYPE j = 0; j < 1<<(MAX_NSTAGES_BAILEY-1); j++) {
    #pragma HLS LOOP_TRIPCOUNT min=(1<<(MAX_NSTAGES_BAILEY-1)) max=(1<<(MAX_NSTAGES_BAILEY-1))
        if (j >= numBF) break;
        // Can be computed once as a look-up table (for the last stage)
        INT_NFFT_TYPE twiddle_idx = j << (MAX_NSTAGES_BAILEY-stage);
        FXP_TYPE c = twiddle_real[twiddle_idx];
        INT_NFFT_TYPE twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;
        if (twiddle_idx_imag >= MAX_TWIDDLES) {
            twiddle_idx_imag -= MAX_TWIDDLES;
        }
        FXP_TYPE s = twiddle_real[twiddle_idx_imag];
        if (s > 0) {
            s = -s;
        }
        // Compute butterflies that use same W**k
        for (INT_NFFT_TYPE i = j; i < MAX_NFFT_BAILEY; i += DFTpts) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS PIPELINE II=1
            if (i >= nfft) break;
            INT_NFFT_TYPE i_lower = i + numBF; // index of lower point in butterfly
            FXP_TYPE temp_real = c * X_real[i_lower] - s * X_imag[i_lower];
            FXP_TYPE temp_imag = c * X_imag[i_lower] + s * X_real[i_lower];
            Out_real[i_lower] = (X_real[i] - temp_real) >> 1;
            Out_imag[i_lower] = (X_imag[i] - temp_imag) >> 1;
            temp_Out_real[i] = (X_real[i] + temp_real) >> 1;
            temp_Out_imag[i] = (X_imag[i] + temp_imag) >> 1;
        }
        for (INT_NFFT_TYPE i = j; i < MAX_NFFT_BAILEY; i += DFTpts) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS PIPELINE II=1
            if (i >= nfft) break;
            Out_real[i] = temp_Out_real[i];
            Out_imag[i] = temp_Out_imag[i];
        }
    }
}

void FFT(FXP_TYPE *In_real, FXP_TYPE *In_imag, INT_NSTAGE_TYPE log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {

    FXP_TYPE Stage_real[2][MAX_NFFT_BAILEY];
    #pragma HLS bind_storage variable=Stage_real type=ram_t2p impl=bram
    #pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=2
	FXP_TYPE Stage_imag[2][MAX_NFFT_BAILEY];
    #pragma HLS bind_storage variable=Stage_imag type=ram_t2p impl=bram
    #pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=2

    INT_NSTAGE_TYPE nstages = log2_nfft;
    INT_NFFT_TYPE nfft = 1 << nstages;

    ap_uint<1> stageFlipFlop = 0;

    bit_reverse(In_real, In_imag, nfft, nstages, Stage_real[0], Stage_imag[0]);

    for (INT_NSTAGE_TYPE stage = 1; stage < nstages; stage++) { // Do M-1 stages of butterflies
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES_BAILEY-1 max=MAX_NSTAGES_BAILEY-1
        fft_stage(stage, Stage_real[stageFlipFlop], Stage_imag[stageFlipFlop], nfft, Stage_real[(stageFlipFlop^1)], Stage_imag[(stageFlipFlop^1)]);
        stageFlipFlop++;
    }
    fft_stage(nstages, Stage_real[stageFlipFlop], Stage_imag[stageFlipFlop], nfft, Out_real, Out_imag);
}

void ComputeBaileyFFT(INT_NSTAGE_TYPE log2_nfft, hls::stream<TDataIntern> & inputStream, hls::stream<TDataIntern> & outputStream) {

    #pragma HLS inline off

    INT_NFFT_TYPE N = 1 << log2_nfft;
    INT_NSTAGE_TYPE log2_r = log2_nfft / 2;
    INT_NSTAGE_TYPE log2_c = log2_nfft - log2_r;
    INT_NFFT_TYPE nb_row = 1 << log2_r;
    INT_NFFT_TYPE nb_col = 1 << log2_c;

    FXP_TYPE stage_real[MAX_NFFT_BAILEY][MAX_NFFT_BAILEY];
    #pragma HLS array_partition variable=stage_real type=cyclic factor=NUM_WORKERS dim=1
    // #pragma HLS array_partition variable=stage_real type=cyclic factor=NUM_WORKERS dim=2
    FXP_TYPE stage_imag[MAX_NFFT_BAILEY][MAX_NFFT_BAILEY];
    #pragma HLS array_partition variable=stage_imag type=cyclic factor=NUM_WORKERS dim=1
    // #pragma HLS array_partition variable=stage_imag type=cyclic factor=NUM_WORKERS dim=2
    FXP_TYPE temp_real[MAX_NFFT_BAILEY][MAX_NFFT_BAILEY];
    #pragma HLS array_partition variable=temp_real type=cyclic factor=NUM_WORKERS dim=1
    // #pragma HLS array_partition variable=temp_real type=cyclic factor=NUM_WORKERS dim=2
    FXP_TYPE temp_imag[MAX_NFFT_BAILEY][MAX_NFFT_BAILEY];
    #pragma HLS array_partition variable=temp_imag type=cyclic factor=NUM_WORKERS dim=1
    // #pragma HLS array_partition variable=temp_imag type=cyclic factor=NUM_WORKERS dim=2

    TDataIntern dataIn;
    for (INT_NFFT_TYPE row = 0; row < nb_row; ++row) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (INT_NFFT_TYPE col = 0; col < nb_col; ++col) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
            inputStream.read(dataIn);
            stage_real[col][row] = dataIn.real;
            stage_imag[col][row] = dataIn.imag;
        }
    }

    for (INT_NFFT_TYPE col = 0; col < MAX_NFFT_BAILEY; col++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
    #pragma HLS unroll factor=NUM_WORKERS
        FFT(stage_real[col], stage_imag[col], log2_r, temp_real[col], temp_imag[col]);
    }

    for (INT_NFFT_TYPE col = 0; col < MAX_NFFT_BAILEY; ++col) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (INT_NFFT_TYPE row = 0; row < MAX_NFFT_BAILEY; ++row) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        // #pragma HLS unroll factor=NUM_WORKERS
            FXP_TYPE real = temp_real[col][row];
			FXP_TYPE imag = temp_imag[col][row];

            INT_NFFT_TYPE twiddle_idx = col * row;
            FXP_TYPE wr = twiddle_real2[twiddle_idx];
            //INT_NFFT_TYPE twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;
            FXP_TYPE wi = twiddle_imag2[twiddle_idx];
            // float angle = -2.0 * M_PI * col * row / N;

			// Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
			FXP_TYPE tw_real = real * wr - imag * wi;
            FXP_TYPE tw_imag = real * wi + imag * wr;

            stage_real[row][col] = tw_real;
            stage_imag[row][col] = tw_imag;
        }
    }

    for (INT_NFFT_TYPE row = 0; row < MAX_NFFT_BAILEY; row++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
    #pragma HLS unroll factor=NUM_WORKERS
        FFT(stage_real[row], stage_imag[row], log2_c, temp_real[row], temp_imag[row]);     
    }

    TDataIntern dataOut;
    for (INT_NFFT_TYPE col = 0; col < nb_col; ++col) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (INT_NFFT_TYPE row = 0; row < nb_row; ++row) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
            dataOut.real = temp_real[row][col];
            dataOut.imag = temp_imag[row][col];
            outputStream.write(dataOut);
        }
    }
}

void ReadInputs(INT_NSTAGE_TYPE log2_nfft,
                float *In_real, float *In_imag, 
				hls::stream<TDataIntern>& stream)
{
	#pragma HLS INLINE off

    INT_NFFT_TYPE nfft = 1 << log2_nfft;
    TDataIntern data;

    float temp_real[MAX_NFFT];
    float temp_imag[MAX_NFFT];

    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        temp_real[j] = In_real[j];
        temp_imag[j] = In_imag[j];
    }

    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        data.real = Float2Fxp(temp_real[j]);
        data.imag = Float2Fxp(temp_imag[j]);
        stream.write(data);
    }        
}

void WriteOutputs(INT_NSTAGE_TYPE log2_nfft, float *Out_real, float *Out_imag, hls::stream<TDataIntern>& stream)
{
    #pragma HLS inline off

    TDataIntern dataOut;
    INT_NFFT_TYPE nfft = 1 << log2_nfft;
    float temp_real[MAX_NFFT];
    float temp_imag[MAX_NFFT];

    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; ++j) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        dataOut = stream.read();
        temp_real[j] = Fxp2Float(dataOut.real)*nfft;
        temp_imag[j] = Fxp2Float(dataOut.imag)*nfft;
    }
    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; ++j) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        Out_real[j] = temp_real[j];
        Out_imag[j] = temp_imag[j];
    }
}

void fft_hw(float *In_real, float *In_imag, int log2_nfft, float *Out_real, float *Out_imag) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_real offset=slave bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_imag offset=slave bundle=gmem_imag
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_real offset=slave bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_imag offset=slave bundle=gmem_imag

	hls_thread_local hls::stream<TDataIntern> input_stream;
    #pragma HLS STREAM variable=input_stream depth=MAX_NFFT
	hls_thread_local hls::stream<TDataIntern> output_stream;
    #pragma HLS STREAM variable=output_stream depth=MAX_NFFT

    #pragma HLS dataflow

	// setbuf(stdout, NULL); // For debugging purpose

    ReadInputs(log2_nfft, In_real, In_imag, input_stream);

    ComputeBaileyFFT(log2_nfft, input_stream, output_stream);

    WriteOutputs(log2_nfft, Out_real, Out_imag, output_stream);
}
