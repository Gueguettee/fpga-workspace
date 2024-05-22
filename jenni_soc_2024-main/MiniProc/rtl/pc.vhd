----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    pc - Behavioral 
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

entity pc is
	port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        ldpc_i   : in std_logic;
        selpc_i  : in std_logic;
        
        jmp_i : in std_logic_vector(cPROGR_ADR_SIZE downto 0);
        pc_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0)
	);
end pc;

architecture Behavioral of pc is

	signal pc_o_s : std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
    signal pc_to_add_s : std_logic_vector(cPROGR_ADR_SIZE downto 0);
    signal pc_after_alu_s : std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
	
begin
    selpc: for i in cPROGR_ADR_SIZE downto 1 generate
            begin
                    selpc_reg: mux port map(
                            a_i => '0',
                            b_i => jmp_i(i),
                            sel_i => selpc_i,
                            z_o => pc_to_add_s(i)
                    );
    end generate;
    selpc_reg: mux port map(
            a_i => '1',
            b_i => jmp_i(0),
            sel_i => selpc_i,
            z_o => pc_to_add_s(0)
    );

    alu: pc_alu_sum port map(
            a_i => pc_o_s,
            b_i => pc_to_add_s,
            z_o => pc_after_alu_s
    );

    pc_o <= pc_o_s;

    pc_process: process(clk_i, reset_i)
    begin
        if reset_i = cRESET_ON then
            pc_o_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if ldpc_i = '1' then
                pc_o_s <= pc_after_alu_s;
            end if;
        end if;
    end process;

end Behavioral;

