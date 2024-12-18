library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;


entity SIPO_shift_reg is 
	port
	(
		clk_i : in std_logic;
		rst_i : in std_logic;
		shift_i : in std_logic;
		en_i : in std_logic;
		data_i : in std_logic;
		data_o : out std_logic_vector(8-1 downto 0)
	);
end entity;

architecture mix of SIPO_shift_reg is 
	constant DATA_BUS_WIDTH_c : integer := 8;

	component DFF is
		port (
			D_i : in std_logic;
			rst_i : in std_logic;
			clk_i : in std_logic;
			Q_o : out std_logic;
			Qn_o : out std_logic
		);
	end component DFF;

	signal SIPO_data_s : std_logic_vector(DATA_BUS_WIDTH_c downto 0);

	signal clk_and_en_s : std_logic;
	signal shift_and_en_ns : std_logic;

	begin
		clk_and_en_s <= (clk_i and en_i);
		shift_and_en_ns <= not (shift_i and en_i);
		SIPO_data_s(0) <= data_i;
		
		SIPO: for i in DATA_BUS_WIDTH_c downto 1 generate
			begin
				SIPO_reg: DFF port map(
					D_i => SIPO_data_s(i-1),
					rst_i => rst_i,
					clk_i => clk_and_en_s,
					Q_o => SIPO_data_s(i)
				);
				memory_reg: DFF port map(
					D_i => SIPO_data_s(i),
					rst_i => rst_i,
					clk_i => shift_and_en_ns,
					Q_o => data_o(i-1)
				);
		end generate;

end architecture;
