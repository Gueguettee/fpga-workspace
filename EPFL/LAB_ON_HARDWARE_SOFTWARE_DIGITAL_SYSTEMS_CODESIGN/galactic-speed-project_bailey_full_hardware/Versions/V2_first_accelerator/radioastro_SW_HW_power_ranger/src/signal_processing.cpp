#include <stdint.h> 
#include <stdio.h>
#include <iostream>
#include <cmath>
#include <map>
#include <fstream>

#include "CAccelProxy.hpp"
#include "CXADCProxy.hpp"
#include "CFFTProxy.hpp"
#include "signal_processing.h"

#define BAILEY_FFT

// The length of the output vector is len(a)-(mavavg_points-1)
void moving_average(float* a, int a_len, int window, float* filt_a) {
    float sum = 0.0;

    // Compute the initial window sum
    for (int i = 0; i < window; ++i) {
        sum += a[i];
    }
    int a_idx = 0;
    filt_a[a_idx] = sum/window;

    // Compute moving average using a sliding window
    for (int i = window; i < a_len; ++i) {
        sum += a[i] - a[i - window];  // Update sum by adding new element and removing old one
        a_idx++;
        filt_a[a_idx] = sum / window;
    }
}

// Function to check if a point is a local maximum
bool is_local_max(const float* signal, int idx, int len, int window) {
    float val = signal[idx];
    for (int i = std::max(0, idx - window); i <= std::min(len - 1, idx + window); ++i) {
        if (i != idx && signal[i] >= val) {
            return false;
        }
    }
    return true;
}

// Function to detect peaks
int find_peaks(float* signal, int signal_len, float height, float prominence, int peak_window, float* filtered_peaks) {
    
    float* peaks = (float*)malloc(PEAKS_MAX*sizeof(float));
    int peaks_len = 0;

    // Detect candidate peaks
    for (int i = 0; i < signal_len; ++i) {
        if (peaks_len == PEAKS_MAX) break;
        if (signal[i] >= height && is_local_max(signal, i, signal_len, peak_window)) {
            peaks[peaks_len++] = i;
        }
    }
    
    // Check if the peak is prominent
    int filtered_peaks_len = 0;
    for (int i = 0; i < peaks_len; i++) {
        int peak_idx = peaks[i];
        float left_min = signal[peak_idx], right_min = signal[peak_idx];
        
        // Find left valley
        for (int j = peak_idx - 1; j >= 0; --j) {
            if (signal[j] < left_min) left_min = signal[j];
            else break;  // Stop at first rising edge
        }
        
        // Find right valley
        for (int j = peak_idx + 1; j < signal_len; ++j) {
            if (signal[j] < right_min) right_min = signal[j];
            else break;  // Stop at first rising edge
        }
        
        float peak_prominence = signal[peak_idx] - std::max(left_min, right_min);
        if (peak_prominence >= prominence) {
            filtered_peaks[filtered_peaks_len] = peak_idx;
            filtered_peaks_len++;
        }
    }

    free(peaks);
    return filtered_peaks_len;
}

unsigned int reverse_bits(unsigned int input, int num_stages) {
	int i, rev = 0;
	for (i = 0; i < num_stages; i++) {
		rev = (rev << 1) | (input & 1);
		input = input >> 1;
	}
	return rev;
}

void bit_reverse(std::complex<float>* X, int nfft, int num_stages, std::complex<float>* OUT) {
    int reversed;
    std::complex<float> temp;
  
    for (int i = 0; i < nfft; i++) {
	    reversed = reverse_bits(i, num_stages); // Find the bit reversed index
		if (i <= reversed) {
			// Swap the real values
			temp = X[i];
			OUT[i] = X[reversed];
			OUT[reversed] = temp;
		}
	}
}

void fft_stage(int stage, std::complex<float>* X, int nfft, std::complex<float>* Out) {
    int DFTpts = 1 << stage;    // DFT = 2^stage = points in sub DFT
    int numBF = DFTpts / 2;     // Butterfly WIDTHS in sub-DFT
    float e = -2 * M_PI / DFTpts;
    float a = 0.0;
    // Perform butterflies for j-th stage
    for (int j = 0; j < numBF; j++) {
        // Can be computed once as a look-up table (for the last stage)
        float c = cos(a);
        float s = sin(a);
        std::complex<float> twiddle = std::complex<float>(c, s);
        a = a + e;
        // Compute butterflies that use same W**k
        for (int i = j; i < nfft; i += DFTpts) {
            int i_lower = i + numBF; // index of lower point in butterfly
            std::complex<float> temp = X[i_lower] * twiddle;
            Out[i_lower] = X[i] - temp;
            Out[i] = X[i] + temp;
        }
    }
}

std::complex<float> Stage[MAX_NSTAGES][MAX_NFFT];
void fft(std::complex<float>* In, int log2_nfft, std::complex<float>* Out) {
    
    int nstages = log2_nfft;
    int nfft = 1 << nstages; // NFFT = 2^NStages 

    bit_reverse(In, nfft, nstages, Stage[0]);
    for (int stage = 1; stage < nstages; stage++) { // Do M-1 stages of butterflies
        fft_stage(stage, Stage[stage-1], nfft, Stage[stage]);
    }
    fft_stage(nstages, Stage[nstages-1], nfft, Out);
}

float custom_hanning_window(float* win, int N){
    float location = -M_PI * 4 / 2.0;
    float norm_factor = 0;
    for (int i = 0; i < N; i++){
        location += M_PI / N;
        win[i] = sin(location) / (location);
        win[i] *= sin(M_PI*i/(N-1))*sin(M_PI*i/(N-1));
        norm_factor += win[i]* win[i];
    }
    return norm_factor;
}     

float hanning_window(float* win, int N){
    float norm_factor = 0;
    for (int i = 0; i < N; i++){
        win[i] = sin(M_PI*i/(N-1))*sin(M_PI*i/(N-1));
        norm_factor += win[i]* win[i];
    }
    return norm_factor;
}

void window(std::complex<float>* In, int N, float* kernel, std::complex<float>* Out){
    for (int i = 0; i < N; i++){
        Out[i] = In[i] * kernel[i];
    }
}

void add_reduction_4(std::complex<float>* In, int N){
    for (int i = 0; i < N; i++){
        In[i] = In[i] + In[i+N] + In[i+2*N] + In[i+3*N];
    }
}

// Scale the spectrum by the norm of the window to compensate for windowing loss
void normalization(float* spectrum, float Fs, int size, float norm_factor){
    for (int i = 0; i < size; i++){
        spectrum[i] = spectrum[i]/(norm_factor*Fs);
    }
}

void welch_psd(std::complex<float>* samples, int Nseg, float Fs, float Fc, float* freqs, int log2_nfft, float* spectrum, TTimes & times, CXADCProxy *powerRanger, TEnergies & energies, CFFTProxy *fftProxy){
    struct timespec start_segment, end_segment;
    double energy_start_segment, energy_end_segment;

    int nfft = 1 << log2_nfft; // NFFT = 2^NStages
    float norm_factor = 0;
    float* hann_win = (float*)malloc(4 * nfft * sizeof(float));

    uint64_t timeBailey = 0;

    std::complex<float>* samples_buffer = (std::complex<float>*)malloc(4 * nfft * sizeof(std::complex<float>));
    std::complex<float>* coeff = (std::complex<float>*)malloc(nfft * sizeof(std::complex<float>));

    FXP_TYPE* input_real_fxp = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    FXP_TYPE* input_imag_fxp = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    FXP_TYPE* outputHW_real_fxp = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    FXP_TYPE* outputHW_imag_fxp = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));

    // initailize the spectrum
    for (int i = 0; i < nfft; i++){
        spectrum[i] = 0;
    }

    FXP_TYPE* twiddle_cos = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    FXP_TYPE* twiddle_sin = (FXP_TYPE*)malloc(nfft * sizeof(FXP_TYPE));
    int log2_r = log2_nfft / 2;
    int log2_s = log2_nfft - log2_r;
    int r = 1 << log2_r;
    int s = 1 << log2_s;
    for (int row = 0; row < r; ++row)
    {
        for (int col = 0; col < s; ++col)
        {
            int k = row;
            int j = col;
            int index = (j * k);

            double angle = -2.0 * M_PI * j * k / nfft;
            twiddle_cos[index] = Float2Fxp((float)cos(angle));
            twiddle_sin[index] = Float2Fxp((float)sin(angle));
        }
    }

    // Compute the Hanning window
    energy_start_segment = powerRanger->GetEnergy();
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    norm_factor = custom_hanning_window(hann_win, 4 * nfft);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    energy_end_segment = powerRanger->GetEnergy();
    times.timeHannGen = CalcTimeDiff(end_segment, start_segment);
    energies.energyHannGen = energy_end_segment - energy_start_segment;
    
    // window buffer
    times.timeHannWin = 0;
    times.timeRed = 0;
    times.timeFFT = 0;
    times.timeMag = 0;

    uint64_t timeStep1 = 0;
    uint64_t timeStep2 = 0;
    uint64_t timeStep3 = 0;
    uint64_t timeStep4 = 0;
    uint64_t timeStep5 = 0;

    for (int i = 0; i < Nseg-3; i+=1){ // Slide 1 block

        // Apply hanning wondow to 4 blocks
        energy_start_segment = powerRanger->GetEnergy();
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
        window(samples+i*nfft, 4 * nfft, hann_win, samples_buffer);
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        energy_end_segment = powerRanger->GetEnergy();
        times.timeHannWin += CalcTimeDiff(end_segment, start_segment);
        energies.energyHannWin += energy_end_segment - energy_start_segment;

        // Add the 4 blocks
        energy_start_segment = powerRanger->GetEnergy();
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
        add_reduction_4(samples_buffer, nfft);
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        energy_end_segment = powerRanger->GetEnergy();
        times.timeRed += CalcTimeDiff(end_segment, start_segment);
        energies.energyRed += energy_end_segment - energy_start_segment;

        // FFT
        energy_start_segment = powerRanger->GetEnergy();
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
#ifdef BAILEY_FFT
        /*std::ofstream file("output.csv");
        if (file.is_open()) {
            for (size_t i = 0; i < nfft; ++i) {
                file << samples_buffer[i].real() << "," << samples_buffer[i].imag() << "\n";
            }
            file.close();
        }*/
        //fft(samples_buffer, log2_nfft, coeff);

        //------------------------ Hardware FFT ---------------------------------------------------------------
        /*
        *   Convert to fixed point
        */
        for (int i = 0; i < nfft; ++i) 
        {
            input_real_fxp[i] = Float2Fxp(samples_buffer[i].real());
            input_imag_fxp[i] = Float2Fxp(samples_buffer[i].imag());
        }

        timeBailey += bailey_fft(input_real_fxp, input_imag_fxp, log2_nfft, outputHW_real_fxp, outputHW_imag_fxp, fftProxy, twiddle_cos, twiddle_sin, 
                                timeStep1, timeStep2, timeStep3, timeStep4, timeStep5);

        /*
        *   Convert to floating point
        */
        for (int i = 0; i < nfft; ++i)
        {
            coeff[i] = std::complex<float>(Fxp2Float(outputHW_real_fxp[i]) * nfft, Fxp2Float(outputHW_imag_fxp[i]) * nfft); // de-normalize the output
        }
#else
        fft(samples_buffer, log2_nfft, coeff);
#endif
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        energy_end_segment = powerRanger->GetEnergy();
        times.timeFFT += CalcTimeDiff(end_segment, start_segment);
        energies.energyFFT += energy_end_segment - energy_start_segment;

        // Integrate ~10 seconds of the signal
        energy_start_segment = powerRanger->GetEnergy();
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
        for (int k = 0; k < nfft; k++){
            spectrum[k] += (coeff[k].real()*coeff[k].real() + coeff[k].imag()*coeff[k].imag())/Nseg;
        }
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        energy_end_segment = powerRanger->GetEnergy();
        times.timeMag += CalcTimeDiff(end_segment, start_segment);
        energies.energyMag += energy_end_segment - energy_start_segment;
    }

    printf("\n Time bailey:             %17.3lf sec\n", timeBailey / 1e9);
    printf("Load col major:             %17.3lf sec\n", timeStep1 / 1e9);
    printf("FFT on cols:                %17.3lf sec\n", timeStep2 / 1e9);
    printf("col major to row major:     %17.3lf sec\n", timeStep3 / 1e9);
    printf("FFT on rows:                %17.3lf sec\n", timeStep4 / 1e9);
    printf("row major to col major:     %17.3lf sec\n \n", timeStep5 / 1e9);
    // Normalize the power spectrum density
    energy_start_segment = powerRanger->GetEnergy();
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    normalization(spectrum, Fs, nfft, norm_factor);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    energy_end_segment = powerRanger->GetEnergy();
    times.timeNorm = CalcTimeDiff(end_segment, start_segment);
    energies.energyNorm = energy_end_segment - energy_start_segment;

    // Translate spectrum around the central frequency
    energy_start_segment = powerRanger->GetEnergy();
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int i = nfft/2; i < nfft; i++){
        float temp_spectrum = spectrum[i];
        spectrum[i] = spectrum[i-nfft/2];
        spectrum[i-nfft/2] = temp_spectrum;
    }
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    energy_end_segment = powerRanger->GetEnergy();
    times.timeReord = CalcTimeDiff(end_segment, start_segment);
    energies.energyReord = energy_end_segment - energy_start_segment;

    // Generate frequencies
    energy_start_segment = powerRanger->GetEnergy();
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int i = 0; i < nfft; i++){
        freqs[i] = i * Fs / nfft + Fc - Fs / 2;
    }
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    energy_end_segment = powerRanger->GetEnergy();
    times.timeFreqGen = CalcTimeDiff(end_segment, start_segment);
    energies.energyFreqGen = energy_end_segment - energy_start_segment;

    // Free allocated memory
    free(hann_win);
    free(samples_buffer);
    free(coeff);
    free(input_real_fxp);
    free(input_imag_fxp);
    free(outputHW_real_fxp);
    free(outputHW_imag_fxp);
    free(twiddle_cos);
    free(twiddle_sin);
}

void gauss_window(float* window, int size){
    int fwhm_cal = int(size/4);
    float normal_factor_cal = 1/sqrt(2*M_PI*fwhm_cal*fwhm_cal);
    float *gx_cal = (float*)malloc((2*size + 1)*sizeof(float));
    for (int i = 0; i <= 2*size; i++){
        gx_cal[i] = i - size;
    }
    float win_sum = 0;
    for (int i = 0; i <= 2*size; i++){
        window[i] = normal_factor_cal*exp(-gx_cal[i]*gx_cal[i]/(2*fwhm_cal*fwhm_cal));
        win_sum += window[i];
    }
    for (int i = 0; i <= 2*size; i++){
        window[i] = window[i]/win_sum;
    }
    free(gx_cal);
}

void gauss_smoothing(float* data, int data_len, int window_size, float* smooth_data){
    float *window = (float*)malloc((2*window_size + 1)*sizeof(float));
    gauss_window(window,window_size);
    for (int i = 0; i < data_len; ++i) {
        float acc = 0.0;
        for (int j = 0; j <= 2*window_size; ++j) {
            int data_idx = i + j - window_size;
            if (data_idx >= 0 && data_idx < data_len) {
                acc += data[data_idx] * window[j];
            }
        }
        smooth_data[i] = acc;
    }
    free(window);
}

int compare (const void * a, const void * b)
{
  return ( *(float*)a < *(float*)b );
}

void moving_median(float* data, int data_len, int* index, int index_len, int window, float* filtered_spike){
    float* med_window = (float*)malloc((2*window+1)*sizeof(float));
    for (int i = 0; i < data_len; i++){
        filtered_spike[i] = data[i];
    }
    for (int i = 0; i < index_len; i++){
        int idx = index[i];
        for (int j = -window; j <= window; j++){
            med_window[j+window] = data[idx + j];
        }
        qsort(med_window, 2*window+1, sizeof(float), compare);
        filtered_spike[idx] = med_window[window];
    }    
    free(med_window);
}

void peak_smoothing(float* data, int data_len, int avg_window, float* filtered_data){
    float mean = 0;
    for (int i = 0; i < data_len; i++){
        mean += data[i];
    }
    mean /= data_len;
    float threshold = 1.20 * mean;
    int* idx_peaks = (int*)malloc(data_len*sizeof(int));
    int idx_peaks_len = 0; 
    for (int i = avg_window; i < data_len - avg_window; i++){
        if (data[i] > threshold){
            idx_peaks[idx_peaks_len] = i;
            idx_peaks_len++;
        }
    }

    moving_median(data, data_len, idx_peaks, idx_peaks_len, avg_window, filtered_data);

    free(idx_peaks);
}

//------------------------- Accelerators -------------------------------
// ------------------------ Bailey's FFT -----------------------------------------

// Helper: index in row-major order
#define IDX_ROW_MAJOR(row, col, ncols) ((row) * (ncols) + (col))

// Helper: index in col-major order
#define IDX_COL_MAJOR(row, col, nrows) ((col) * (nrows) + (row))

uint64_t bailey_fft(FXP_TYPE *In_real, FXP_TYPE *In_imag, int log2_nfft, 
                FXP_TYPE *Out_real, FXP_TYPE *Out_imag, CFFTProxy *fftProxy,
                FXP_TYPE *twiddle_cos, FXP_TYPE *twiddle_sin,
                uint64_t &timeStep1, uint64_t &timeStep2, uint64_t &timeStep3, uint64_t &timeStep4, uint64_t &timeStep5)
{
    int N = 1 << log2_nfft;
    int log2_r = log2_nfft / 2;
    int log2_c = log2_nfft - log2_r;
    int nb_row = 1 << log2_r;
    int nb_col = 1 << log2_c;

    struct timespec start_segment, end_segment;
    uint64_t time = 0;

    FXP_TYPE *stage_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *stage_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));

    FXP_TYPE *temp_real = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));
    FXP_TYPE *temp_imag = (FXP_TYPE*)malloc(N * sizeof(FXP_TYPE));

    FXP_TYPE *cache_in_real = (FXP_TYPE*)fftProxy->AllocDMACompatible(nb_col * NUM_WORKERS * sizeof(FXP_TYPE), 1);
    FXP_TYPE *cache_in_imag = (FXP_TYPE*)fftProxy->AllocDMACompatible(nb_col * NUM_WORKERS * sizeof(FXP_TYPE), 1);
    FXP_TYPE *cache_out_real = (FXP_TYPE*)fftProxy->AllocDMACompatible(nb_col * NUM_WORKERS * sizeof(FXP_TYPE), 1);
    FXP_TYPE *cache_out_imag = (FXP_TYPE*)fftProxy->AllocDMACompatible(nb_col * NUM_WORKERS * sizeof(FXP_TYPE), 1);

    // Step 1: Arrange input into nb_row x nb_col matrix col-wise
    // clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int i = 0; i < N; ++i)
    {
        int row = i / nb_col;  // nb_row rows
        int col = i % nb_col;  // nb_col columns
        int index = IDX_COL_MAJOR(row, col, nb_row);
        stage_real[index] = In_real[i];
        stage_imag[index] = In_imag[i];
    }
    // clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    // timeStep1 +=  CalcTimeDiff(end_segment, start_segment);
    // Step 2: FFTs on each column (each of length nb_row)
    // clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int col = 0; col < nb_col; col += NUM_WORKERS)
    {
    	uint32_t col_index = col * nb_row;// * sizeof(FXP_TYPE);

        int workers = NUM_WORKERS;
        if (workers + col > nb_col){
            workers = nb_col - col;
        }
        for (int i = 0; i < workers*nb_row; ++i) {
            cache_in_real[i] = stage_real[col_index+i];
            cache_in_imag[i] = stage_imag[col_index+i];
        }
        
        fftProxy->FFT_HW(cache_in_real, cache_in_imag, log2_r, cache_out_real, cache_out_imag, 0, workers);

        for (int i = 0; i < workers*nb_row; ++i) {
            temp_real[col_index+i] = cache_out_real[i];
            temp_imag[col_index+i] = cache_out_imag[i];
        }
    }
    // clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    // timeStep2 +=  CalcTimeDiff(end_segment, start_segment);

    // Step 4: FFTs on each row (each of length s)
    // Convert to row major
    // clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int row = 0; row < nb_row; ++row)
    {
        for (int col = 0; col < nb_col; ++col)
        {
        	int row_index = IDX_ROW_MAJOR(row, col, nb_col);
        	int col_index = IDX_COL_MAJOR(row, col, nb_row);

            FXP_TYPE real = temp_real[col_index];
			FXP_TYPE imag = temp_imag[col_index];

			FXP_TYPE wr = twiddle_cos[row * col];
            FXP_TYPE wi = twiddle_sin[row * col];

			// Complex multiply: (real + i*imag) * (tw_real + i*tw_imag)
			FXP_TYPE tw_real = FXP_Mult(real, wr) - FXP_Mult(imag, wi);
            FXP_TYPE tw_imag = FXP_Mult(real, wi) + FXP_Mult(imag, wr);

            stage_real[row_index] = tw_real;
            stage_imag[row_index] = tw_imag;
        }
    }
    // clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    // timeStep3 +=  CalcTimeDiff(end_segment, start_segment);

    // Perform FFTs on rows
    // clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    for (int row = 0; row < nb_row; row += NUM_WORKERS)
    {
    	int row_index = row * nb_col;// * sizeof(FXP_TYPE);

        int workers = NUM_WORKERS;
        if (workers + row > nb_row){
            workers = nb_row - row;
        }
        for (int i = 0; i < workers*nb_col; ++i) {
            cache_in_real[i] = stage_real[row_index+i];
            cache_in_imag[i] = stage_imag[row_index+i];
        }

        fftProxy->FFT_HW(cache_in_real, cache_in_imag, log2_c, cache_out_real, cache_out_imag, 0, workers);

        for (int i = 0; i < workers*nb_col; ++i) {
            temp_real[row_index+i] = cache_out_real[i];
            temp_imag[row_index+i] = cache_out_imag[i];
        }
    }

    // clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    // timeStep4 +=  CalcTimeDiff(end_segment, start_segment);

    // Step 5: Write result back in transposed (col-major) order
    // clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
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
    // clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    // timeStep5 += CalcTimeDiff(end_segment, start_segment);

    free(stage_real);
    free(stage_imag);
    free(temp_real);
    free(temp_imag);

    fftProxy->FreeDMACompatible(cache_in_real);
    fftProxy->FreeDMACompatible(cache_in_imag);
    fftProxy->FreeDMACompatible(cache_out_real);
    fftProxy->FreeDMACompatible(cache_out_imag);

    return time;
}
