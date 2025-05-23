import numpy as np
import argparse
import matplotlib.pyplot as plt

# Define the hydro frequency
hydro_freq = 1.42040575177  # in GHz

def read_data(file_path):
    """
    Reads binary data from a file and returns it as a numpy array of doubles.
    """
    with open(file_path, "rb") as f:
        size = int(np.frombuffer(f.read(8), dtype=np.uint64)[0])  # Read the size as unsigned long int
        size_peaks = int(np.frombuffer(f.read(8), dtype=np.uint64)[0])  # Read the size as unsigned long int
        data = np.frombuffer(f.read(size * 4), dtype=np.float32)  # Read the remaining data (float32)
        freq = np.frombuffer(f.read(size * 4), dtype=np.float32)  # Read the remaining data (float32)
        peak_height = np.frombuffer(f.read(size_peaks * 4), dtype=np.float32)  # Read the remaining data (float32)
        peak_freq = np.frombuffer(f.read(size_peaks * 4), dtype=np.float32)  # Read the remaining data (float32)
    return data, freq, peak_height, peak_freq

def plot_psd(data, freqs, name, peaks=None):

    # data = 10 * np.log10(data)  # Convert to dB

    plt.figure(figsize=(12, 6))
    plt.title(f"Power Spectral Density", fontsize=16)
    plt.xlabel('Frequency (GHz)', fontsize=14)
    plt.ylabel('Relative power', fontsize=14)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.ylim(0.8, 1.02)
    plt.plot(freqs, data)
    if peaks is not None:
        plt.vlines(hydro_freq, min(data), max(data), colors="b", linestyles="--", label="21cm Hydrogen Line")
        plt.plot(peaks[0], peaks[1], "rx", label="Detected Peaks")
        plt.legend()
    plt.savefig(f"{name}.png")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process radio astronomy data.")
    parser.add_argument('-f', '--file', type=str, required=True, help='Metrics file to process')
    args = parser.parse_args()
    file_path = args.file

    # Example usage
    data, freqs, p_height, p_freq = read_data(file_path)
    freqs = freqs / 1e9  # Convert to GHz
    p_freq = p_freq / 1e9  # Convert to GHz
    plot_psd(data, freqs, "spectrum", [p_freq, p_height])