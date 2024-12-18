library ieee;
use ieee.std_logic_1164.all;

entity en_res is
		port (
			in_i : in std_logic_vector(2 downto 0);
			out_o : out std_logic_vector(2 downto 0);
			en_i : in std_logic
		);
end entity;


architecture rtl of en_res is
	
	begin
	
	out_o <= in_i when en_i = '1' else
		"000";
	
end architecture rtl;