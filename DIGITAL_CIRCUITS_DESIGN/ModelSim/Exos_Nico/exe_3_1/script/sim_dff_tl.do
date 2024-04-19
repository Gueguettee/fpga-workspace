#add input and output ports
add wave -divider Input
add wave sim:/dff_tl/data_i
add wave sim:/dff_tl/clk_i
add wave sim:/dff_tl/rst_i
add wave -divider Output
add wave sim:/dff_tl/data_o

#Set init. values
force -freeze sim:/dff_tl/data_i 0 0 ns
force -freeze sim:/dff_tl/rst_i 0 0 ns
force -freeze sim:/dff_tl/clk_i 0 0 ns

#Set clock
force -freeze sim:/dff_tl/clk_i 1 0, 0 {50 ns} -r 100 ns

#rst
force -freeze sim:/dff_tl/rst_i 1 10 ns
force -freeze sim:/dff_tl/rst_i 0 20 ns
force -freeze sim:/dff_tl/rst_i 1 450 ns

#
force -freeze sim:/dff_tl/data_i 1 150 ns
force -freeze sim:/dff_tl/data_i 0 290 ns
force -freeze sim:/dff_tl/data_i 1 350 ns
force -freeze sim:/dff_tl/data_i 0 410 ns
force -freeze sim:/dff_tl/data_i 1 550 ns

#run
run 600 ns