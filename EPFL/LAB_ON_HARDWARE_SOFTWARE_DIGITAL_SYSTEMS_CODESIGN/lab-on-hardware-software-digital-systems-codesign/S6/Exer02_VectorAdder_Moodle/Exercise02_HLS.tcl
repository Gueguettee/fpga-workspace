open_project Exercise02_HLS
set_top AddVectors
add_files HLS/vector.cpp
add_files HLS/vector.h
add_files -tb HLS/main.cpp
open_solution "solution1" -flow_target vivado
set_part {xc7z020clg400-1}
create_clock -period 10 -name default
config_export -display_name Exercise02 -format ip_catalog -output ./IP-catalog/HLS_VectorAdder.zip -rtl vhdl -vendor EPFL -vivado_clock 10
#csynth_design
#export_design -rtl vhdl -format ip_catalog -output ./IP-catalog/HLS_VectorAdder.zip
quit
