vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/lib_cdc_v1_0_2
vlib modelsim_lib/msim/proc_sys_reset_v5_0_14
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_vip_v1_1_15
vlib modelsim_lib/msim/processing_system7_vip_v1_0_17
vlib modelsim_lib/msim/fifo_generator_v13_2_9
vlib modelsim_lib/msim/axi_clock_converter_v2_1_28
vlib modelsim_lib/msim/generic_baseblocks_v2_1_1
vlib modelsim_lib/msim/axi_data_fifo_v2_1_28
vlib modelsim_lib/msim/axi_register_slice_v2_1_29
vlib modelsim_lib/msim/axi_protocol_converter_v2_1_29

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap lib_cdc_v1_0_2 modelsim_lib/msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_14 modelsim_lib/msim/proc_sys_reset_v5_0_14
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_15 modelsim_lib/msim/axi_vip_v1_1_15
vmap processing_system7_vip_v1_0_17 modelsim_lib/msim/processing_system7_vip_v1_0_17
vmap fifo_generator_v13_2_9 modelsim_lib/msim/fifo_generator_v13_2_9
vmap axi_clock_converter_v2_1_28 modelsim_lib/msim/axi_clock_converter_v2_1_28
vmap generic_baseblocks_v2_1_1 modelsim_lib/msim/generic_baseblocks_v2_1_1
vmap axi_data_fifo_v2_1_28 modelsim_lib/msim/axi_data_fifo_v2_1_28
vmap axi_register_slice_v2_1_29 modelsim_lib/msim/axi_register_slice_v2_1_29
vmap axi_protocol_converter_v2_1_29 modelsim_lib/msim/axi_protocol_converter_v2_1_29

vlog -work xilinx_vip  -incr -mfcu  -sv -L axi_vip_v1_1_15 -L processing_system7_vip_v1_0_17 -L xilinx_vip "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"D:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -incr -mfcu  -sv -L axi_vip_v1_1_15 -L processing_system7_vip_v1_0_17 -L xilinx_vip "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"D:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"D:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib  -93  \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0_1/sim/VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0.vhd" \
"../../../bd/VNAMI_BLOCK_DESIGN/ipshared/e228/hdl/PL_registers_v1_0_S00_AXI.vhd" \
"../../../bd/VNAMI_BLOCK_DESIGN/ipshared/e228/hdl/PL_registers_v1_0.vhd" \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_PL_registers_0_2_1/sim/VNAMI_BLOCK_DESIGN_PL_registers_0_2.vhd" \

vcom -work lib_cdc_v1_0_2  -93  \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_14  -93  \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/408c/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib  -93  \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_proc_sys_reset_0_0/sim/VNAMI_BLOCK_DESIGN_proc_sys_reset_0_0.vhd" \

vlog -work axi_infrastructure_v1_1_0  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_15  -incr -mfcu  -sv -L axi_vip_v1_1_15 -L processing_system7_vip_v1_0_17 -L xilinx_vip "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/5753/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_17  -incr -mfcu  -sv -L axi_vip_v1_1_15 -L processing_system7_vip_v1_0_17 -L xilinx_vip "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_processing_system7_1_0/sim/VNAMI_BLOCK_DESIGN_processing_system7_1_0.v" \

vcom -work xil_defaultlib  -93  \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_rst_ps7_0_100M_0/sim/VNAMI_BLOCK_DESIGN_rst_ps7_0_100M_0.vhd" \

vlog -work fifo_generator_v13_2_9  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ac72/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_9  -93  \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ac72/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_9  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ac72/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_clock_converter_v2_1_28  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/769c/hdl/axi_clock_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_axi_clock_converter_0_0/sim/VNAMI_BLOCK_DESIGN_axi_clock_converter_0_0.v" \

vcom -work xil_defaultlib  -93  \
"../../../bd/VNAMI_BLOCK_DESIGN/sim/VNAMI_BLOCK_DESIGN.vhd" \

vlog -work generic_baseblocks_v2_1_1  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/10ab/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_data_fifo_v2_1_28  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/279e/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_29  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ff9f/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work axi_protocol_converter_v2_1_29  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/a63f/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/ec67/hdl" "+incdir+../../../../VNAMI_MAIN.gen/sources_1/bd/VNAMI_BLOCK_DESIGN/ipshared/6b2b/hdl" "+incdir+D:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" \
"../../../bd/VNAMI_BLOCK_DESIGN/ip/VNAMI_BLOCK_DESIGN_auto_pc_0_1/sim/VNAMI_BLOCK_DESIGN_auto_pc_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

