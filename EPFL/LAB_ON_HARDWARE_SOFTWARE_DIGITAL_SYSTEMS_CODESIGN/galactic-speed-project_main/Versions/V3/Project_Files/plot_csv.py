import numpy as np
import matplotlib.pyplot as plt

PATH = "RadioAstro_HW_HLS/solution1/csim/build"

def plot_fft(csv_file, label, color):
    data = np.loadtxt(csv_file, delimiter=',')
    plt.plot(data[:, 0], data[:, 1], label=label, color=color)

plt.figure(figsize=(12, 6))
plot_fft(f"{PATH}/fft_sw.csv", "SW FFT", "blue")
plot_fft(f"{PATH}/fft_hw.csv", "HW FFT", "green")

plt.xlabel("Frequency bin")
plt.ylabel("Magnitude")
plt.title("SW FFT vs HW FFT")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("fft.png", dpi=300)
plt.show()
