############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
############################################################
open_project Exercise01_HLS
set_top Adder
add_files HLS/adder.cpp
add_files HLS/adder.h
add_files -tb HLS/main.cpp
open_solution "solution1" -flow_target vivado
set_part {xc7z020clg400-1}
create_clock -period 10 -name default
config_export -display_name SimpleAdder -format ip_catalog -output ./IP-catalog/HLS_SimpleAdder.zip -rtl vhdl -vendor EPFL -vivado_clock 10
#csynth_design
#export_design -rtl vhdl -format ip_catalog -output ./IP-catalog/HLS_SimpleAdder.zip
quit
