----------------------------------------------------------------------------------
-- Company: HEIA-FR GE
-- Engineer: FRA
-- 
-- Create Date: 28.03.2022 11:14:48
-- Design Name: 
-- Module Name: SD_filter_toplevel - Behavioral
-- Project Name: TP-ELAP sigma-delta filters
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.SD_filter_pkg.all;

entity SD_filter_toplevel is
    Port ( clk_i : in STD_LOGIC;       -- 100MHz, from Zboard, connecte to nothing
           rst_i : in STD_LOGIC;       -- from Zboard's push-button BTNC
           fos_i : in STD_LOGIC;       -- from SD modulator
           bitstream_i : in STD_LOGIC; -- from SD modulator
           filtered_o : out STD_LOGIC_VECTOR (B_FIR-1 downto 0); -- to test DAC
           FIRnIIR_i : in STD_LOGIC;  -- from Zboard's switch SW0
           fir_o: out STD_LOGIC;
           iir_o: out STD_LOGIC);    
end SD_filter_toplevel;

architecture Behavioral of SD_filter_toplevel is

    signal clock_r: std_logic;
    signal data_fir: std_logic_vector (B_FIR-1 downto 0);
    signal data_iir: std_logic_vector (B_IIR-1 downto 0);
   
    component FIR_rect 
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_FIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC);
    end component;

    component IIR_LP1o 
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_IIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC);
    end component;

begin

filtered_o<= data_iir when FIRnIIR_i= '0' else data_fir; --FRA: modifi�e pour 16 bit de donn�e
fir_o<= not FIRnIIR_i;
iir_o<= FIRnIIR_i;

FIR: FIR_rect
port map (
   bitstream_i => bitstream_i,
   filtered_o => data_fir,
   reset_i => rst_i,
   clock_i => clock_r
);

IIR: IIR_LP1o
port map (
   bitstream_i => bitstream_i,
   filtered_o => data_iir,
   reset_i => rst_i,
   clock_i => clock_r
);

-- BUFR: Regional Clock Buffer for I/O and Logic Resources within a Clock Region
-- 7 Series
-- Xilinx HDL Libraries Guide, version 14.7
BUFR_inst : BUFR
generic map (
    BUFR_DIVIDE => "BYPASS", -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8"
    SIM_DEVICE => "7SERIES" -- Must be set to "7SERIES"
)
port map (
    O => clock_r, -- 1-bit output: Clock output port
    CE => '1', -- 1-bit input: Active high, clock enable (Divided modes only)
    CLR => '0', -- 1-bit input: Active high, asynchronous clear (Divided modes only)
    I => fos_i -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);
-- End of BUFR_inst instantiation

end Behavioral;
