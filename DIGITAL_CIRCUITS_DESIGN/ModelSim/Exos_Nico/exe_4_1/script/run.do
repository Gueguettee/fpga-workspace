# Clear all previous simulation data
restart

# Simulate for 1000 ns
vsim -t 1ns

# Clear all waves at the start
delete wave *

# Add input and output ports to the wave window
add wave -divider Input
add wave sim:/MemCTRL/clk_i
add wave sim:/MemCTRL/rst_i
add wave sim:/MemCTRL/en_i
add wave sim:/MemCTRL/rw_i
add wave sim:/MemCTRL/ready_i
add wave sim:/MemCTRL/current_state_s
add wave sim:/MemCTRL/next_state_s
add wave -divider Output
add wave sim:/MemCTRL/re_o
add wave sim:/MemCTRL/we_o

# Set initial values for inputs
force -freeze sim:/MemCTRL/clk_i 0 0 ps
force -freeze sim:/MemCTRL/rst_i 0 0 ps
force -freeze sim:/MemCTRL/en_i 0 0 ps
force -freeze sim:/MemCTRL/rw_i 0 0 ps
force -freeze sim:/MemCTRL/ready_i 0 0 ps

# Set the clock signal
force -freeze sim:/MemCTRL/clk_i 1 0, 0 {50 ns} -r 100 ns

# Reset
force -freeze sim:/MemCTRL/rst_i 1 10 ns
force -freeze sim:/MemCTRL/rst_i 0 20 ns

# Test all possible transitions systematically
# Transition from RST to IDLE
force -freeze sim:/MemCTRL/en_i 0 50 ns

# Transition from IDLE to ENABLE
force -freeze sim:/MemCTRL/en_i 1 100 ns

# Transition from ENABLE to WR_DATA (rw_i set to 0)
force -freeze sim:/MemCTRL/rw_i 0 200 ns

# Transition from WR_DATA to IDLE
force -freeze sim:/MemCTRL/ready_i 1 400 ns

# Transition from ENABLE to RD_DATA (rw_i set to 1)
force -freeze sim:/MemCTRL/rw_i 1 450 ns

# Transition from RD_DATA to IDLE
force -freeze sim:/MemCTRL/ready_i 1 550 ns

# Transition from ENABLE to IDLE
force -freeze sim:/MemCTRL/en_i 0 600 ns

# Run the simulation for a fixed time of 1000 ns
run 1000 ns
