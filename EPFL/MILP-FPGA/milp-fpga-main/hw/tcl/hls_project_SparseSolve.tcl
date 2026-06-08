open_component SparseSolve_HLS -flow_target vivado
set_top SparseSolve
add_files kernels/sparse_solve/src/sparse_solve.h -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_solve.cpp -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_kform.h -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_kform.cpp -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_factor.h -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_factor.cpp -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_triangular_solve.h -cflags "-I../shared"
add_files kernels/sparse_solve/src/sparse_triangular_solve.cpp -cflags "-I../shared"
add_files -tb kernels/sparse_solve/tb/sparse_solve_tb.cpp -cflags "-Ikernels/sparse_solve/src -Ikernels/common -I../shared"
set_part {xczu7ev-ffvc1156-2-e}
create_clock -period 5.5 -name default
config_export -display_name SparseSolve -format ip_catalog -output ./build/ip_repo/SparseSolve.zip -rtl verilog -vendor EPFL -vivado_clock 5.5
