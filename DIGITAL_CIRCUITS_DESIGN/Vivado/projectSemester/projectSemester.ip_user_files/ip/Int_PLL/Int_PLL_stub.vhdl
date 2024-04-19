-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
-- Date        : Tue Jan  9 08:47:07 2024
-- Host        : LAPTOP-CJ972H0K running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/git/digital-circuits-desighs-workspace/Vivado/projectSemester/projectSemester.gen/sources_1/ip/Int_PLL/Int_PLL_stub.vhdl
-- Design      : Int_PLL
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Int_PLL is
  Port ( 
    clk_o : out STD_LOGIC;
    clk_o_180 : out STD_LOGIC;
    resetn : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_i : in STD_LOGIC
  );

end Int_PLL;

architecture stub of Int_PLL is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_o,clk_o_180,resetn,locked,clk_i";
begin
end;
