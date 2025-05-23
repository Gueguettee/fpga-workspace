def int_to_hex32(value):
    """Convert a signed integer to 32-bit hexadecimal (two's complement)."""
    if value < 0:
        value = (1 << 32) + value  # Two's complement
    return value, f"0x{value:08X}"

def fixed_q4_28_to_float(value):
    """Interpret a signed 32-bit integer as a Q4.28 fixed-point float."""
    if value & (1 << 31):  # If sign bit is set
        value -= 1 << 32  # Convert from two's complement
    return value / (1 << 28)

# Input integer
num = -146323648

# Convert to 32-bit hex
int32_value, hex32 = int_to_hex32(num)

# Convert to fixed-point float (Q4.28)
fixed_point_value = fixed_q4_28_to_float(int32_value)

# Display results
print(f"Integer: {num}")
print(f"32-bit Hex: {hex32}")
print(f"Q4.28 Fixed-point value: {fixed_point_value:.6f}")
