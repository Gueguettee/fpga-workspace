# Testbench:
iverilog -s profiling_tb -o testbench profiling_tb.v profiling.v counter.v
./testbench
gtkwave profiling_tb.vcd
