LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity TL_management is
port
	(
        --clk_80_i        : in std_logic;
        --clk_100_i       : in std_logic;

        PLL_reset_i     : in std_logic;
        PS_reset_i      : in std_logic;
        BTN_reset_i     : in std_logic;
        
      --clocks on FMC
        --clk_80_o        : out std_logic;
        --clk_100_o       : out std_logic;

        --clk_main_PL_o   : out std_logic;

        reset_main_PL_o : out std_logic
    );
end entity TL_management;


architecture mix of TL_management is

--------------------------- SIGNALS ---------------------------

-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------
    
    --clk_80_o <= clk_80_i;
    --clk_100_o <= clk_100_i;

    --clk_main_PL_o <= clk_80_i;

    reset_main_PL_o <= not PLL_reset_i or PS_reset_i;-- or BTN_reset_i;

end architecture mix;
