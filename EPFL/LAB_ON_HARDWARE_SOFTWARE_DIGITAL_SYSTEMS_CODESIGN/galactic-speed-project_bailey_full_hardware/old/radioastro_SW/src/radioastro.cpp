// main.cpp
#include "signal_processing.h"
#include <iostream>
#include <stdlib.h>
//#include "matplotlibcpp.h"
#include <time.h>

// Configuration parameters
#define NUM_CONFIGS 10
configurations_t config_settings[NUM_CONFIGS] = {
    {10,    12,    12,      12,     3       , "../data_bin/gain_0.bin", "../data_bin/ref_0.bin" },  // config_id = 0
    {11,    24,    24,      24,     10      , "../data_bin/gain_1.bin", "../data_bin/ref_1.bin" },  // config_id = 1
    {12,    48,    48,      48,     10      , "../data_bin/gain_2.bin", "../data_bin/ref_2.bin" },  // config_id = 2
    {13,    96,    96,      96,     10      , "../data_bin/gain_3.bin", "../data_bin/ref_3.bin" },  // config_id = 3
    {14,    192,   192,     192,    200     , "../data_bin/gain_4.bin", "../data_bin/ref_4.bin" },  // config_id = 4
    {15,    384,   384,     384,    10      , "../data_bin/gain_5.bin", "../data_bin/ref_5.bin" },  // config_id = 5
    {16,    768,   768,     768,    10      , "../data_bin/gain_6.bin", "../data_bin/ref_6.bin" },  // config_id = 6
    {17,    2304,  2304,    2304,   200     , "../data_bin/gain_7.bin", "../data_bin/ref_7.bin" },  // config_id = 7
    {18,    3072,  3072,    3072,   200     , "../data_bin/gain_8.bin", "../data_bin/ref_8.bin" },  // config_id = 8
    {19,    6144,  6144,    6144,   200     , "../data_bin/gain_9.bin", "../data_bin/ref_9.bin" }   // config_id = 9
};

int main(int argc, char* argv[]) {
    /*----------------------
    Processing pipeline
    ----------------------*/ 
    TTimes times;
    struct timespec start_program, end_program;
    struct timespec start_segment, end_segment;
    int peaks_len = 0;
    
    // Load program parameters
    InParameters params = load_in_param(argc, argv);

    // Select configuration
    configurations_t config = config_settings[params.config_id];
    
    // Constants
    float sample_rate = 2.048e6; // From the antenna 2.048 MHz
    float c = 3e8; // Speed of light in m/s
    float hydro_freq = 1420.40575177e6; // Hydrogen line rest frequency in Hz
    int nfft = 1 << config.log2_nfft; // NFFT = 2^NStages
    params.freq_res = sample_rate / nfft; // Frequency resolution
    params.vel_res = c * params.freq_res / hydro_freq; // Velocity resolution
    int len_avg = nfft - (config.ma_w-1);
    
    PrintConfigs(params, config);
    
    // Memory allocation
    std::complex<float> *signal = nullptr;
    float *freqs = (float*)malloc(nfft*sizeof(float));
    float *freqs_ma = (float*)malloc(len_avg*sizeof(float));
    float *psd = (float*)malloc(nfft*sizeof(float));
    float *psd_ma = (float*)malloc(len_avg*sizeof(float));
    float *psd_ps = (float*)malloc(len_avg*sizeof(float));
    float *psd_gf = (float*)malloc(len_avg*sizeof(float));
    float* gain = nullptr;
    float *psd_norm = (float*)malloc(nfft*sizeof(float));
    float* peaks_idx = (float*)malloc(PEAKS_MAX*sizeof(float));
    float *velocities = nullptr;
    float *peak_freq = nullptr;
    float *peak_height = nullptr;
    float *save = psd_gf;
    
    // Load input data
    // Sky data
    DatasetParam signal_param;
    load_bin_signal(params.signal_file, signal_param, &signal);
    
    // Load Gain data
    read_res_bin(config.gain_file, &gain);
    
    // 3) Compute power spectral density using Weltch's method
    int num_samples = (int)signal_param.num_samples;
    if (num_samples % nfft != 0) {
        std::cerr << "Error: num_samples must be divisible by NFFT without a remainder." << std::endl;
        return -1;
    }
    int Nseg = num_samples / nfft;

    /*---------------------*\
        Start processing
    \*---------------------*/ 

    clock_gettime(CLOCK_MONOTONIC_RAW, &start_program);

    // 1) Sky spectrum
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    welch_psd(signal, Nseg, sample_rate, (int)signal_param.fc, freqs, config.log2_nfft, psd, times);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    times.timePSD = CalcTimeDiff(end_segment, start_segment);

    // 2) Moving average
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    moving_average(psd, nfft, config.ma_w, psd_ma);
    for (int i = 0; i < len_avg; i++){
        freqs_ma[i] = freqs[(int)(i + config.ma_w/2)];
    }
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    times.timeMA = CalcTimeDiff(end_segment, start_segment);

    // 3) Peak Smoothing
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    peak_smoothing(psd_ma, len_avg, config.ps_w, psd_ps);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    times.timePS = CalcTimeDiff(end_segment, start_segment);

    // 4) Gaussian filter
    clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
    gauss_smoothing(psd_ps, len_avg, config.gf_w, psd_gf);
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
    times.timeGF = CalcTimeDiff(end_segment, start_segment);

    if (gain != nullptr){
        // 5) Calibration
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);    
        for (int i = 0; i < len_avg; i++){
            psd_norm[i] = psd_gf[i]/gain[i];
        }
        save = psd_norm;
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        times.timeCal = CalcTimeDiff(end_segment, start_segment);
        
        // 6) Detect peaks
        peaks_len = 0;
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);
        peaks_len = find_peaks(psd_norm, len_avg, params.peaks_height, params.peaks_prom, config.pd_w, peaks_idx);
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        times.timeDetectPeaks = CalcTimeDiff(end_segment, start_segment);
    
        // 7) Compute velocity shift due to Doppler effect
        velocities = (float*)malloc(peaks_len*sizeof(float));
        peak_freq = (float*)malloc(peaks_len*sizeof(float));
        peak_height = (float*)malloc(peaks_len*sizeof(float));
        clock_gettime(CLOCK_MONOTONIC_RAW, &start_segment);  
        for(int i = 0; i < peaks_len; i++){
            int peak = peaks_idx[i];
            peak_freq[i] = freqs_ma[peak];
            peak_height[i] = psd_norm[peak];
            velocities[i] = c * (peak_freq[i] - hydro_freq) / hydro_freq;
        }
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_segment);
        times.timeVelocity = CalcTimeDiff(end_segment, start_segment);
    
    }
    
    clock_gettime(CLOCK_MONOTONIC_RAW, &end_program);
    times.timeTotal = CalcTimeDiff(end_program, start_program);

    /*---------------------*\
        End processing
    \*---------------------*/ 

    // Print results
    for (int i = 0; i < peaks_len; i++){
        std::cout << "Arm " << i << ": Peak Frequency = " << peak_freq[i] << "Hz, Velocity = " << velocities[i]/1000 << " km/s"<< std::endl;
    }

    // Save output data
    if (!params.out_file.empty()){
        write_res_bin(params.out_file, save, freqs_ma, (int64_t)len_avg, peak_height, peak_freq, (int64_t)peaks_len);
    }

    // Reference data
    float snr = -1;
    float* reference;
    read_res_bin(config.ref_file, &reference);
    snr = SNR(reference, save, len_avg);
    std::cout << "SNR: " << snr << " dB" << std::endl;
    
    // Deallocate dynamically allocated memory
    free(signal);
    free(freqs);
    free(psd);
    free(gain);
    free(psd_norm);
    free(freqs_ma);
    free(psd_ma);
    free(psd_ps);
    free(psd_gf);
    free(peaks_idx);
    free(peak_freq);
    free(peak_height);
    free(velocities);
    
    
    // Save metrics to CSV
    if (!params.profile_file.empty()){
        save_metrics(params.profile_file, params.config_id, config, times, snr, params.freq_res, params.vel_res);
    }
    
    // Print times
    PrintTimes(times); 
    
    // Check SNR
    if (std::isfinite(snr) && snr < SNR_LIMIT){
        std::cout << "******************************************" << std::endl;
        std::cout << "Warning: SNR is lower than " << SNR_LIMIT << " dB!!" << std::endl;
        std::cout << "******************************************" << std::endl;
        return -1;
    }else{
        return 0;
    }
}
