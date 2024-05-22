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
use work.miniproc_pkg.all;
 
ENTITY TB_miniproc IS
END TB_miniproc;
 
ARCHITECTURE behavior OF TB_miniproc IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    
    --Inputs
    signal tb_clk_i_s : std_logic;
    signal tb_reset_i_s  :std_logic;
    
    -- Clock period definitions
    constant cCLK_PERIOD : time := 10 ns;
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
    miniproc: miniproc_top
        port map (
            clk_i => tb_clk_i_s,
            reset_i => tb_reset_i_s
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
        tb_reset_i_s <= cRESET_OFF;
        wait for 20 ns;
        tb_reset_i_s <= cRESET_ON;
        wait for 3 * cCLK_PERIOD;
        tb_reset_i_s <= cRESET_OFF;
        wait;
    end process;
    
END;
