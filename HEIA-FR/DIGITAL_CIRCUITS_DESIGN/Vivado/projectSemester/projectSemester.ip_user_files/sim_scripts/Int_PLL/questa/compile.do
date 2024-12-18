vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../ipstatic" \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL_clk_wiz.v" \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL.v" \


vlog -work xil_defaultlib \
"glbl.v"

