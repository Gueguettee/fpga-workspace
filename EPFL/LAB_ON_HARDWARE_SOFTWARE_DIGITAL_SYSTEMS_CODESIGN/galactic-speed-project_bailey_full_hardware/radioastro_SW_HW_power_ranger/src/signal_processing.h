#ifndef SIGNAL_PROCESSING_H
#define SIGNAL_PROCESSING_H

#include <math.h> // Use M_PI for the value of pi
#include "fxp_utils.h"

// #define NStages 10 // Nstages = log2(NFFT)
#define MAX_NSTAGES 19 // the maximum number of stages
#define MAX_NFFT (1 << MAX_NSTAGES) // the maximum number of FFT points
#define MAX_NSTAGES_BAILEY 10
#define MAX_NFFT_BAILEY (1 << MAX_NSTAGES_BAILEY)
#define PEAKS_MAX 1000 // the maximum number of peaks to find
#define SNR_LIMIT 70 // the minimum SNR to consider

#define NUM_WORKERS 8

// Helper: index in row-major order
#define IDX(row, col, ncols) ((row) * (ncols) + (col))

void moving_average(float* a, int a_len, int window, float* filt_a) ;
int find_peaks(float* signal, int signal_len, float height, float prominence, int peak_window, float* filtered_peaks);
unsigned int reverse_bits(unsigned int input, int num_stages);
void bit_reverse(std::complex<float>* X, int nfft, int num_stages, std::complex<float>* OUT);
void fft_stage(int stage, std::complex<float>* X, int nfft, std::complex<float>* Out);
void fft(std::complex<float>* In, int log2_nfft, std::complex<float>* Out);
float custom_hanning_window(float* win, int N);
float hanning_window(float* win, int N);
void window(std::complex<float>* In, int N, float* kernel, std::complex<float>* Out);
void add_reduction_4(float* In_R, float* In_I, int N);
void welch_psd(std::complex<float>* samples, int Nseg, float Fs, float Fc, float* freqs, int log2_nfft, float* spectrum, TTimes & times, CXADCProxy *powerRanger, TEnergies & energies, CFFTProxy *fftProxy);
void normalization(float* spectrum, float Fs, int size, float* kernel);
void gauss_window(float* window, int size);
void gauss_smoothing(float* data, int data_len, int window_size, float* smooth_data);
void moving_median(float* data, int data_len, int* index, int index_len, int window, float* filtered_spike);
int compare (const void * a, const void * b);
void peak_smoothing(float* data, int data_len, int avg_window, float* filtered_data);

void bailey_fft(std::complex<float>* samples_buffer, int log2_nfft, 
                std::complex<float>* coeff, CFFTProxy *fftProxy,
                FXP_TYPE *twiddle_cos, FXP_TYPE *twiddle_sin, FXP_TYPE *W_real, FXP_TYPE *W_imag,
                FXP_TYPE *stage_real, FXP_TYPE *stage_imag, FXP_TYPE *temp_real, FXP_TYPE *temp_imag,
                FXP_TYPE *cache_in_real, FXP_TYPE *cache_in_imag, FXP_TYPE *cache_out_real, FXP_TYPE *cache_out_imag,
                uint64_t &timeStep1, uint64_t &timeStep2, uint64_t &timeStep3, uint64_t &timeStep4, uint64_t &timeStep5);

#endif
