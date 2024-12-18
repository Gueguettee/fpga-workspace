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

architecture Behavioral of DFF is
	begin
		process (rst_i, clk_i)
			begin
				if rising_edge(clk_i) then
				    if rst_i = '1' then
                        Q_o <= '0';
                        Qn_o <= '1';
                    else
                        Q_o <= D_i;
                        Qn_o <= not D_i;
                    end if;
				end if;
		end process;
end architecture Behavioral;
