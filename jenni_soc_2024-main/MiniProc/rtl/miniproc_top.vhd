----------------------------------------------------------------------------------
-- Company: HEIA-FR 
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    miniproc_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity miniproc_top is
	port (
		clk_i   : in std_logic;
		reset_i : in std_logic
	);
end miniproc_top;

architecture Behavioral of miniproc_top is

	--Signals
	signal addr_bus_p_s : std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
    signal data_bus_p_out_s : std_logic_vector(cINSTR_SIZE-1 downto 0);
    signal data_bus_p_in_s : std_logic_vector(cINSTR_SIZE-1 downto 0);
    
	signal addr_bus_d_s : std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
    signal data_bus_d_mem2proc_s : std_logic_vector(cDATA_SIZE-1 downto 0);
    signal data_bus_d_proc2mem_s : std_logic_vector(cDATA_SIZE-1 downto 0);
	signal rw_s : std_logic;
	
begin

    --Values to '0' for the input data of progmem
    data_bus_p_in_s <= (others=>'0');
    
	--Components
	cmp_proc : proc 
	port map (
		clk_i   => clk_i,
		reset_i => reset_i,
		
		addr_bus_p_o => addr_bus_p_s,
		data_bus_p_i => data_bus_p_out_s,
		
		addr_bus_d_o  => addr_bus_d_s,
		data_bus_d_i  => data_bus_d_mem2proc_s,
        data_bus_d_o  => data_bus_d_proc2mem_s,
		
		rwmem_o  => rw_s
	);
		
	cmp_data_mem : data_mem
	port map (
		clk_i => clk_i,
		adr_i => addr_bus_d_s,
        data_i => data_bus_d_proc2mem_s,
        data_o => data_bus_d_mem2proc_s,
		ce_i => '1',
		rw_i => rw_s
	);
	
	cmp_prog_mem : prog_mem
	port map (
		clk_i => clk_i,
		adr_i => addr_bus_p_s,
        data_i => data_bus_p_in_s,
        data_o => data_bus_p_out_s,
		ce_i => '1',
		rw_i => '1'
	);
	
end Behavioral;


