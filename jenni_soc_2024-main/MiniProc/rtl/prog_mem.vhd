----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    prog_mem - Behavioral 
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

entity prog_mem is
	port (
        clk_i : in std_logic;
        adr_i : in std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
        data_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
        data_o : out std_logic_vector(cINSTR_SIZE-1 downto 0);
        ce_i : in std_logic;
        rw_i : in std_logic
	);
end prog_mem;

architecture Behavioral of prog_mem is

	type prog_mem_type is array(1023 downto 0) of std_logic_vector(cINSTR_SIZE-1 downto 0);
    
	--program memory   
	signal prog_mem_s : prog_mem_type := ( --    short program:
		0  => "0001100000000011",	--       LOAD  R3,M[3]
		1  => "1001100000000000",	--       DEC R3
		2  => "1011100000000000",	--       EQL0 R3
		3  => "1110000000000010",   --       JMPC LOOP2
        4  => "1100011111111101",   --       JMP LOOP1
        5  => "0001000000000010",	--       LOAD R2,M[2]
        6  => "0101110000000000",	--       CPY R3,R2
        7  => "0011100000000011",	--       STORE R3,M[3]
        8  => "0000000000000011",	--       LOAD R0,M[3]
        9  => "0000100000000001",	--       LOAD R1,M[1]
        10 => "0110110110000000",	--       MAC R1,R2,R3
        11 => "0010100000000001",   --       STORE R1,M[1]
        12 => "0000000000000001",   --       LOAD R0,M[1]
        13 => "1001000000000000",	--       DEC R2
        14 => "1011000000000000",	--       EQL0 R2
        15 => "1110000000000010",	--       JMPC LOOP4
        16 => "1100011111111101",   --       JMP LOOP3
        17 => "0110001110000000",	--       MAC R0,R1,R3
        18 => "1100000000000000",	--       JMP LOOP5
		others => "0000000000000000"
	);
	
begin
	
    process (clk_i)
    begin
        if falling_edge(clk_i) then
            if ce_i='1' then
                if rw_i=cWRITE then
                    prog_mem_s(to_integer(unsigned(adr_i))) <= data_i;
                else
                    data_o <= prog_mem_s(to_integer(unsigned(adr_i)));
               end if;
            end if;
        end if;
    end process;

end Behavioral;

