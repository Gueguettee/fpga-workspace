library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;


entity PISO_shift_reg is
	port
	(
		clk_i : in std_logic;
		rst_i : in std_logic;
		shift_i : in std_logic;
		en_i : in std_logic;
		data_i : in std_logic_vector(8-1 downto 0);
		data_o : out std_logic
	);
end entity;

architecture mix of PISO_shift_reg is 

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

	component MUX is
		port (
			A_i : in std_logic;
			B_i : in std_logic;
			S_i : in std_logic;
			Z_o : out std_logic
		);
	end component MUX;

	signal PISO_data_after_mux_s : std_logic_vector(DATA_BUS_WIDTH_c-1 downto 0);
	signal PISO_data_before_mux_s : std_logic_vector(DATA_BUS_WIDTH_c downto 0);
	
	signal shift_and_en_ns : std_logic;
	signal clk_and_en_s: std_logic;
	
	begin
		PISO_data_before_mux_s(0) <= '0';
		shift_and_en_ns <= (not (shift_i and en_i));
		clk_and_en_s <= (clk_i and en_i);
		data_o <= PISO_data_before_mux_s(DATA_BUS_WIDTH_c);

		PISO: for i in DATA_BUS_WIDTH_c-1 downto 0 generate
			begin
				mux_reg: MUX port map(
					A_i => data_i(i),
					B_i => PISO_data_before_mux_s(i),
					S_i => shift_and_en_ns,
					Z_o => PISO_data_after_mux_s(i)
				);
				PISO_reg: DFF port map(
					D_i => PISO_data_after_mux_s(i),
					rst_i => rst_i,
					clk_i => clk_and_en_s,
					Q_o => PISO_data_before_mux_s(i+1)
				);
		end generate;

end architecture;
