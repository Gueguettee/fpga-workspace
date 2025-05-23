############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
############################################################
open_project Vitis
set_top Conv2D_HW
add_files HLS/conv2d.cpp
add_files HLS/conv2d.h
add_files -tb HLS/conv2DTestbench.cpp -cflags "-Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas -Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
open_solution "solution1" -flow_target vivado
set_part {xc7z020-clg400-1}
create_clock -period 10 -name default
config_export -display_name Conv2D_HW -format ip_catalog -output C:/git/lab-on-hardware-software-digital-systems-codesign/CNN_Dogs_Cats_project/Conv2D/IP-catalog -rtl verilog -vendor EPFL
source "./Vitis/solution1/directives.tcl"
csim_design
csynth_design
cosim_design
export_design -rtl verilog -format ip_catalog -output C:/git/lab-on-hardware-software-digital-systems-codesign/CNN_Dogs_Cats_project/Conv2D/IP-catalog
