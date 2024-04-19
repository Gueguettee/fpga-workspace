#add input and output ports
#add wave -divider Input
#add wave sim:/sipo_shift_reg/data_i
#add wave sim:/sipo_shift_reg/clk_i
#add wave sim:/sipo_shift_reg/rst_i
#add wave -divider Output
#add wave sim:/sipo_shift_reg/data_o
#add wave -divider Internal
#add wave sim:/sipo_shift_reg/SIPO_data_s

#Set init. values
force -freeze sim:/sipo_shift_reg/data_i 0 0 ns
force -freeze sim:/sipo_shift_reg/rst_i 0 0 ns
force -freeze sim:/sipo_shift_reg/clk_i 0 0 ns

#Set clock
force -freeze sim:/sipo_shift_reg/clk_i 1 0, 0 {50 ns} -r 100 ns

#rst
force -freeze sim:/sipo_shift_reg/rst_i 1 10 ns
force -freeze sim:/sipo_shift_reg/rst_i 0 20 ns

#
force -freeze sim:/sipo_shift_reg/data_i 1 150 ns
force -freeze sim:/sipo_shift_reg/data_i 0 290 ns
force -freeze sim:/sipo_shift_reg/data_i 1 350 ns
force -freeze sim:/sipo_shift_reg/data_i 0 410 ns
force -freeze sim:/sipo_shift_reg/data_i 1 550 ns

#run
run 4000 ns