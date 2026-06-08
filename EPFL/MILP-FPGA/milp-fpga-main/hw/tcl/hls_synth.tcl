source ./tcl/hls_project.tcl
csynth_design
export_design -rtl verilog -format ip_catalog -output ./build/ip_repo/SparseSolve.zip
