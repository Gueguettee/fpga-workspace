#add input and output ports
add wave -divider Inputs_Ports
add wave sim:/add2/a_i
add wave sim:/add2/b_i

add wave -divider Output_Ports
add wave sim:/add2/res_o

#Set init. values
force -freeze sim:/add2/a_i "00000000" 0 ns
force -freeze sim:/add2/b_i "00000000" 0 ns

#Set values of a, b
force -freeze sim:/add2/a_i "00000001" 10 ns
force -freeze sim:/add2/b_i "00000010" 10 ns

run 80 ns
