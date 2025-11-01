----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.03.2022 18:37:59
-- Design Name: 
-- Module Name: TestBench - Behavioral
-- Project Name: 
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
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_PE43705 is
--  Port ( );
end TB_PE43705;

architecture mix of TB_PE43705 is

    --Inputs
    signal clk_i : std_logic;
    signal reset_i : std_logic;
    signal start_i : std_logic;
    signal data_i : std_logic_vector(7 downto 0);
    signal PAR_SER1_o : std_logic;
    signal SERIAL1_o : std_logic;
    signal CLK1_o : std_logic;
    signal LATCH_ENABLE1_o : std_logic;
    signal PAR_SER2_o : std_logic;
    signal SERIAL2_o : std_logic;
    signal CLK2_o : std_logic;
    signal LATCH_ENABLE2_o : std_logic;
    signal rdy_o : std_logic;
    
    -- Clock period definitions
    constant clk_i_period : time := 12.5 ns;
   
begin

    att_power_controller_comp : att_power_controller
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        start_i         => start_i,
        power_i          => data_i,

        rdy_o           => rdy_o,

        PAR_SER1_o       => PAR_SER1_o,
        SERIAL1_o        => SERIAL1_o,
        CLK1_o           => CLK1_o,
        LATCH_ENABLE1_o  => LATCH_ENABLE1_o,
        
        PAR_SER2_o       => PAR_SER2_o,
        SERIAL2_o        => SERIAL2_o,
        CLK2_o           => CLK2_o,
        LATCH_ENABLE2_o  => LATCH_ENABLE2_o
    );
  
   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process; 

-- Reset process
   reset_proc: process
   begin		
      -- hold reset state for 50 ns.
        reset_i <= '1';
        wait for 100 ns;
        reset_i <= '0';
        wait;
   end process;
   
-- Signal process
    signal_proc: process
    begin
        start_i <= '0';
        data_i <= "11010101";

        wait for 200 ns;

        start_i <= '1';

        wait;
        
    end process;

end mix;
