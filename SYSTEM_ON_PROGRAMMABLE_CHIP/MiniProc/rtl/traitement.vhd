----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    traitement_bloc - Behavioral 
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

entity traitement is
	port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        sela_i   : in std_logic;
        rwreg_i  : in std_logic;
        opcode_alu_i : in std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
        inalu_i  : in std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
        inreg_i  : in std_logic;
        ldres_i  : in std_logic;
        ldflg_i  : in std_logic;
        ldpc_i   : in std_logic;
        selpc_i  : in std_logic;
        ldir_i   : in std_logic;
        
        flag_o   : out std_logic;
        opcode_o : out std_logic_vector(2 downto 0);
        
        addr_bus_p_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
        data_bus_p_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
        
        addr_bus_d_o  : out std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
        data_mem_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
        data_mem_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
	);
end traitement;

architecture Behavioral of traitement is

	--Signals
	signal ir_s : std_logic_vector(cINSTR_SIZE-1 downto 0);
	signal pc_s : std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
	signal alu_s : std_logic_vector(cDATA_SIZE-1 downto 0);
	signal rega_s, regb_s, regc_s : std_logic_vector(cDATA_SIZE-1 downto 0);
	signal data_in_reg_s : std_logic_vector(cDATA_SIZE-1 downto 0);
    signal opcode_s : std_logic_vector(cOP_CODE_SIZE-1 downto 0);

begin

	--Buses and signals connections
	addr_bus_d_o <= ir_s(cDATA_ADR_SIZE-1 downto 0);
	addr_bus_p_o <= pc_s;
	opcode_s <= ir_s(15 downto 13); 
	data_mem_o <= alu_s;
    opcode_o <= opcode_s;
	

	--Components
	cmp_registres : registers 
	port map (
		clk_i => clk_i, 
		reset_i => reset_i, 
		
		input_bus_i => data_in_reg_s, 
		
		a_o => rega_s,
		b_o => regb_s,
		c_o => regc_s,
		
		w_reg_i => ir_s(12 downto 11),
		reg2_i  => ir_s(10 downto 9),
		reg3_i  => ir_s(8 downto 7),
		
		rw_i    => rwreg_i,
		sela_i  => sela_i
	);
	
	cmp_alu : alu 
	port map (
		clk_i => clk_i, 
		reset_i => reset_i, 
		
		inalu_i  => inalu_i,
		opcode_alu_i  => opcode_alu_i,
		ldres_i  => ldres_i,
		ldflg_i  => ldflg_i,
		
		a_i  => rega_s,
		b_i  => regb_s,
		c_i  => regc_s,

		flag_o   => flag_o,
		result_o => alu_s
	);

	cmp_write_back : write_back
	port map (
        data_mem_i => data_mem_i,
        data_from_alu_i => alu_s,
        
        inreg_i => inreg_i,
        
        data2reg_o => data_in_reg_s
	);

	cmp_pc : pc 
	port map (
		clk_i   => clk_i, 
		reset_i => reset_i, 
		
		ldpc_i  => ldpc_i, 
		selpc_i => selpc_i, 
		
		jmp_i => ir_s(cPROGR_ADR_SIZE downto 0), 
		pc_o => pc_s
	);
	
	cmp_ir : ir
	port map (
		clk_i  => clk_i, 
		reset_i => reset_i, 

		ldir_i => ldir_i, 
		
		ir_i => data_bus_p_i, 
		ir_o => ir_s
	);
	
end Behavioral;

