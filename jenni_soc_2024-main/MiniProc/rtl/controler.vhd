----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer:       
-- 
-- Create Date:    08:46:40 26/02/2024 
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
		opcode_i : in std_logic_vector(cOP_CODE_SIZE-1 downto 0);
		
		rwdmem_o : out std_logic;
		
		sela_o   : out std_logic;
		rwreg_o  : out std_logic;
		opcode_alu_o : out std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
        inalu_o  : out std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
		inreg_o  : out std_logic;
		ldres_o  : out std_logic;
		ldflg_o  : out std_logic;
		ldpc_o   : out std_logic;
		selpc_o  : out std_logic;
		ldir_o   : out std_logic
	);
end controler;

architecture Behavioral of controler is

	type ctrl_state is(
		FETCH_D, -- 'D' for Default
        DECOD_D,
        EXEC_D,
		EXEC_CPY,
        EXEC_JMPC,
		MEM_ACCESS_D,
        MEM_ACCESS_DEC,
        MEM_ACCESS_MAC,
        MEM_ACCESS_EQL0,
        MEM_ACCESS_JMP,
        WRITE_BACK_D,
		WRITE_BACK_LOAD,
        WRITE_BACK_STORE
	);
	
	signal current_state_s : ctrl_state := FETCH_D;
	signal next_state_s : ctrl_state;

    signal op_code_s : std_logic_vector(cOP_CODE_SIZE-1 downto 0);

begin

    --stock opcode value

	next_state_logic: process(current_state_s, opcode_i, op_code_s, flag_i)
	begin
		case current_state_s is
			when FETCH_D =>
				next_state_s <= DECOD_D;
			when DECOD_D =>
                next_state_s <= EXEC_D;
                op_code_s <= opcode_i;
                if opcode_i = cCPY_INSTR then
                    next_state_s <= EXEC_CPY;
                elsif opcode_i = cJMPC_INSTR then
                    next_state_s <= EXEC_JMPC;
                end if;
			when EXEC_D =>
				next_state_s <= MEM_ACCESS_D;
                if op_code_s = cMAC_INSTR then
                    next_state_s <= MEM_ACCESS_MAC;
                elsif op_code_s = cEQL0_INSTR then
                    next_state_s <= MEM_ACCESS_EQL0;
                elsif op_code_s = cJMP_INSTR then
                    next_state_s <= MEM_ACCESS_JMP;
                elsif op_code_s = cDEC_INSTR then
                    next_state_s <= MEM_ACCESS_DEC;
                end if;
            when EXEC_CPY =>
				next_state_s <= MEM_ACCESS_D;
            when EXEC_JMPC =>
				next_state_s <= MEM_ACCESS_D;
                if flag_i = '1' then
                    next_state_s <= MEM_ACCESS_JMP;
                end if;
			when MEM_ACCESS_D =>
                next_state_s <= WRITE_BACK_D;
                if op_code_s = cLOAD_INSTR then
                    next_state_s <= WRITE_BACK_LOAD;
                elsif op_code_s = cSTORE_INSTR then
                    next_state_s <= WRITE_BACK_STORE;
                end if;
            when MEM_ACCESS_DEC =>
                next_state_s <= WRITE_BACK_D;
            when MEM_ACCESS_MAC =>
                next_state_s <= WRITE_BACK_D;
            when MEM_ACCESS_EQL0 =>
                next_state_s <= WRITE_BACK_D;
            when MEM_ACCESS_JMP =>
                next_state_s <= WRITE_BACK_D;
			when WRITE_BACK_D =>
				next_state_s <= FETCH_D;
            when WRITE_BACK_LOAD =>
				next_state_s <= FETCH_D;
            when WRITE_BACK_STORE =>
				next_state_s <= FETCH_D;
            when others => null;
		end case;
	end process;

	current_state: process(clk_i, reset_i)
	begin
		if reset_i = cRESET_ON then
			current_state_s <= FETCH_D;
		elsif rising_edge(clk_i) then
			current_state_s <= next_state_s;
		end if;
	end process;

	output_logic: process(current_state_s)
	begin
		-- default value
		rwdmem_o <= cREAD;
		opcode_alu_o <= cDEFAULT_OP;
		sela_o   <= '0';
		rwreg_o  <= cREAD;
		inalu_o  <= (others => '0');
		inreg_o  <= '0';
		ldres_o  <= '0';
		ldflg_o  <= '0';
		ldpc_o   <= '0';
		selpc_o  <= '0';
		ldir_o   <= '0';

		case current_state_s is
			when FETCH_D =>
				rwdmem_o <= cREAD;
				ldir_o   <= '1';
			when DECOD_D =>
				null;
			when EXEC_D =>
                rwreg_o  <= cREAD;
            when EXEC_CPY =>
                rwreg_o  <= cREAD;
                sela_o <= '1';
            when EXEC_JMPC =>
                rwreg_o  <= cREAD;
                ldflg_o <= '1';
			when MEM_ACCESS_D =>
                opcode_alu_o <= cDEFAULT_OP;
                ldres_o <= '1';
                ldpc_o   <= '1';
            when MEM_ACCESS_DEC =>
                opcode_alu_o <= cDEC_OP;
                ldres_o <= '1';
                ldpc_o   <= '1';
            when MEM_ACCESS_MAC =>
                opcode_alu_o <= cMAC_OP;
                ldres_o <= '1';
                inalu_o <= "11";
                ldpc_o   <= '1';
            when MEM_ACCESS_EQL0 =>
                opcode_alu_o <= cEQL0_OP;
                ldres_o <= '1';
                ldflg_o <= '1';
                ldpc_o   <= '1';
            when MEM_ACCESS_JMP =>
                opcode_alu_o <= cDEFAULT_OP;
                ldres_o <= '1';
                selpc_o <= '1';
                ldpc_o   <= '1';
			when WRITE_BACK_D =>
                inreg_o <= '1';
                rwreg_o  <= cWRITE;
            when WRITE_BACK_LOAD =>
                inreg_o <= '0';
                rwreg_o  <= cWRITE;
                rwdmem_o <= cREAD;
            when WRITE_BACK_STORE =>
                inreg_o <= '1';
                rwreg_o  <= cWRITE;
                rwdmem_o <= cWRITE;
            when others => null;
		end case;
	end process;

end Behavioral;

