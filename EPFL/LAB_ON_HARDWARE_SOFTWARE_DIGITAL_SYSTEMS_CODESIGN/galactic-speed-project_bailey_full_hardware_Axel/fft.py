import numpy as np
import matplotlib.pyplot as plt

def fft_radix2_dit(x):
    N = len(x)
    if N <= 1:
        return x

    if N % 2 != 0:
        raise ValueError("Size of x must be a power of 2")

    x_even = fft_radix2_dit(x[::2])
    x_odd  = fft_radix2_dit(x[1::2])

    factor = np.exp(-2j * np.pi * np.arange(N) / N)
    X = np.zeros(N, dtype=complex)
    for k in range(N // 2):
        t = factor[k] * x_odd[k]
        X[k] = x_even[k] + t
        X[k + N // 2] = x_even[k] - t
    return X

# Input signal (zero-padded to length 8)
x = np.array([1, 2, 3, 4], dtype=complex)
N = 8  # pad to power of 2
x_padded = np.zeros(N, dtype=complex)
x_padded[:len(x)] = x

# Compute FFT
X_custom = fft_radix2_dit(x_padded)
X_numpy = np.fft.fft(x_padded)
freq = np.arange(N)

# 📊 Plot the input and FFT results
plt.figure(figsize=(15, 4))

# --- Time-domain signal ---
plt.subplot(1, 3, 1)
plt.stem(np.arange(N), x_padded.real)
plt.title("Input Signal (Time Domain)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")

# --- Custom FFT Magnitude ---
plt.subplot(1, 3, 2)
plt.stem(freq, np.abs(X_custom))
plt.title("Custom FFT Magnitude")
plt.xlabel("Frequency Bin")
plt.ylabel("Magnitude")

# --- NumPy FFT Magnitude ---
plt.subplot(1, 3, 3)
plt.stem(freq, np.abs(X_numpy), linefmt='g-', markerfmt='go', basefmt='gray')
plt.title("NumPy FFT Magnitude")
plt.xlabel("Frequency Bin")

plt.tight_layout()
plt.show()
