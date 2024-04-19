transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {C:/git/digital-circuits-desighs-workspace/Vivado/projectSemester/projectSemester.cache/compile_simlib/activehdl}
vlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../ipstatic" -l xil_defaultlib \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL_clk_wiz.v" \
"../../../../projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL.v" \


vlog -work xil_defaultlib \
"glbl.v"

