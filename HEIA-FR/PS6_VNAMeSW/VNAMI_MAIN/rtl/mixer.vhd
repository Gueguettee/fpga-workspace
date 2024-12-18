LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;



entity mixer is
generic(
        BIT_WIDTH   : integer := 14
    );
port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        a_i         : in std_logic_vector(BIT_WIDTH-1 downto 0);
        b_i         : in std_logic_vector(BIT_WIDTH-1 downto 0);

        y_o         : out std_logic_vector(2*BIT_WIDTH-2 downto 0)
	);
end entity mixer;

architecture mix of mixer is
    
--------------------------- SIGNALS ---------------------------
	signal result_s    : std_logic_vector(2*BIT_WIDTH-1 downto 0);
	
-------------------------- COMPONENTS -------------------------
	
	
	
begin
--------------------------- DESIGN ----------------------------
    
    y_o <= result_s(2*BIT_WIDTH-1) & result_s(2*BIT_WIDTH-3 downto 0);
    
    -- MULT_MACRO: Multiply Function implemented in a DSP48E
    -- 7 Series
    -- Xilinx HDL Libraries Guide, version 14.7
    MULT_MACRO_inst : MULT_MACRO
    generic map (
        DEVICE  => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
        LATENCY => 1, -- Desired clock cycle latency, 0-4
        WIDTH_A => BIT_WIDTH, -- Multiplier A-input bus width, 1-25
        WIDTH_B => BIT_WIDTH) -- Multiplier B-input bus width, 1-18
    port map (
        P   => result_s, -- Multiplier output bus, width determined by WIDTH_P generic
        A   => a_i, -- Multiplier input A bus, width determined by WIDTH_A generic
        B   => b_i, -- Multiplier input B bus, width determined by WIDTH_B generic
        CE  => '1', -- 1-bit active high input clock enable
        CLK => clk_i, -- 1-bit positive edge clock input
        RST => reset_i -- 1-bit input active high reset
    );
    -- End of MULT_MACRO_inst instantiation
    
    

end architecture mix;

