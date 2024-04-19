vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../ipstatic" \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL_clk_wiz.v" \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL.v" \


vlog -work xil_defaultlib \
"glbl.v"

