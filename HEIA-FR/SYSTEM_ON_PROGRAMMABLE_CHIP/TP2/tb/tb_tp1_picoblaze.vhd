--------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
--
-- Create Date:   08:46:40 26/02/2024 
-- Design Name:   
-- Module Name:   ~\SOC\MiniProc\MiniProc\testbench\TB_miniproc.vhd
-- Project Name:  miniproc
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: miniproc_top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.tp1_picoblaze_pkg.all;
 
ENTITY tb_tp1_picoblaze IS
END tb_tp1_picoblaze;
 
ARCHITECTURE behavior OF tb_tp1_picoblaze IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    
    --Inputs
    signal tb_clk_i_s : std_logic;
    signal tb_reset_i_s  :std_logic;
    signal port1_i_s : std_logic_vector(cIN_NB-1 downto 0);
    signal rx_i_s : std_logic;
    
    --Outputs
    signal port1_o_s : std_logic_vector(cOUT_NB-1 downto 0);
    signal tx_o_s : std_logic;
    
    -- Clock period definitions
    constant cCLK_PERIOD : time := 10 ns;
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
    miniproc: tp1_picoblaze_top
        port map (
            clk_i => tb_clk_i_s,
            reset_i => tb_reset_i_s,
            
            port1_i => port1_i_s,
            rx_i => rx_i_s,

            port1_o => port1_o_s,
            tx_o => tx_o_s
        );
    
    -- Clock process definitions
    clk : process
        begin
            tb_clk_i_s <= '0';
            wait for cCLK_PERIOD / 2;
            tb_clk_i_s <= '1';
            wait for cCLK_PERIOD / 2;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        tb_reset_i_s <= '0';
        wait for 20 ns;
        tb_reset_i_s <= '1';
        wait for 3 * cCLK_PERIOD;
        tb_reset_i_s <= '0';
        wait;
    end process;
    
END;
