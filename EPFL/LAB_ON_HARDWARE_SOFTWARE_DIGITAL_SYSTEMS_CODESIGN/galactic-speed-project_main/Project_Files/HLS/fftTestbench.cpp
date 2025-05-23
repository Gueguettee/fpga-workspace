#include <stdlib.h>
#include <inttypes.h>

#include "fft.h"
#include "utils.h"

//#define CSV_DATA

#define SW_MAX_NSTAGES 19
#define SW_MAX_NFFT (1 << SW_MAX_NSTAGES) // the maximum number of FFT points

#define NUM_SEGMENTS 512 //Only used for the old FFT segments

typedef std::complex<float> Complex;
typedef float FFT_TYPE;

void save_fft_output(const Complex* data, int nfft, const char* filename) {
    std::ofstream file(filename);
    for (int i = 0; i < nfft; ++i) {
        float magnitude = std::abs(data[i]);
        file << i << "," << magnitude << "\n";
    }
    file.close();
}

void save_fft_output_from_real_imag(const FFT_TYPE* real, const FFT_TYPE* imag, int nfft, const char* filename) {
    std::ofstream file(filename);
    for (int i = 0; i < nfft; ++i) {
        float magnitude = std::sqrt(real[i]*real[i] + imag[i]*imag[i]);
        file << i << "," << magnitude << "\n";
    }
    file.close();
}

// --------------------------------------------------------------------------

unsigned int reverse_bits_SW(unsigned int input, int num_stages) {
	int i, rev = 0;
	for (i = 0; i < num_stages; i++) {
		rev = (rev << 1) | (input & 1);
		input = input >> 1;
	}
	return rev;
}

void bit_reverse_SW(Complex* X, int nfft, int num_stages, Complex* OUT) {
    int reversed;
    Complex temp;
  
    for (int i = 0; i < nfft; i++) {
	    reversed = reverse_bits_SW(i, num_stages); // Find the bit reversed index
		if (i <= reversed) {
			// Swap the real values
			temp = X[i];
			OUT[i] = X[reversed];
			OUT[reversed] = temp;
		}
	}
}

void fft_stage_SW(int stage, Complex* X, int nfft, Complex* Out) {
    int DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
    int numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
    float e = -2 * M_PI / DFTpts;
    float a = 0.0;
    // Perform butterflies for j-th stage
    for (int j = 0; j < numBF; j++) {
        // Can be computed once as a look-up table (for the last stage)
        float c = cos(a);//TODO
        float s = sin(a);//TODO
        Complex twiddle = Complex(c, s);
        a = a + e;
        // Compute butterflies that use same W**k
        for (int i = j; i < nfft; i += DFTpts) {
            int i_lower = i + numBF; // index of lower point in butterfly
            Complex temp = X[i_lower] * twiddle;
            Out[i_lower] = X[i] - temp;
            Out[i] = X[i] + temp;
        }
    }
}

Complex Stage[SW_MAX_NSTAGES][SW_MAX_NFFT];
void fft(Complex* In, int log2_nfft, Complex* Out) {
    
    int nstages = log2_nfft;
    int nfft = 1 << nstages; // NFFT = 2^NStages 

    bit_reverse_SW(In, nfft, nstages, Stage[0]);
    for (int stage = 1; stage < nstages; stage++) { // Do M-1 stages of butterflies
        fft_stage_SW(stage, Stage[stage-1], nfft, Stage[stage]);
    }
    fft_stage_SW(nstages, Stage[nstages-1], nfft, Out);
}

// ----------------------------------- Bailey's FFT -----------------------------------------

// Helper: index in row-major order
#define IDX_ROW_MAJOR(row, col, ncols) ((row) * (ncols) + (col))

// Helper: index in col-major order
#define IDX_COL_MAJOR(row, col, nrows) ((col) * (nrows) + (row))

void bailey_fft(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft,
                FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
{
    int N = 1 << log2_nfft;
    int log2_r = log2_nfft / 2;
    int log2_c = log2_nfft - log2_r;
    int nb_row = 1 << log2_r;
    int nb_col = 1 << log2_c;


    FXP_TYPE *stage_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *stage_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *temp_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *temp_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));

    // Step 1: Arrange input into nb_row x nb_col matrix col-wise
    for (int i = 0; i < N; ++i)
    {
        int row = i / nb_col;  // nb_row rows
        int col = i % nb_col;  // nb_col columns
        int index = IDX_COL_MAJOR(row, col, nb_row);
        stage_real[index] = In_real[i];
        stage_imag[index] = In_imag[i];
    }

    // Step 2: FFTs on each column (each of length nb_row)
    for (int col = 0; col < nb_col; col += NUM_WORKERS)
    {
        int workers = NUM_WORKERS;
        if (workers + col > nb_col){
            workers = nb_col - col;
        }

    	int col_index = col * nb_row;
        FXP_TYPE *in_real_ptr = &stage_real[col_index];
        FXP_TYPE *in_imag_ptr = &stage_imag[col_index];

        FXP_TYPE *out_real_ptr = &temp_real[col_index];
        FXP_TYPE *out_imag_ptr = &temp_imag[col_index];

        fft_hw(in_real_ptr, in_imag_ptr, log2_r, out_real_ptr, out_imag_ptr, workers);

        // Step 3: Twiddle multiplication for each row (index k)
        for (int worker = 0; worker < workers; ++worker)
        {
            for (int row = 0; row < nb_row; ++row)
            {
                int index = IDX_COL_MAJOR(row, col+worker, nb_row);
                FXP_TYPE real = temp_real[index];
                FXP_TYPE imag = temp_imag[index];

                // Compute W_N^{k * j} = e^(-2πi * row * col / N)
                double angle = -2.0 * M_PI * row * (col+worker) / (double)(N);
                FXP_TYPE tw_real = cos(angle);
                FXP_TYPE tw_imag = sin(angle);

                // Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
                FXP_TYPE new_real = real * tw_real - imag * tw_imag;
                FXP_TYPE new_imag = real * tw_imag + imag * tw_real;

                temp_real[index] = new_real;
                temp_imag[index] = new_imag;
            }
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
    for (int row = 0; row < nb_row; row += NUM_WORKERS)
    {
        int workers = NUM_WORKERS;
        if (workers + row > nb_row){
            workers = nb_row - row;
        }

    	int row_index = row * nb_col;
    	FXP_TYPE *in_real_ptr = &stage_real[row_index];
		FXP_TYPE *in_imag_ptr = &stage_imag[row_index];

		FXP_TYPE *out_real_ptr = &temp_real[row_index];
		FXP_TYPE *out_imag_ptr = &temp_imag[row_index];

		fft_hw(in_real_ptr, in_imag_ptr, log2_c, out_real_ptr, out_imag_ptr, workers);
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

    free(stage_real);
    free(stage_imag);
    free(temp_real);
    free(temp_imag);
}


// ----------------------------------- Segment's FFT -----------------------------------------

void fft_sw_segment(Complex* In, int log2_nfft, Complex* Out) {

    int nfft = 1 << log2_nfft;  // Total FFT size
    int segment_size_input = nfft / NUM_SEGMENTS;
    int segment_size_output = nfft / NUM_SEGMENTS;
    int log2_segment = log2_nfft - (int)std::log2(NUM_SEGMENTS);
    
    // Temporary storage
    Complex* input_segment = new Complex[segment_size_input];
    Complex* output_segment = new Complex[segment_size_output];
    Complex* temp_segment = new Complex[nfft];

    for (int seg = 0; seg < NUM_SEGMENTS; ++seg) {
        // Fill input segment
        for (int i = 0; i < segment_size_input; ++i) {
            int idx = seg * segment_size_input + i;
            input_segment[i] = In[idx];
        }

        // Compute FFT for the segment
        fft(input_segment, log2_segment, output_segment);

        // Write output
        for (int i = 0; i < segment_size_output; ++i) {
            int idx = seg * segment_size_output + i;
            temp_segment[idx] = output_segment[i];
        }
    }

    int i = 0;
    for (int k = 0; k < segment_size_output; ++k) {
        Complex sum_val(0.0f, 0.0f);
        for (int seg = 0; seg < NUM_SEGMENTS; ++seg) {
            int idx = seg * segment_size_output + k;
            sum_val += temp_segment[idx];
        }
        Out[i] = sum_val;
        i += 1;
         for (int seg = 0; seg < NUM_SEGMENTS-1; ++seg) {
            Out[i] = Complex(0.0f, 0.0f);
            i += 1;
        }
    }

    delete[] input_segment;
    delete[] output_segment;
    delete[] temp_segment;
}

// --------------------------------------------------------------------------

void fft_hw_segment(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, FXP_TYPE *Out_real, FXP_TYPE *Out_imag) {

    int nfft = 1 << log2_nfft;  // Number of FFT points
    int segment_size_input = nfft / NUM_SEGMENTS;
    int segment_size_output = nfft / NUM_SEGMENTS;
    int log2_segment = log2_nfft - (int)std::log2(NUM_SEGMENTS);

    // Temporary storage for real and imaginary parts of each segment
    FXP_TYPE *segment_real = (FXP_TYPE*)malloc(segment_size_input * sizeof(FXP_TYPE));
    FXP_TYPE *segment_imag = (FXP_TYPE*)malloc(segment_size_input * sizeof(FXP_TYPE));
    FXP_TYPE *segment_out_real = (FXP_TYPE*)malloc(segment_size_output * sizeof(FXP_TYPE));
    FXP_TYPE *segment_out_imag = (FXP_TYPE*)malloc(segment_size_output * sizeof(FXP_TYPE));

    FXP_TYPE *temp_out_real = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    FXP_TYPE *temp_out_imag = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));

    // Loop through each segment
    for (int seg = 0; seg < NUM_SEGMENTS; ++seg) {
        // Copy the corresponding segment from the input
        for (int i = 0; i < segment_size_input; ++i) {
            int idx = seg * segment_size_input + i;
            segment_real[i] = In_real[idx];
            segment_imag[i] = In_imag[idx];
        }

        // Call the hardware FFT for this segment
        fft_hw(segment_real, segment_imag, log2_segment, segment_out_real, segment_out_imag, 1);

        for (int i = 0; i < segment_size_output; ++i) {
            int idx = seg * segment_size_output + i;
            temp_out_real[idx] = segment_out_real[i];
            temp_out_imag[idx] = segment_out_imag[i];
        }
    }

    int i = 0;
    for (int k = 0; k < segment_size_output; ++k) {
        Complex sum_val(0.0f, 0.0f);
        for (int seg = 0; seg < NUM_SEGMENTS; ++seg) {
            int idx = seg * segment_size_output + k;
            sum_val += Complex(temp_out_real[idx], temp_out_imag[idx]);
        }
        Out_real[i] = sum_val.real();
        Out_imag[i] = sum_val.imag();
        i += 1;
         for (int seg = 0; seg < NUM_SEGMENTS-1; ++seg) {
            Out_real[i] = 0.0;
            Out_imag[i] = 0.0;
            i += 1;
        }
    }

    // Clean up temporary memory
    free(segment_real);
    free(segment_imag);
    free(segment_out_real);
    free(segment_out_imag);
    free(temp_out_real);
    free(temp_out_imag);
}

// -------------------------------------------------------------------------
// Main function to test FFT and hardware FFT operations
int main(int argc, char **argv) {
    srand(time(NULL));

    // Test case size, can be modified as needed
    int log2_nfft = 15; //between 10 and 19
    int nfft = 1 << (log2_nfft);
    uint32_t sizeInput =  nfft;  // Input size
    uint32_t sizeOutput = nfft; // Output size

     // Allocating memory for real and imaginary parts
    Complex* complete_input = nullptr;
    Complex* input_complex = new Complex[sizeInput];
    FXP_TYPE* input_real_fxp = (FXP_TYPE*)malloc(sizeInput * sizeof(FXP_TYPE));
    FXP_TYPE* input_imag_fxp = (FXP_TYPE*)malloc(sizeInput * sizeof(FXP_TYPE));

    Complex* outputSW = (Complex*)malloc(sizeOutput * sizeof(Complex));
    Complex* outputSW_segments = (Complex*)malloc(sizeOutput * sizeof(Complex));
    FXP_TYPE* outputHW_real_fxp = (FXP_TYPE*)malloc(sizeOutput * sizeof(FXP_TYPE));
    FXP_TYPE* outputHW_imag_fxp = (FXP_TYPE*)malloc(sizeOutput * sizeof(FXP_TYPE));
    FFT_TYPE* outputHW_real = (FFT_TYPE*)malloc(sizeOutput * sizeof(FFT_TYPE));
    FFT_TYPE* outputHW_imag = (FFT_TYPE*)malloc(sizeOutput * sizeof(FFT_TYPE));
    // Initializing input for complex (SW) and real+imaginary (HW)
    DatasetParam signal_param;
    load_bin_signal("../../../../../data_bin/data/signal_data.bin", signal_param, &complete_input);

    // ----------------------------------------------------------------------------
    #ifdef CSV_DATA
    std::ifstream file("../../../../dataInputFFT4.csv");
    std::string line;
    int i = 0;
    if (!file.is_open()) {
        std::cerr << "Error: Failed to open file.\n";
        return 1;
    }
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string realStr, imagStr;
        if (std::getline(ss, realStr, ',') && std::getline(ss, imagStr)) {
            if (i >= sizeInput) {
                break;
            }
            FFT_TYPE real = std::stof(realStr);
            FFT_TYPE imag = std::stof(imagStr);
            input_complex[i] = Complex(real, imag);
            i++;
        }
    }
    #endif

    // ----------------------------------------------------------------------------

    uint32_t stride = 1 << (SW_MAX_NSTAGES - log2_nfft);

    for (uint32_t i = 0; i < nfft; ++i)
    {
        #ifndef CSV_DATA
        input_complex[i] = complete_input[i * stride];
        #endif
        input_real_fxp[i] = (FXP_TYPE)input_complex[i].real();
        input_imag_fxp[i] = (FXP_TYPE)input_complex[i].imag();
        // printf("%.4f  %.4f \n", (float)input_real_fxp[i], input_complex[i].real());
    }

    printf("Evaluating FFT execution for %u-point FFT\n", nfft);

    // Resetting output vectors
    memset(outputHW_real_fxp, 0, sizeOutput * sizeof(FXP_TYPE));
    memset(outputHW_imag_fxp, 0, sizeOutput * sizeof(FXP_TYPE));
    memset(outputSW, 0, sizeOutput * sizeof(Complex));
    memset(outputSW_segments, 0, sizeOutput * sizeof(Complex));

    // Software FFT implementation (complex type)
    fft(input_complex, log2_nfft, outputSW);

    // Software FFT segment implementation (complex type)
    // fft_sw_segment(input_complex, log2_nfft, outputSW);

    // Hardware FFT basic implementation (real+imaginary type) --> not working because it uses too much memory
    //fft_hw(input_real_fxp, input_imag_fxp, log2_nfft, outputHW_real_fxp, outputHW_imag_fxp);

    // Hardware FFT Bailey implementation (real+imaginary type)
    bailey_fft(input_real_fxp, input_imag_fxp, log2_nfft, outputHW_real_fxp, outputHW_imag_fxp);
    for (int i = 0; i < sizeOutput; ++i)
    {
    	outputHW_real[i] = (float)outputHW_real_fxp[i] * nfft; // de-normalize the output
    	outputHW_imag[i] = (float)outputHW_imag_fxp[i] * nfft; // de-normalize the output
    }
    // Hardware FFT segment implementation (real+imaginary type) --> working but small percent of error in the values
    //fft_hw_segment(input_real, input_imag, log2_nfft, outputHW_real, outputHW_imag);

    // Compare results
	for (uint32_t ii = 0; ii < sizeOutput; ++ii)
	{
		printf("SW fft: %f, HW FFT %f \n", outputSW[ii].real(), outputHW_real[ii]);
        printf("SW fft: %f, HW FFT %f \n", outputSW[ii].imag(), outputHW_imag[ii]);
        break;
	}
    float outputSW_magnitude[sizeOutput];
    float outputHW_magnitude[sizeOutput];
    for (int i = 0; i < sizeOutput; ++i)
    {
    	outputSW_magnitude[i] = std::sqrt(outputSW[i].real()*outputSW[i].real() + outputSW[i].imag()*outputSW[i].imag());
    	outputHW_magnitude[i] = std::sqrt(outputHW_real[i]*outputHW_real[i] + outputHW_imag[i]*outputHW_imag[i]);
    }

    float snr = -1;
    snr = SNR(outputSW_magnitude, outputHW_magnitude, sizeOutput);
    printf("SNR: %.2f dB\n", snr);

    save_fft_output(outputSW, nfft, "fft_sw.csv");
    save_fft_output_from_real_imag(outputHW_real, outputHW_imag, nfft, "fft_hw.csv");

    // Cleanup*/
    free(input_complex);
    free(input_real_fxp);
    free(input_imag_fxp);
    free(outputSW);
    free(outputSW_segments);
    free(outputHW_real);
    free(outputHW_imag);
    free(outputHW_real_fxp);
    free(outputHW_imag_fxp);
    return 0;
}
