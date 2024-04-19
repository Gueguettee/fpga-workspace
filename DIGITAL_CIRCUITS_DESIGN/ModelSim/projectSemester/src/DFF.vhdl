library ieee;
use ieee.std_logic_1164.all;

entity DFF is
	port (
			D_i : in std_logic;
			rst_i : in std_logic;
			clk_i : in std_logic;
			Q_o : out std_logic;
			Qn_o : out std_logic
	);
end entity DFF;

architecture mix of DFF is
	begin
		process (rst_i, clk_i)
			begin
				if rst_i = '0' then
					Q_o <= '0';
					Qn_o <= '1';
				elsif rising_edge(clk_i) then
					Q_o <= D_i;
					Qn_o <= not D_i;
				end if;
		end process;
end architecture mix;
