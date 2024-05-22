----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: Daniel Oberson
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    data_mem - Behavioral 
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

entity data_mem is
	port (
        clk_i : in std_logic;
        adr_i : in std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
        data_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
        data_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
        ce_i : in std_logic;
        rw_i : in std_logic
	);
end data_mem;

architecture synt of data_mem is

    --for development with an array of 16 data
	--type data_mem_type is array(15 downto 0) of std_logic_vector(7 downto 0); 
	type data_mem_type is array(2047 downto 0) of std_logic_vector(cDATA_SIZE-1 downto 0);
	--data memory
	signal data_mem_s : data_mem_type := ( 
		0 => "00000011", 
		1 => "00000101",
		2 => "00000011",
		3 => "00000010",
		others => "00000000"
	);
	
begin
	
	process (clk_i)
	begin
		if falling_edge(clk_i) then
			if ce_i='1' then
				if rw_i=cWRITE then
					data_mem_s(to_integer(unsigned(adr_i))) <= data_i;
				else
            	   data_o <= data_mem_s(to_integer(unsigned(adr_i)));
	           end if;
    		end if;
		end if;
	end process;
	
end synt;