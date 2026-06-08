source ./tcl/hls_project_SparseSolve.tcl
csynth_design
export_design -rtl verilog -format ip_catalog -output ./build/ip_repo/SparseSolve.zip
