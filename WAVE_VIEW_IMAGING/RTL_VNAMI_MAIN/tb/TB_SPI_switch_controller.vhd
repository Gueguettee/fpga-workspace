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

entity TB_SPI_switch_controller is
--  Port ( );
end TB_SPI_switch_controller;

architecture Behavioral of TB_SPI_switch_controller is

    --Inputs
    signal clk_i : std_logic := '0';
    signal reset_i : std_logic := '0';
    signal start_seq_i : std_logic := '0';
    signal ser_i : std_logic := '0';
    signal path_data_i : std_logic_vector(path_data_length_c - 1 downto 0) := (others => '0');

    --Outputs
    signal ser_o : std_logic;
    signal srclk_o : std_logic;
    signal srclr_n_o : std_logic;
    --signal rclk_o : std_logic;
    signal rclr_n_o : std_logic;
    signal rdy_o : std_logic;
    signal cs_o : std_logic;

    -- Clock period definitions
    constant clk_i_period : time := 12.5 ns;
   
begin

    SPI_SR_SN74_tb : SPI_switch_controller
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
    
        start_seq_i         => start_seq_i,
    
        poci_i     => ser_i,
        pico_o     => ser_o,
        path_data_i => path_data_i,
        sck_o     => srclk_o,
        srclr_n_o      => srclr_n_o,
        --rclk_o      => rclk_o,
        rclr_n_o   => rclr_n_o,
        rdy_o   => rdy_o,
        cs_o   => cs_o
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
        wait for 50 ns;
        reset_i <= '0';
        wait;
   end process;
   
-- Signal process
    signal_proc: process
    begin
        path_data_i <= "101010111010101110101011";
        
        start_seq_i <= '0';

        --init measure
        wait for 100 ns;

        start_seq_i <= '1';
        wait for clk_i_period;

        start_seq_i <= '0';
        wait for 1200 ns;

        path_data_i <= "101010111010101110101011";

        start_seq_i <= '1';

        wait for clk_i_period;

        wait for 1200 ns;

        wait;
        
    end process;

end Behavioral;
