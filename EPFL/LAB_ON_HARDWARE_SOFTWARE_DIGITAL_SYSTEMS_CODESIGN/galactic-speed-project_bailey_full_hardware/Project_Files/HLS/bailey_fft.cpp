#include "bailey_fft.h"

#define MAX_LOG2_BAILEY 10
#define MAX_NFFT_BAILEY (1 << MAX_LOG2_BAILEY)
#define MAX_NSTAGES 10 // the maximum number of stages (MAX_SW_STAGE/2) rounded at top (for us MAX_SW_STAGE is 16)
#define MAX_NFFT (1 << MAX_NSTAGES) // the maximum number of FFT points
#define MAX_TWIDDLES (MAX_NFFT / 2)
#define OFFSET_IMAG (MAX_TWIDDLES / 2)

// Helper: index in row-major order
#define IDX_ROW_MAJOR(row, col, ncols) ((row) * (ncols) + (col))

// Helper: index in col-major order
#define IDX_COL_MAJOR(row, col, nrows) ((col) * (nrows) + (row))

namespace bailey_hw
{
	ap_uint<MAX_NSTAGES> reverse_bits(ap_uint<MAX_NSTAGES> input, ap_uint<MAX_NSTAGES> num_stages)
	{
#pragma HLS INLINE

		ap_uint<MAX_NSTAGES> reversed = input.reverse();

		// Return only the 'num_stages' least significant bits of the reversed value
		return reversed.range(MAX_NSTAGES - 1, MAX_NSTAGES - num_stages);
	}

	void bit_reverse(FXP_TYPE *X_real, FXP_TYPE *X_imag, ap_uint<MAX_NSTAGES> nfft, ap_uint<MAX_NSTAGES> num_stages,
					 FXP_TYPE *OUT_real, FXP_TYPE *OUT_imag)
	{
#pragma HLS INLINE
		for (ap_uint<MAX_NSTAGES> i = 0; i < MAX_NFFT; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
			if (i >= nfft) break;
			ap_uint<MAX_NSTAGES> reversed = reverse_bits(i, num_stages);
			OUT_real[reversed] = X_real[i];
			OUT_imag[reversed] = X_imag[i];
		}
	}

	void fft_stage(ap_uint<MAX_NSTAGES> stage, FXP_TYPE *X_real, FXP_TYPE *X_imag, ap_uint<MAX_NSTAGES> nfft,
				   FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
	{
#pragma HLS INLINE
		ap_uint<MAX_NSTAGES> DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
		ap_uint<MAX_NSTAGES> numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
		FXP_TYPE temp_Out_real[MAX_NFFT];   // TODO could be optimized
		FXP_TYPE temp_Out_imag[MAX_NFFT];   // TODO could be optimized

		// Perform butterflies for j-th stage
		for (ap_uint<MAX_NSTAGES> j = 0; j < 1<<(MAX_NSTAGES-1); j++)
		{
#pragma HLS LOOP_TRIPCOUNT min=(1<<(MAX_NSTAGES-1)) max=(1<<(MAX_NSTAGES-1))
			if (j >= numBF) break;
			// Can be computed once as a look-up table (for the last stage)
			ap_uint<MAX_NSTAGES> twiddle_idx = j << (MAX_NSTAGES-stage);
			FXP_TYPE c = twiddle_real[twiddle_idx];
			ap_uint<MAX_NSTAGES> twiddle_idx_imag = twiddle_idx+OFFSET_IMAG;

			if (twiddle_idx_imag >= MAX_TWIDDLES)
				twiddle_idx_imag -= MAX_TWIDDLES;

			FXP_TYPE s = twiddle_real[twiddle_idx_imag];

			if (s > 0)
				s = -s;
			// Compute butterflies that use same W**k
			for (ap_uint<MAX_NSTAGES> i = j; i < MAX_NFFT; i += DFTpts)
			{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
				if (i >= nfft) break;
				ap_uint<MAX_NSTAGES> i_lower = i + numBF; // index of lower point in butterfly
				FXP_TYPE temp_real = c * X_real[i_lower] - s * X_imag[i_lower];
				FXP_TYPE temp_imag = c * X_imag[i_lower] + s * X_real[i_lower];
				//printf("temp: %.2f \n", (float)temp_real);
				Out_real[i_lower] = (X_real[i] - temp_real) >> 1;
				Out_imag[i_lower] = (X_imag[i] - temp_imag) >> 1;
				temp_Out_real[i] = (X_real[i] + temp_real) >> 1;
				temp_Out_imag[i] = (X_imag[i] + temp_imag) >> 1;
			}

			for (ap_uint<MAX_NSTAGES> i = j; i < MAX_NFFT; i += DFTpts)
			{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
				if (i >= nfft) break;
				Out_real[i] = temp_Out_real[i];
				Out_imag[i] = temp_Out_imag[i];
			}
		}
	}

	void fft_hw(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
	{
#pragma HLS INLINE
		ap_uint<MAX_NSTAGES> nstages = log2_nfft;
		ap_uint<MAX_NSTAGES> nfft = (1 << nstages); // NFFT = 2^NStages

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

		for (ap_uint<MAX_NSTAGES> i = 0; i < MAX_NFFT; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
			if (i >= nfft) break;
			temp_In_real[i] = In_real[i];
		}
		for (ap_uint<MAX_NSTAGES> i = 0; i < MAX_NFFT; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
			if (i >= nfft) break;
			temp_In_imag[i] = In_imag[i];
		}

		bit_reverse(temp_In_real, temp_In_imag, nfft, nstages, Stage_real[0], Stage_imag[0]);

		for (ap_uint<MAX_NSTAGES> stage = 1; stage < nstages; stage++) // Do M-1 stages of butterflies
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NSTAGES max=MAX_NSTAGES
			fft_stage(stage, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], nfft, Stage_real[(int)(stageFlipFlop^1)], Stage_imag[(int)(stageFlipFlop^1)]);
			stageFlipFlop++;
		}
		fft_stage(nstages, Stage_real[(int)(stageFlipFlop)], Stage_imag[(int)(stageFlipFlop)], nfft, temp_Out_real, temp_Out_imag);

		for (ap_uint<MAX_NSTAGES> i = 0; i < MAX_NFFT; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
			if (i >= nfft) break;
			Out_real[i] = temp_Out_real[i];
		}
		for (ap_uint<MAX_NSTAGES> i = 0; i < MAX_NFFT; i++)
		{
#pragma HLS LOOP_TRIPCOUNT min=MAX_NFFT max=MAX_NFFT
			if (i >= nfft) break;
			Out_imag[i] = temp_Out_imag[i];
		}
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
		int N = 1 << log2_nfft;
		int log2_r = log2_nfft / 2;
		int log2_c = log2_nfft - log2_r;
		int nb_row = 1 << log2_r;
		int nb_col = 1 << log2_c;

		FXP_TYPE stage_real[MAX_NFFT_BAILEY];
		FXP_TYPE stage_imag[MAX_NFFT_BAILEY];
		FXP_TYPE temp_real[MAX_NFFT_BAILEY];
		FXP_TYPE temp_imag[MAX_NFFT_BAILEY];

		// Load in row major
		for (int row = 0; row < nb_row; ++row)
		{
			for (int col = 0; col < nb_col; ++col)
			{
				int index = IDX_ROW_MAJOR(row, col, nb_row);
				temp_real[index] = In_real[index];
				temp_imag[index] = In_imag[index];
			}
		}

		// Step 1: Arrange input into nb_row x nb_col matrix col-wise
		for (int row = 0; row < nb_row; ++row)
		{
			for (int col = 0; col < nb_col; ++col)
			{
				int row_index = IDX_ROW_MAJOR(row, col, nb_col);
				int col_index = IDX_COL_MAJOR(row, col, nb_row);
				stage_real[col_index] = temp_real[row_index];
				stage_imag[col_index] = temp_imag[row_index];
			}
		}

		// Step 2: FFTs on each column (each of length nb_row)
		for (int col = 0; col < nb_col; ++col)
		{
			int col_index = col * nb_row;
			FXP_TYPE *in_real_ptr = &stage_real[col_index];
			FXP_TYPE *in_imag_ptr = &stage_imag[col_index];

			FXP_TYPE *out_real_ptr = &temp_real[col_index];
			FXP_TYPE *out_imag_ptr = &temp_imag[col_index];

			fft_hw(in_real_ptr, in_imag_ptr, log2_r, out_real_ptr, out_imag_ptr);

			// Step 3: Twiddle multiplication for each row (index k)
			for (int row = 0; row < nb_row; ++row)
			{
				int index = IDX_COL_MAJOR(row, col, nb_row);
				FXP_TYPE real = temp_real[index];
				FXP_TYPE imag = temp_imag[index];

				// Compute W_N^{k * j} = e^(-2πi * row * col / N)
				double angle = -2.0 * M_PI * row * col / (double)(N);
				FXP_TYPE tw_real = cos(angle);
				FXP_TYPE tw_imag = sin(angle);

				// Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
				FXP_TYPE new_real = real * tw_real - imag * tw_imag;
				FXP_TYPE new_imag = real * tw_imag + imag * tw_real;

				temp_real[index] = new_real;
				temp_imag[index] = new_imag;
			}
		}

		// Step 4: FFTs on each row
		// Convert to row major
		for (int row = 0; row < nb_row; ++row)
		{
			for (int col = 0; col < nb_col; ++col)
			{
				int row_index = IDX_ROW_MAJOR(row, col, nb_col);
				int col_index = IDX_COL_MAJOR(row, col, nb_row);
				stage_real[row_index] = temp_real[col_index];
				stage_imag[row_index] = temp_imag[col_index];
			}
		}

		// Perform FFTs on rows
		for (int row = 0; row < nb_row; ++row)
		{
			int row_index = row * nb_col;
			FXP_TYPE *in_real_ptr = &stage_real[row_index];
			FXP_TYPE *in_imag_ptr = &stage_imag[row_index];

			FXP_TYPE *out_real_ptr = &temp_real[row_index];
			FXP_TYPE *out_imag_ptr = &temp_imag[row_index];

			fft_hw(in_real_ptr, in_imag_ptr, log2_c, out_real_ptr, out_imag_ptr);
		}

		// Step 5: Write result back in transposed (col-major) order
		for (int row = 0; row < nb_row; ++row)
		{
			for (int col = 0; col < nb_col; ++col)
			{
				int row_index = IDX_ROW_MAJOR(row, col, nb_col);
				int col_index = IDX_COL_MAJOR(row, col, nb_row);
				Out_real[col_index] = temp_real[row_index];
				Out_imag[col_index] = temp_imag[row_index];
			}
		}
	}
}
