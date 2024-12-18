library ieee;
use ieee.std_logic_1164.all;

entity MUX is
	port (
			A_i : in std_logic;
			B_i : in std_logic;
			S_i : in std_logic;
			Z_o : out std_logic
	);
end entity MUX;

architecture rtl of MUX is

	begin
        Z_o <=  A_i when S_i = '0' else
                B_i when S_i = '1' else
                '0';
        --Z_o <= ((not S_i) and A_i) or (S_i and B_i);

end architecture rtl;
