----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:34:41 03/20/2016 
-- Design Name: 
-- Module Name:    mult - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

library work;
use work.myfilter_pkg.all;

entity mult is
	Generic (
		gFILTER_DATA_LENGTH : integer := 16
		);
	Port ( 
		clk_i   : in  std_logic;
		reset_i : in  std_logic;
		
		b_coeff_i : in std_logic_vector (cFILTER_DATA_LENGTH-1 downto 0);
		signal_i : in std_logic_vector (cFILTER_DATA_LENGTH-1 downto 0);
		start_i : in std_logic;

		signal_o : out std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0)
	);
end mult;

architecture Behavioral of mult is

	--Signal
	signal intern_signal_s : signed(2*cFILTER_DATA_LENGTH-1 downto 0);

begin

	process (clk_i)
	begin
		if rising_edge(clk_i) then
			if (reset_i='1') then
				intern_signal_s<=(others=>'0');
			else
				if (start_i='1') then
					intern_signal_s<=signed(signal_i)*signed(b_coeff_i);
				end if;
			end if;
		end if; 
	end process;
	
	signal_o<=std_logic_vector(signed(intern_signal_s(2*cFILTER_DATA_LENGTH-2 downto cFILTER_DATA_LENGTH-1)));
	--signal_o<=std_logic_vector(signed(intern_signal_s));

end Behavioral;

