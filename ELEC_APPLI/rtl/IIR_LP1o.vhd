library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.SD_filter_pkg.all;

entity IIR_LP1o is
    generic (
        d : integer := 7
    );
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_IIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC
    );
end entity;

architecture Behavioral of IIR_LP1o is

    signal first_level : STD_LOGIC_VECTOR (B_IIR*2-1 downto 0);
    signal first_level2 : STD_LOGIC_VECTOR (B_IIR*2-1 downto 0);
    signal second_level : STD_LOGIC_VECTOR (B_IIR*2-1 downto 0);
    signal second_level_shift : STD_LOGIC_VECTOR (B_IIR*2-1 downto 0);

begin

    first_level2(B_IIR*2-1-d downto 0) <= second_level_shift(B_IIR*2-1 downto d);
    first_level2(B_IIR*2-1 downto B_IIR*2-d) <= (others => '0');

    second_level <= std_logic_vector(unsigned(first_level) + unsigned(second_level_shift) - unsigned(first_level2));

    filtered_o(B_IIR-1 downto B_IIR-d) <= second_level(B_IIR*2-1 downto B_IIR*2-d);
    filtered_o(B_IIR-d-1 downto 0) <= (others => '0');

    process(clock_i, reset_i)
    begin
        if reset_i = '1' then
            second_level_shift <= (others => '0');
        elsif rising_edge(clock_i) then
            second_level_shift <= second_level;
        end if;
    end process;

    process(bitstream_i)
    begin
        if bitstream_i = '1' then
            first_level <= (others => '0');
        else
            first_level(B_IIR-d) <= '1';
            first_level(B_IIR*2-d-1 downto 0) <= (others => '0');
            first_level(B_IIR*2-1 downto B_IIR*2-d+1) <= (others => '0');
        end if;
    end process;

end architecture;
