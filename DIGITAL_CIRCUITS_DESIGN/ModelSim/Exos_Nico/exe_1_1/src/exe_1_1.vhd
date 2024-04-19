library ieee;
use ieee.std_logic_1164.all;

entity ex1 is
	port
	(
		a_i : in std_logic;
		b_i : in std_logic;
		c_i : in std_logic;
		y1_o : out std_logic;
		y2_o : fout std_logic
	);
end entity ex1;

architecture rtl of ex1 is
	
	begin
	
	y1_o <= a_i and b_i;
	y2_o <= not(b_i) or (a_i and b_i and c_i);
	
end architecture rtl;


