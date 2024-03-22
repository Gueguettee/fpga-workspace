library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.SD_filter_pkg.all;

entity IIR_LP1o is
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_IIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC
    );
end entity;

architecture Behavioral of IIR_LP1o is

    signal bitstream_reg : STD_LOGIC_VECTOR (N-1 downto 0);
    signal last_bitstream_s : STD_LOGIC_VECTOR(1 downto 0);

    signal add_sub_s : signed(1 downto 0);
    signal last_bistream_i_s : STD_LOGIC_VECTOR(1 downto 0);

    signal sum : signed(B downto 0);
    signal new_sum : signed(B downto 0);

    signal filtered_o_s : std_logic_vector(B downto 0);

begin

    first_reg: DFF port map(
        D_i => bitstream_i,
        rst_i => reset_i,
        clk_i => clock_i,
        Q_o => bitstream_reg(N-1)
    );

    shift_reg: for i in N-2 downto 0 generate
    begin
        reg: DFF port map(
            D_i => bitstream_reg(i+1),
            rst_i => reset_i,
            clk_i => clock_i,
            Q_o => bitstream_reg(i)
        );
    end generate;
    
    last_bitstream_s(1) <= '0';
    last_bitstream_s(0) <= bitstream_reg(0);
    add_sub_s <= signed(last_bistream_i_s) - signed(last_bitstream_s);
    new_sum <= sum + add_sub_s;
    
    filtered_o_s <= std_logic_vector(new_sum);
    filtered_o <= filtered_o_s(B-1 downto 0);

    process(clock_i, reset_i)
    begin
        if reset_i = '1' then
            sum <= (others => '0');
            last_bistream_i_s <= (others => '0');
        elsif rising_edge(clock_i) then
            sum <= new_sum;
            last_bistream_i_s(0) <= bitstream_i;
        end if;
    end process;

end architecture;