import numpy as np
import re
import math
from fxpmath import Fxp

file_path = "HLS/fft.h"

defines = {}
with open(file_path, 'r') as f:
    for line in f:
        match = re.match(r'#define\s+(\w+)\s+(.+)', line)
        if match:
            key, value = match.groups()
            defines[key] = value.strip()
if 'MAX_NSTAGES' in defines:
    nStage = int(defines['MAX_NSTAGES'].split(' ')[0])
else:
    raise ValueError("MAX_TWIDDLES not found.")
if 'FXP_TYPE_WIDTH' in defines:
    n_word = int(defines['FXP_TYPE_WIDTH'].split(' ')[0])
else:
    raise ValueError("FXP_TYPE_WIDTH not found.")
if 'FXP_TYPE_INT_WIDTH' in defines:
    n_int = int(defines['FXP_TYPE_INT_WIDTH'].split(' ')[0])
else:
    raise ValueError("FXP_TYPE_INT_WIDTH not found.")

N = 2**(nStage-1)
tw_r = np.cos(2 * np.pi * np.arange(N) / (N*2))
tw_r = Fxp(tw_r, signed=True, n_word=n_word, n_int=n_int)
tw_i = -np.sin(2 * np.pi * np.arange(N) / (N*2))
tw_i = Fxp(tw_i, signed=True, n_word=n_word, n_int=n_int)

print("const FXP_TYPE twiddle_real[{}] = {{\n    ".format(N) + (",\n    ".join(str(x) for x in tw_r)) +  "\n};\n\n")

# with open("HLS/twiddles.h", "w") as f:
#     # f.write("const float twiddle_real[{}] = {{\n    ".format(N))
#     # f.write(",\n    ".join(str(x) for x in tw_r))
#     # f.write("\n};\n\n")

#     # f.write("const float twiddle_imag[{}] = {{\n    ".format(N))
#     # f.write(",\n    ".join(str(x) for x in tw_i))
#     # f.write("\n};\n")