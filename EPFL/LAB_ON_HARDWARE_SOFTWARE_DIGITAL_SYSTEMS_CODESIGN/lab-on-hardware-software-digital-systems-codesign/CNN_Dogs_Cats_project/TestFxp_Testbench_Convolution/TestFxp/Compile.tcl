open_project TestFXP
set_top TestFXP_HW
add_files HLS/testfxp.h
add_files HLS/testfxp.cpp
add_files -tb HLS/main.cpp
open_solution "solution1" -flow_target vivado
set_part {xc7z020clg400-1}
create_clock -period 10 -name default
config_export -display_name TestFxp -format ip_catalog -output ./IP-catalog/TestFxp_HLS.zip -rtl vhdl -vendor EPFL -vivado_clock 10
config_interface -m_axi_addr64=0
csim_design -O
#csynth_design
#export_design -rtl vhdl -format ip_catalog -output ./IP-catalog/Conv2D_HW_HLS.zip
quit
