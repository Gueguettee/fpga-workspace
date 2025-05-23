#include <stdlib.h>
#include <inttypes.h>

#include "fft.h"
#include "utils.h"

#define CSV_DATA

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
#define IDX(row, col, ncols) ((row) * (ncols) + (col))

void bailey_fft(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft,
                FXP_TYPE *Out_real, FXP_TYPE *Out_imag)
{
    int N = 1 << log2_nfft;
    int log2_r = log2_nfft / 2;
    int log2_s = log2_nfft - log2_r;
    int r = 1 << log2_r;
    int s = 1 << log2_s;

    // Step 1: Arrange input into r x s matrix row-wise
    FXP_TYPE *stage_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *stage_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *temp_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *temp_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));

    for (int i = 0; i < N; ++i)
    {
        int row = i / s;
        int col = i % s;
        stage_real[IDX(row, col, s)] = In_real[i];
        stage_imag[IDX(row, col, s)] = In_imag[i];
    }

    // Step 2: FFTs on each column (each of length r)
    for (int col = 0; col < s; ++col)
    {
        for (int row = 0; row < r; ++row)
        {
            temp_real[row] = stage_real[IDX(row, col, s)];
            temp_imag[row] = stage_imag[IDX(row, col, s)];
        }

        fft_hw(temp_real, temp_imag, log2_r, temp_real, temp_imag);

        for (int row = 0; row < r; ++row)
        {
            stage_real[IDX(row, col, s)] = temp_real[row];
            stage_imag[IDX(row, col, s)] = temp_imag[row];
        }
    }

    // Step 3: Multiply by twiddle factor
    for (int row = 0; row < r; ++row)
    {
        for (int col = 0; col < s; ++col)
        {
            int k = row;
            int j = col;
            double angle = -2.0 * M_PI * j * k / N;
            FXP_TYPE wr = cos(angle);
            FXP_TYPE wi = sin(angle);

            FXP_TYPE a_real = stage_real[IDX(row, col, s)];
            FXP_TYPE a_imag = stage_imag[IDX(row, col, s)];

            FXP_TYPE tw_real = a_real * wr - a_imag * wi;
            FXP_TYPE tw_imag = a_real * wi + a_imag * wr;

            stage_real[IDX(row, col, s)] = tw_real;
            stage_imag[IDX(row, col, s)] = tw_imag;
        }
    }

    // Step 4: FFTs on each row (each of length s)
    for (int row = 0; row < r; ++row)
    {
        for (int col = 0; col < s; ++col)
        {
            temp_real[col] = stage_real[IDX(row, col, s)];
            temp_imag[col] = stage_imag[IDX(row, col, s)];
        }

        fft_hw(temp_real, temp_imag, log2_s, temp_real, temp_imag);

        for (int col = 0; col < s; ++col)
        {
            stage_real[IDX(row, col, s)] = temp_real[col];
            stage_imag[IDX(row, col, s)] = temp_imag[col];
        }
    }

    // Step 5: Write result back in transposed (col-major) order
    for (int row = 0; row < r; ++row)
    {
        for (int col = 0; col < s; ++col)
        {
            int out_idx = col * r + row;  // Transpose: (row, col) becomes (col, row)
            Out_real[out_idx] = stage_real[IDX(row, col, s)];
            Out_imag[out_idx] = stage_imag[IDX(row, col, s)];
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
        fft_hw(segment_real, segment_imag, log2_segment, segment_out_real, segment_out_imag);

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
    int log2_nfft = 17; //between 10 and 19
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
