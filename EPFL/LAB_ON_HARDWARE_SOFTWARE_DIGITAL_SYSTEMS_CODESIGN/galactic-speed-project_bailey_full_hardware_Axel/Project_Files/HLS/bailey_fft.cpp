#include "bailey_fft.h"

#define MAX_NSTAGES 10 // we use 10 bit variable everywhere for simplicity (not much ressources to get from having some 8 bit variables..)
#define MAX_NFFT (1 << MAX_NSTAGES) // the maximum number of FFT points
#define MAX_NSTAGES_BAILEY 5
#define MAX_NFFT_BAILEY (1 << MAX_NSTAGES_BAILEY)
#define MAX_TWIDDLES (MAX_NFFT_BAILEY / 2)
#define OFFSET_IMAG (MAX_TWIDDLES / 2)

// Helper: index in row-major order
#define IDX_ROW_MAJOR(row, col, ncols) ((row) * (ncols) + (col))

// Helper: index in col-major order
#define IDX_COL_MAJOR(row, col, nrows) ((col) * (nrows) + (row))

namespace bailey_hw
{
	uint10_t reverse_bits(uint10_t input)
	{
//#pragma HLS INLINE

		uint10_t reversed = input.reverse();

		// Return only the 'num_stages' least significant bits of the reversed value
		return reversed.range(9, 10 - MAX_NSTAGES_BAILEY);
	}

	void bit_reverse(FXP_TYPE *X_real, FXP_TYPE *X_imag, FXP_TYPE *OUT_real, FXP_TYPE *OUT_imag)
	{
//#pragma HLS INLINE
		for (uint10_t i = 0; i < MAX_NFFT_BAILEY; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
			uint10_t reversed = reverse_bits(i);
			OUT_real[reversed] = X_real[i];
			OUT_imag[reversed] = X_imag[i];
		}
	}

	void fft_stage(uint10_t stage, FXP_TYPE *X_real, FXP_TYPE *X_imag, FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
	{
//#pragma HLS INLINE
		uint10_t DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
		uint10_t numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
		FXP_TYPE temp_Out_real[MAX_NFFT_BAILEY];   // TODO could be optimized
		FXP_TYPE temp_Out_imag[MAX_NFFT_BAILEY];   // TODO could be optimized
		// Perform butterflies for j-th stage
		for (uint10_t j = 0; j < 1<<(MAX_NSTAGES_BAILEY-1); j++)
		{
#pragma HLS LOOP_TRIPCOUNT min=(1<<(MAX_NSTAGES_BAILEY-1)) max=(1<<(MAX_NSTAGES-1))
			if (j >= numBF) break;
			// Can be computed once as a look-up table (for the last stage)
			uint10_t twiddle_idx = j << (MAX_NSTAGES_BAILEY-stage);
			FXP_TYPE c = twiddle_real[twiddle_idx];
			uint10_t twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;

			if (twiddle_idx_imag >= MAX_TWIDDLES)
				twiddle_idx_imag -= MAX_TWIDDLES;

			FXP_TYPE s = twiddle_real[twiddle_idx_imag];

			if (s > 0)
				s = -s;
			// Compute butterflies that use same W**k
			for (uint10_t i = j; i < MAX_NFFT_BAILEY; i += DFTpts)
			{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT_BAILEY max=MAX_NFFT_BAILEY
				uint10_t i_lower = i + numBF; // index of lower point in butterfly
				FXP_TYPE temp_real = c * X_real[i_lower] - s * X_imag[i_lower];
				FXP_TYPE temp_imag = c * X_imag[i_lower] + s * X_real[i_lower];
				Out_real[i_lower] = (X_real[i] - temp_real) >> 1;
				Out_imag[i_lower] = (X_imag[i] - temp_imag) >> 1;
				Out_real[i] = (X_real[i] + temp_real) >> 1;
				Out_imag[i] = (X_imag[i] + temp_imag) >> 1;
			}
		}
	}

	void fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
	{
//#pragma HLS INLINE

		FXP_TYPE Stage_real[2][MAX_NFFT_BAILEY];
		//#pragma HLS bind_storage variable=Stage_real type=ram_t2p
#pragma HLS array_partition variable=Stage_real type=cyclic factor=2 dim=1
		//#pragma HLS array_partition variable=Stage_real type=cyclic factor=4 dim=2
		FXP_TYPE Stage_imag[2][MAX_NFFT_BAILEY];
		//#pragma HLS bind_storage variable=Stage_imag type=ram_t2p
#pragma HLS array_partition variable=Stage_imag type=cyclic factor=2 dim=1
		//#pragma HLS array_partition variable=Stage_imag type=cyclic factor=4 dim=2

		ap_uint<1> stageFlipFlop = 0;

		FXP_TYPE temp_In_real[MAX_NFFT_BAILEY];
		FXP_TYPE temp_In_imag[MAX_NFFT_BAILEY];

		FXP_TYPE temp_Out_real[MAX_NFFT_BAILEY];
		FXP_TYPE temp_Out_imag[MAX_NFFT_BAILEY];

		bit_reverse(In_real, In_imag, Stage_real[0], Stage_imag[0]);

		for (uint10_t stage = 1; stage < MAX_NSTAGES_BAILEY; stage++) // Do M-1 stages of butterflies
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
			fft_stage(stage, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], Stage_real[(int)(stageFlipFlop^1)], Stage_imag[(int)(stageFlipFlop^1)]);
			stageFlipFlop++;
		}
		fft_stage(MAX_NSTAGES_BAILEY, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], Out_real, Out_imag);
	}

	void bailey_fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
	{
#pragma HLS INTERFACE s_axilite port=return
#pragma HLS INTERFACE s_axilite port=log2_nfft
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=In_imag offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_real offset=slave
#pragma HLS INTERFACE m_axi depth=MAX_NFFT port=Out_imag offset=slave

		// setbuf(stdout, NULL); // For debugging purpose
		FXP_TYPE stage_real[MAX_NFFT];
		FXP_TYPE stage_imag[MAX_NFFT];
		FXP_TYPE temp_real[MAX_NFFT];
		FXP_TYPE temp_imag[MAX_NFFT];

		// Load in row major
		for (int i = 0; i < MAX_NFFT; i++)
		{
			temp_real[i] = In_real[i];
		}

		for (int i = 0; i < MAX_NFFT; i++)
		{
			temp_imag[i] = In_imag[i];
		}

		// Step 1: Arrange input into nb_row x nb_col matrix col-wise
		for (uint10_t row = 0; row < MAX_NFFT_BAILEY; ++row)
		{
			for (uint10_t col = 0; col < MAX_NFFT_BAILEY; ++col)
			{
				uint10_t row_index = IDX_ROW_MAJOR(row, col, MAX_NFFT_BAILEY);
				uint10_t col_index = IDX_COL_MAJOR(row, col, MAX_NFFT_BAILEY);
				stage_real[col_index] = temp_real[row_index];
				stage_imag[col_index] = temp_imag[row_index];
			}
		}

		// Step 2: FFTs on each column (each of length nb_row)
		for (uint10_t col = 0; col < MAX_NFFT_BAILEY; ++col)
		{
			uint10_t col_index = col * MAX_NFFT_BAILEY;
			FXP_TYPE *in_real_ptr = &stage_real[col_index];
			FXP_TYPE *in_imag_ptr = &stage_imag[col_index];

			FXP_TYPE *out_real_ptr = &temp_real[col_index];
			FXP_TYPE *out_imag_ptr = &temp_imag[col_index];

			fft_hw(in_real_ptr, in_imag_ptr, out_real_ptr, out_imag_ptr);

			// Step 3: Twiddle multiplication for each row (index k)
			for (uint10_t row = 0; row < MAX_NFFT_BAILEY; ++row)
			{
				uint10_t index = IDX_COL_MAJOR(row, col, MAX_NFFT_BAILEY);
				FXP_TYPE real = temp_real[index];
				FXP_TYPE imag = temp_imag[index];

				uint10_t twiddle_idx = col * row;
				FXP_TYPE wr = twiddle_real2[twiddle_idx];
				FXP_TYPE wi = twiddle_imag2[twiddle_idx];

				// Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
				FXP_TYPE tw_real = real * wr - imag * wi;
				FXP_TYPE tw_imag = real * wi + imag * wr;

				temp_real[index] = tw_real;
				temp_imag[index] = tw_imag;
			}
		}

		// Step 4: FFTs on each row
		// Convert to row major
		for (uint10_t row = 0; row < MAX_NFFT_BAILEY; ++row)
		{
			for (uint10_t col = 0; col < MAX_NFFT_BAILEY; ++col)
			{
				uint10_t row_index = IDX_ROW_MAJOR(row, col, MAX_NFFT_BAILEY);
				uint10_t col_index = IDX_COL_MAJOR(row, col, MAX_NFFT_BAILEY);
				stage_real[row_index] = temp_real[col_index];
				stage_imag[row_index] = temp_imag[col_index];
			}
		}

		// Perform FFTs on rows
		for (uint10_t row = 0; row < MAX_NFFT_BAILEY; ++row)
		{
			uint10_t row_index = row * MAX_NFFT_BAILEY;
			FXP_TYPE *in_real_ptr = &stage_real[row_index];
			FXP_TYPE *in_imag_ptr = &stage_imag[row_index];

			FXP_TYPE *out_real_ptr = &temp_real[row_index];
			FXP_TYPE *out_imag_ptr = &temp_imag[row_index];

			fft_hw(in_real_ptr, in_imag_ptr, out_real_ptr, out_imag_ptr);
		}

		// Step 5: Write result back in transposed (col-major) order
		for (uint10_t row = 0; row < MAX_NFFT_BAILEY; ++row)
		{
			for (uint10_t col = 0; col < MAX_NFFT_BAILEY; ++col)
			{
				uint10_t row_index = IDX_ROW_MAJOR(row, col, MAX_NFFT_BAILEY);
				uint10_t col_index = IDX_COL_MAJOR(row, col, MAX_NFFT_BAILEY);
				Out_real[col_index] = temp_real[row_index];
				Out_imag[col_index] = temp_imag[row_index];
			}
		}
	}
}
