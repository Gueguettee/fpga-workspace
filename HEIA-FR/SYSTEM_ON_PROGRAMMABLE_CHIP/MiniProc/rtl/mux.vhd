library ieee;
use ieee.std_logic_1164.all;

entity mux is
	port (
			a_i : in std_logic;
			b_i : in std_logic;
			sel_i : in std_logic;
			z_o : out std_logic
	);
end entity mux;

architecture rtl of mux is

begin
    z_o <=  a_i when sel_i = '0' else
            b_i when sel_i = '1' else
            '0';

end architecture rtl;
