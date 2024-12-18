// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Tue Jan  9 08:47:07 2024
// Host        : LAPTOP-CJ972H0K running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/git/digital-circuits-desighs-workspace/Vivado/projectSemester/projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL_stub.v
// Design      : Int_PLL
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module Int_PLL(clk_o, clk_o_180, resetn, locked, clk_i)
/* synthesis syn_black_box black_box_pad_pin="resetn,locked,clk_i" */
/* synthesis syn_force_seq_prim="clk_o" */
/* synthesis syn_force_seq_prim="clk_o_180" */;
  output clk_o /* synthesis syn_isclock = 1 */;
  output clk_o_180 /* synthesis syn_isclock = 1 */;
  input resetn;
  output locked;
  input clk_i;
endmodule
