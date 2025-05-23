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

void ComputeFFT(hls::stream<TDataConfig> & config_streams, hls::stream<TDataIn> & inputStream, hls::stream<TDataOut> & outputStream)
{
    #pragma HLS inline off

    ap_uint<1> stageFlipFlop = 0;

    FXP_TYPE Stage_real[2][MAX_NFFT];
    //#pragma HLS bind_storage variable=Stage_real type=ram_t2p
    #pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=2
	FXP_TYPE Stage_imag[2][MAX_NFFT];
    //#pragma HLS bind_storage variable=Stage_imag type=ram_t2p
    #pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=2

    TDataIn dataIn;
    TDataOut dataOut;

    TDataConfig config = config_streams.read();

    int nstages = config.log2_nfft;
    int nfft = config.nfft;

    for (int i = 0; i < MAX_NFFT; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        if (i >= nfft) break;
    	dataIn = inputStream.read();
        Stage_real[1][i] = dataIn.real;
        Stage_imag[1][i] = dataIn.imag;
    }

    bit_reverse(Stage_real[1], Stage_imag[1], nfft, nstages, Stage_real[0], Stage_imag[0]);

    for (int stage = 1; stage <= nstages; stage++) { // Do M-1 stages of butterflies
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
        fft_stage(stage, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], nfft, Stage_real[(int)(stageFlipFlop^1)], Stage_imag[(int)(stageFlipFlop^1)]);
        stageFlipFlop++;
    }

    for (int i = 0; i < nfft; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        if (i >= nfft) break;
        dataOut.real = Stage_real[(int)(stageFlipFlop)][i];
        dataOut.imag = Stage_imag[(int)(stageFlipFlop)][i];
        outputStream.write(dataOut);
    }
}

void ReadInputs(int log2_nfft, int numHW,
                FXP_TYPE *In_real,
                FXP_TYPE *In_imag,
                hls::stream<TDataIn> streams[NUM_WORKERS],
                hls::stream<TDataConfig> config_streams[NUM_WORKERS])
{
	#pragma HLS INLINE off

    int nfft = 1 << log2_nfft;
    int ii = 0;
    FXP_TYPE temp_In_imag[MAX_NFFT];
    TDataIn data;
    TDataConfig config;

    for (int i = 0; i < numHW; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=NUM_WORKERS max=NUM_WORKERS

        config.log2_nfft = log2_nfft;
        config.nfft = nfft;

        config_streams[i].write(config);

        for (int j = 0; j < MAX_NFFT; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        #pragma HLS pipeline II=1
            if (j >= nfft) break;
            temp_In_imag[j] = In_imag[ii + j];
        }

        for (int j = 0; j < MAX_NFFT; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
        #pragma HLS pipeline II=1
            if (j >= nfft) break;
            data.real = In_real[ii + j];
            data.imag = temp_In_imag[j];
            streams[i].write(data);
        }        
        ii += nfft;
    }
}

void WriteOutputs(int numHW, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag, hls::stream<TDataOut> streams[NUM_WORKERS])
{
    #pragma HLS inline off

    FXP_TYPE temp_Out_imag[MAX_NFFT];
    TDataOut dataOut;
    int nfft = 1 << log2_nfft;
    int index = 0;

    for(int ii = 0; ii < numHW; ii++) {
    #pragma HLS LOOP_TRIPCOUNT min=NUM_WORKERS max=NUM_WORKERS

        for (int j = 0; j < MAX_NFFT; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
		#pragma HLS pipeline II=1
            if (j >= nfft) break;
            dataOut = streams[ii].read();
            Out_real[index + j] = dataOut.real;
            temp_Out_imag[j] = dataOut.imag;
        }
        for (int j = 0; j < MAX_NFFT; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
		#pragma HLS pipeline II=1
            if (j >= nfft) break;
            Out_imag[index + j] = temp_Out_imag[j];
        }
        index += nfft;
    }
}

void fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag, int numHW) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE s_axilite port=numHW
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=In_real offset=slave max_read_burst_length=256 num_read_outstanding=4 max_write_burst_length=256 num_write_outstanding=4 //bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=In_imag offset=slave max_read_burst_length=256 num_read_outstanding=4 max_write_burst_length=256 num_write_outstanding=4 //bundle=gmem_imag
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=Out_real offset=slave max_write_burst_length=256 num_write_outstanding=4 max_read_burst_length=256 num_read_outstanding=4 //bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=Out_imag offset=slave max_write_burst_length=256 num_write_outstanding=4 max_read_burst_length=256 num_read_outstanding=4 //bundle=gmem_imag

	hls_thread_local hls::stream<TDataIn> input_streams[NUM_WORKERS];
    #pragma HLS STREAM variable=input_streams depth=MAX_NFFT
	hls_thread_local hls::stream<TDataOut> output_streams[NUM_WORKERS];
    #pragma HLS STREAM variable=output_streams depth=MAX_NFFT

	hls_thread_local hls::stream<TDataConfig> config_streams[NUM_WORKERS];
	#pragma HLS STREAM variable=output_streams depth=1

    // hls_thread_local hls::task workers[NUM_WORKERS];

    #pragma HLS dataflow

	// setbuf(stdout, NULL); // For debugging purpose

    ReadInputs(log2_nfft, numHW, In_real, In_imag, input_streams, config_streams);

    // workers_gen: for (int ii = 0; ii < NUM_WORKERS; ii++) {
    // #pragma HLS unroll
   	//      workers[ii](ComputeFFT, config_streams[ii], input_streams[ii], output_streams[ii]);
    // }

    hls_thread_local hls::task worker0(ComputeFFT, config_streams[0], input_streams[0], output_streams[0]);
#ifdef NUM_WORKERS_2
    hls_thread_local hls::task worker1(ComputeFFT, config_streams[1], input_streams[1], output_streams[1]);
#endif
#ifdef NUM_WORKERS_4
    hls_thread_local hls::task worker2(ComputeFFT, config_streams[2], input_streams[2], output_streams[2]);
    hls_thread_local hls::task worker3(ComputeFFT, config_streams[3], input_streams[3], output_streams[3]);
#endif
#ifdef NUM_WORKERS_8
    hls_thread_local hls::task worker4(ComputeFFT, config_streams[4], input_streams[4], output_streams[4]);
    hls_thread_local hls::task worker5(ComputeFFT, config_streams[5], input_streams[5], output_streams[5]);
    hls_thread_local hls::task worker6(ComputeFFT, config_streams[6], input_streams[6], output_streams[6]);
    hls_thread_local hls::task worker7(ComputeFFT, config_streams[7], input_streams[7], output_streams[7]);
#endif
#ifdef NUM_WORKERS_16
    hls_thread_local hls::task worker8(ComputeFFT, config_streams[8], input_streams[8], output_streams[8]);
    hls_thread_local hls::task worker9(ComputeFFT, config_streams[9], input_streams[9], output_streams[9]);
    hls_thread_local hls::task worker10(ComputeFFT, config_streams[10], input_streams[10], output_streams[10]);
    hls_thread_local hls::task worker11(ComputeFFT, config_streams[11], input_streams[11], output_streams[11]);
    hls_thread_local hls::task worker12(ComputeFFT, config_streams[12], input_streams[12], output_streams[12]);
    hls_thread_local hls::task worker13(ComputeFFT, config_streams[13], input_streams[13], output_streams[13]);
    hls_thread_local hls::task worker14(ComputeFFT, config_streams[14], input_streams[14], output_streams[14]);
    hls_thread_local hls::task worker15(ComputeFFT, config_streams[15], input_streams[15], output_streams[15]);
#endif

    WriteOutputs(numHW, log2_nfft, Out_real, Out_imag, output_streams);
}
