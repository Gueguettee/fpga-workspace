# Execute (-s specifies the top-level module, -o specifies the output file)
iverilog -s fifoTestBench -o testbench fifo.v fifo_tb.v semi_dual_port_ssram.v

# Perform the simulation by:
./testbench

# Observe the timing-diagram by:
gtkwave fifoSignals.vcd
