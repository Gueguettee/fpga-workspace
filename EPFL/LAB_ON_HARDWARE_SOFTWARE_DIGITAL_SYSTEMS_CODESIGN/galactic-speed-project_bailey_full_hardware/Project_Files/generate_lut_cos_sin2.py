import numpy as np
import re
import math
from fxpmath import Fxp

file_path = "Project_Files/HLS/fft.h"

defines = {}
with open(file_path, 'r') as f:
    for line in f:
        match = re.match(r'#define\s+(\w+)\s+(.+)', line)
        if match:
            key, value = match.groups()
            defines[key] = value.strip()
if 'MAX_NSTAGES_BAILEY' in defines:
    nStage = int(defines['MAX_NSTAGES_BAILEY'].split(' ')[0])
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

N = 2**nStage

array = []
for col in range(N):
    for row in range(N):
        array.append(col*row)

array = np.array(array)
array = np.unique(array)
print(array[0:100])
print(len(array))
exit()

# Compute twiddle factors
angle = -2 * np.pi * array / (2**10)
tw_r = np.cos(angle)
tw_i = np.sin(angle)

# Convert to fixed-point
tw_r_fx = Fxp(tw_r, signed=True, n_word=n_word, n_int=n_int)
tw_i_fx = Fxp(tw_i, signed=True, n_word=n_word, n_int=n_int)

print("const FXP_TYPE twiddle_real2[{}] = {{\n    ".format(N) + (",\n    ".join(str(x) for x in tw_r)) +  "\n};\n\n")
#print("const FXP_TYPE twiddle_imag2[{}] = {{\n    ".format(N) + (",\n    ".join(str(x) for x in tw_i)) +  "\n};\n\n")


# def to_hex(val):
#     # Get the actual numeric value from the Fxp object
#     int_val = int(val.val)  # Access the `.val` attribute of the Fxp object
#     if int_val < 0:
#         int_val = (1 << n_word) + int_val  # 2's complement handling for negative values
#     return f"(FXP_TYPE)0x{int_val:08X}"

# print("const FXP_TYPE twiddle_real[{}] = {{\n    ".format(N) + (",\n    ".join(str(x) for x in tw_r)) +  "\n};\n\n")

# print("const FXP_TYPE twiddle_real[{}] = {{\n    ".format(N) +
#       ",\n    ".join(to_hex(x) for x in tw_r) +
#       "\n};\n")

# with open("HLS/twiddles.h", "w") as f:
#     # f.write("const float twiddle_real[{}] = {{\n    ".format(N))
#     # f.write(",\n    ".join(str(x) for x in tw_r))
#     # f.write("\n};\n\n")

#     # f.write("const float twiddle_imag[{}] = {{\n    ".format(N))
#     # f.write(",\n    ".join(str(x) for x in tw_i))
#     # f.write("\n};\n")