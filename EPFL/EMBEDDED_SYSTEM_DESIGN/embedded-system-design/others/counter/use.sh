# Execute (-s specifies the top-level module, -o specifies the output file)
iverilog -s counterTestBench -o testbench counter.v counter_tb.v

# Perform the simulation by:
./testbench

# Observe the timing-diagram by:
gtkwave counterSignals.vcd
