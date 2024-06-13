----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer:       
-- 
-- Create Date:    10:56:31 07/02/2022
-- Design Name: 
-- Module Name:    controler - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity controler is
	port (
		clk_i   : in std_logic;
		reset_i : in std_logic;
		
		flag_i   : in std_logic;
		opcode_i : in std_logic_vector(2 downto 0);
		
		rwdmem_o : out std_logic;
		
		sela_o  : out std_logic;
		rwreg_o : out std_logic;
		opalu_o : out std_logic;
		inalu_o : out std_logic;
		inreg_o : out std_logic;
		ldres_o : out std_logic;
		ldflg_o : out std_logic;
		ldpc_o  : out std_logic;
		selpc_o : out std_logic;
		ldir_o  : out std_logic
	);
end controler;

architecture Behavioral of controler is

	type ctrl_state is(
		FETCH,
		DECOD,
		EXEC,
		MEM_AC,
		WRITE_BACK
	);

	--Signal
	signal state_s : ctrl_state;

begin

	--Controler - State machine with one process
	process (clk_i) 
	begin
		if rising_edge(clk_i) then 
            if (reset_i='1') then
				state_s  <= FETCH;
				rwdmem_o <= cREAD;
				sela_o  <= '0';
				rwreg_o <= cREAD;
				opalu_o <= '0';
				inalu_o <= '0';
				inreg_o <= '0';
				ldres_o <= '0';
				ldflg_o <= '0';
				ldpc_o  <= '0';
				selpc_o <= '0';
				ldir_o  <= '0';
			else
				--Default value
				rwdmem_o <= cREAD;
				sela_o  <= '0';
				rwreg_o <= cREAD;
				opalu_o <= '0';
				inalu_o <= '0';
				inreg_o <= '0';
				ldres_o <= '0';
				ldflg_o <= '0';
				ldpc_o  <= '0';
				selpc_o <= '0';
				ldir_o  <= '0';
				
				case state_s is

					when FETCH =>
						state_s  <= DECOD;
						ldir_o  <= '1';
						
					when DECOD =>
						state_s <= EXEC;

					when EXEC =>
						state_s <= MEM_AC;
						if    (opcode_i=cLOAD_INSTR)  then
							
						elsif (opcode_i=cSTORE_INSTR) then
							sela_o  <= '1';
							ldres_o <= '1';
							
						elsif (opcode_i=cCPY_INSTR)  then
							ldres_o <= '1';
						
						elsif (opcode_i=cSUB_INSTR)   then
							opalu_o <= '1';
							inalu_o <= '1';
							ldres_o <= '1';
							
						elsif (opcode_i=cADD_INSTR)   then
							inalu_o <= '1';
							ldres_o <= '1';
							
						elsif (opcode_i=cEQL_INSTR)   then
							opalu_o <= '1';
							inalu_o <= '1';
							ldres_o <= '1';
							ldflg_o <= '1';
						
						elsif (opcode_i=cJMPC_INSTR)    then
							if (flag_i='1') then
								selpc_o <= '1';
							end if;
						
						elsif (opcode_i=cJMP_INSTR)   then
							selpc_o <= '1';
						
						end if;
						ldpc_o  <= '1';
						
					when MEM_AC =>
						state_s <= WRITE_BACK;
						if    (opcode_i=cLOAD_INSTR) then
							sela_o  <= '1';
							rwreg_o <= cWRITE;
							
						elsif (opcode_i=cSTORE_INSTR) then
							rwdmem_o <= cWRITE;
						end if;
						
					when WRITE_BACK =>
						state_s <= FETCH;			
						if (opcode_i=cCPY_INSTR) or 
							(opcode_i=cADD_INSTR)  or 
							(opcode_i=cSUB_INSTR)  then
							inreg_o <= '1';
							rwreg_o <= cWRITE;
						end if;
						
				end case;
			end if;
		end if;
	end process;

end Behavioral;

