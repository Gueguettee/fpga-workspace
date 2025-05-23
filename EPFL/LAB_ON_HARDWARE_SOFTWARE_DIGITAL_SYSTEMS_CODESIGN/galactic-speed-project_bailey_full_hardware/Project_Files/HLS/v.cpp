#include "fft.h"

inline FXP_TYPE Float2Fxp(float value, uint32_t decimalBits = FXP_TYPE_WIDTH-FXP_TYPE_INT_WIDTH)
{
  //return value;
  int32_t scaled = (int32_t)roundf(value * ((uint64_t)1 << decimalBits));
    
  // Clamp to int16_t range
  if (scaled > INT32_MAX) scaled = INT32_MAX;
  if (scaled < INT32_MIN) scaled = INT32_MIN;

  return (int32_t)scaled;
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

void ComputeFFT(hls::stream<TDataConfig> & config_streams, hls::stream<TDataIn> & inputStream, hls::stream<TDataOut> & outputStream)
{
    #pragma HLS inline off

    ap_uint<1> stageFlipFlop = 0;

    FXP_TYPE Stage_real[2][MAX_NFFT_BAILEY];
    #pragma HLS bind_storage variable=Stage_real type=ram_t2p impl=bram
    #pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=2
	FXP_TYPE Stage_imag[2][MAX_NFFT_BAILEY];
    #pragma HLS bind_storage variable=Stage_imag type=ram_t2p impl=bram
    #pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=1
	//#pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=2

    TDataIn dataIn;
    TDataOut dataOut;

    TDataConfig config = config_streams.read();

    INT_NSTAGE_TYPE nstages = config.log2_nfft;
    INT_NFFT_TYPE nfft = config.nfft;

    for (INT_NFFT_TYPE i = 0; i < MAX_NFFT_BAILEY; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
    #pragma HLS pipeline II=1
        if (i >= nfft) break;
    	dataIn = inputStream.read();
        Stage_real[1][i] = dataIn.real;
        Stage_imag[1][i] = dataIn.imag;
    }

    bit_reverse(Stage_real[1], Stage_imag[1], nfft, nstages, Stage_real[0], Stage_imag[0]);

    for (INT_NSTAGE_TYPE stage = 1; stage <= nstages; stage++) { // Do M-1 stages of butterflies
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES_BAILEY max=MAX_NSTAGES_BAILEY
        fft_stage(stage, Stage_real[stageFlipFlop], Stage_imag[stageFlipFlop], nfft, Stage_real[(stageFlipFlop^1)], Stage_imag[(stageFlipFlop^1)]);
        stageFlipFlop++;
    }

    for (INT_NFFT_TYPE i = 0; i < MAX_NFFT_BAILEY; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
    #pragma HLS pipeline II=1
        if (i >= nfft) break;
        dataOut.real = Stage_real[stageFlipFlop][i];
        dataOut.imag = Stage_imag[stageFlipFlop][i];
        outputStream.write(dataOut);
    }
}

void ReadInputsFFT(INT_NSTAGE_TYPE log2_nfft, INT_NWORKERS_TYPE numHW,
                FXP_TYPE *In_real,
                FXP_TYPE *In_imag,
                hls::stream<TDataIn> streams[NUM_WORKERS],
                hls::stream<TDataConfig> config_streams[NUM_WORKERS])
{
	#pragma HLS INLINE off

    INT_NFFT_TYPE nfft = 1 << log2_nfft;
    INT_NFFT_WORKERS_TYPE ii = 0;
    TDataIn data;
    TDataConfig config;
    config.log2_nfft = log2_nfft;
    config.nfft = nfft;

    //printf("%d\n", In_real[0]);

    for (INT_NWORKERS_TYPE i = 0; i < numHW; i++) {
    #pragma HLS LOOP_TRIPCOUNT min=NUM_WORKERS max=NUM_WORKERS
        config_streams[i].write(config);

        for (INT_NFFT_TYPE j = 0; j < MAX_NFFT_BAILEY; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
            if (j >= nfft) break;
            data.real = In_real[ii + j];
            data.imag = In_imag[ii + j];
            streams[i].write(data);
        }        
        ii += nfft;
    }
}

void WriteOutputsFFT(INT_NSTAGE_TYPE numHW, INT_NSTAGE_TYPE log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag, hls::stream<TDataOut> streams[NUM_WORKERS])
{
    #pragma HLS inline off

    TDataOut dataOut;
    INT_NFFT_TYPE nfft = 1 << log2_nfft;
    INT_NFFT_WORKERS_TYPE index = 0;

    for(INT_NWORKERS_TYPE ii = 0; ii < numHW; ii++) {
    #pragma HLS LOOP_TRIPCOUNT min=NUM_WORKERS max=NUM_WORKERS
        for (INT_NFFT_TYPE j = 0; j < MAX_NFFT_BAILEY; j++) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
		#pragma HLS pipeline II=1
            if (j >= nfft) break;
            dataOut = streams[ii].read();
            Out_real[index + j] = dataOut.real;
            Out_imag[index + j] = dataOut.imag;
        }
        index += nfft;
    }
}

void FFT(FXP_TYPE *In_real, FXP_TYPE *In_imag, INT_NSTAGE_TYPE log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag, INT_NWORKERS_TYPE numHW) {
	hls_thread_local hls::stream<TDataIn> input_streams[NUM_WORKERS];
    #pragma HLS STREAM variable=input_streams depth=MAX_NFFT_BAILEY
	hls_thread_local hls::stream<TDataOut> output_streams[NUM_WORKERS];
    #pragma HLS STREAM variable=output_streams depth=MAX_NFFT_BAILEY

	hls_thread_local hls::stream<TDataConfig> config_streams[NUM_WORKERS];
	#pragma HLS STREAM variable=output_streams depth=1

    // hls_thread_local hls::task workers[NUM_WORKERS];

    #pragma HLS dataflow

	// setbuf(stdout, NULL); // For debugging purpose

    ReadInputsFFT(log2_nfft, numHW, In_real, In_imag, input_streams, config_streams);

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

    WriteOutputsFFT(numHW, log2_nfft, Out_real, Out_imag, output_streams);
}

void ComputeBaileyFFT(INT_NSTAGE_TYPE log2_nfft, hls::stream<TDataIn> & inputStream, hls::stream<TDataOut> & outputStream) {

    #pragma HLS inline off

    INT_NFFT_TYPE N = 1 << log2_nfft;
    INT_NSTAGE_TYPE log2_r = log2_nfft / 2;
    INT_NSTAGE_TYPE log2_c = log2_nfft - log2_r;
    INT_NFFT_TYPE nb_row = 1 << log2_r;
    INT_NFFT_TYPE nb_col = 1 << log2_c;

    FXP_TYPE stage_real[MAX_NFFT];
    #pragma HLS array_partition variable=stage_real type=cyclic factor=2 dim=0
    FXP_TYPE stage_imag[MAX_NFFT];
    #pragma HLS array_partition variable=stage_imag type=cyclic factor=2 dim=0
    FXP_TYPE temp_real[MAX_NFFT];
    #pragma HLS array_partition variable=temp_real type=cyclic factor=2 dim=0
    FXP_TYPE temp_imag[MAX_NFFT];
    #pragma HLS array_partition variable=temp_imag type=cyclic factor=2 dim=0

    TDataIn dataIn;
    for (int row = 0; row < nb_row; ++row) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (int col = 0; col < nb_col; ++col) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
            int col_index = IDX_COL_MAJOR(row, col, nb_row);
            inputStream.read(dataIn);
            stage_real[col_index] = dataIn.real;
            stage_imag[col_index] = dataIn.imag;
        }
    }

    for (INT_NFFT_TYPE col = 0; col < nb_col; col += NUM_WORKERS) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        INT_NWORKERS_TYPE workers = NUM_WORKERS;
        if (workers + col > nb_col){
            workers = nb_col - col;
        }

        INT_NFFT_TYPE col_index = col * nb_row;
        FFT(&stage_real[col_index], &stage_imag[col_index], log2_r, &temp_real[col_index], &temp_imag[col_index], workers);       
    }

    for (INT_NFFT_TYPE col = 0; col < nb_col; ++col) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (INT_NFFT_TYPE row = 0; row < nb_row; ++row) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
        	INT_NFFT_TYPE row_index = IDX_ROW_MAJOR(row, col, nb_col);
        	INT_NFFT_TYPE col_index = IDX_COL_MAJOR(row, col, nb_row);

            FXP_TYPE real = temp_real[col_index];
			FXP_TYPE imag = temp_imag[col_index];

            INT_NFFT_TYPE twiddle_idx = col * row;
            FXP_TYPE wr = twiddle_real2[twiddle_idx];
            //INT_NFFT_TYPE twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;
            FXP_TYPE wi = twiddle_imag2[twiddle_idx];
            // float angle = -2.0 * M_PI * col * row / N;

			// Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
			FXP_TYPE tw_real = real * wr - imag * wi;
            FXP_TYPE tw_imag = real * wi + imag * wr;

            stage_real[row_index] = tw_real;
            stage_imag[row_index] = tw_imag;
        }
    }

    for (INT_NFFT_TYPE row = 0; row < nb_row; row += NUM_WORKERS) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        INT_NWORKERS_TYPE workers = NUM_WORKERS;
        if (workers + row > nb_row){
            workers = nb_row - row;
        }

        INT_NFFT_TYPE row_index = row * nb_col;
        FFT(&stage_real[row_index], &stage_imag[row_index], log2_c, &temp_real[row_index], &temp_imag[row_index], workers);     
    }

    TDataOut dataOut;
    for (int col = 0; col < nb_col; ++col) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        for (int row = 0; row < nb_row; ++row) {
        #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
        #pragma HLS pipeline II=1
            int row_index = IDX_ROW_MAJOR(row, col, nb_col);
            dataOut.real = temp_real[row_index];
            dataOut.imag = temp_imag[row_index];
            outputStream.write(dataOut);
        }
    }
}

void ReadInputs(INT_NSTAGE_TYPE log2_nfft,
                FXP_TYPE *In_real,
                FXP_TYPE *In_imag,
				hls::stream<TDataIn>& stream)
{
	#pragma HLS INLINE off

    INT_NFFT_TYPE nfft = 1 << log2_nfft;
    TDataIn data;

    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        if (j >= nfft) break;
        data.real = In_real[j];
        data.imag = In_imag[j];
        stream.write(data);
    }        
}

void WriteOutputs(INT_NSTAGE_TYPE log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag, hls::stream<TDataOut>& stream)
{
    #pragma HLS inline off

    TDataOut dataOut;
    INT_NFFT_TYPE nfft = 1 << log2_nfft;

    for (INT_NFFT_TYPE j = 0; j < MAX_NFFT; j++) {
    #pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
    #pragma HLS pipeline II=1
        if (j >= nfft) break;
        dataOut = stream.read();
        Out_real[j] = dataOut.real;
        Out_imag[j] = dataOut.imag;
    }
}

void fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, INT_NSTAGE_TYPE log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=In_real offset=slave max_read_burst_length=256 num_read_outstanding=4 max_write_burst_length=256 num_write_outstanding=4 bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=In_imag offset=slave max_read_burst_length=256 num_read_outstanding=4 max_write_burst_length=256 num_write_outstanding=4 bundle=gmem_imag
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=Out_real offset=slave max_write_burst_length=256 num_write_outstanding=4 max_read_burst_length=256 num_read_outstanding=4 bundle=gmem_real
#pragma HLS INTERFACE m_axi depth=MAX_NFFT*NUM_WORKERS port=Out_imag offset=slave max_write_burst_length=256 num_write_outstanding=4 max_read_burst_length=256 num_read_outstanding=4 bundle=gmem_imag

	hls_thread_local hls::stream<TDataIn> input_stream;
    #pragma HLS STREAM variable=input_stream depth=MAX_NFFT
	hls_thread_local hls::stream<TDataOut> output_stream;
    #pragma HLS STREAM variable=output_stream depth=MAX_NFFT

    #pragma HLS dataflow

	// setbuf(stdout, NULL); // For debugging purpose

    ReadInputs(log2_nfft, In_real, In_imag, input_stream);

    ComputeBaileyFFT(log2_nfft, input_stream, output_stream);

    WriteOutputs(log2_nfft, Out_real, Out_imag, output_stream);
}
