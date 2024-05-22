----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    proc - Behavioral 
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

entity proc is
	port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        addr_bus_p_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
        data_bus_p_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
        
        addr_bus_d_o  : out std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
        data_bus_d_i  : in std_logic_vector(cDATA_SIZE-1 downto 0);
        data_bus_d_o  : out std_logic_vector(cDATA_SIZE-1 downto 0);
        
        rwmem_o  : out std_logic
	);
end proc;

architecture Behavioral of proc is

	--Signals
	signal rwreg_s, sela_s, inreg_s, ldres_s, ldflg_s, ldpc_s, selpc_s, ldir_s, flag_s : std_logic;
	signal inalu_s : std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
	signal opcode_s : std_logic_vector(cOP_CODE_SIZE-1 downto 0);
    signal opcode_alu_s : std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
	
begin

	cmp_controler : controler 
	port map (
		clk_i   => clk_i,
		reset_i => reset_i,
		
		flag_i   => flag_s,
		opcode_i => opcode_s,
		
		rwdmem_o  => rwmem_o,
		
		rwreg_o  => rwreg_s,
		sela_o  => sela_s,
		inreg_o  => inreg_s,
		opcode_alu_o  => opcode_alu_s,
		inalu_o  => inalu_s,
		ldflg_o  => ldflg_s,
		ldres_o  => ldres_s,
		ldpc_o   => ldpc_s,
		
		selpc_o => selpc_s,
		ldir_o  => ldir_s	
	);
	
	cmp_traitement : traitement 
	port map (
		clk_i   => clk_i,
		reset_i => reset_i,
		
		rwreg_i  => rwreg_s,
		sela_i   => sela_s,
		inreg_i  => inreg_s,
		opcode_alu_i  => opcode_alu_s,
		ldres_i  => ldres_s,
		ldflg_i  => ldflg_s,
		inalu_i  => inalu_s,
		ldpc_i   => ldpc_s,
		selpc_i  => selpc_s,
		ldir_i   => ldir_s,

		flag_o   => flag_s,
		opcode_o => opcode_s,
		
		addr_bus_p_o => addr_bus_p_o, 
		data_bus_p_i => data_bus_p_i,
		
		addr_bus_d_o => addr_bus_d_o, 
		data_mem_i => data_bus_d_i,
		data_mem_o => data_bus_d_o
	);

end Behavioral;