library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity pc_alu_sum is
	port (
		a_i : in std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
		b_i : in std_logic_vector(cPROGR_ADR_SIZE downto 0);

		z_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0)
	);
end entity pc_alu_sum;

architecture rtl of pc_alu_sum is

	signal result_s : std_logic_vector(cPROGR_ADR_SIZE downto 0);

begin
	result_s <= std_logic_vector(signed('0' & a_i) + signed(b_i));
	z_o <= result_s(cPROGR_ADR_SIZE-1 downto 0);

end architecture rtl;
