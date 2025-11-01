library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;

entity filter_bank_controller is
port (
    clk_i       : in std_logic;
    reset_i     : in std_logic;

    --intern inputs/outputs (from main control,etc)
    freq_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
    en_i        : in std_logic;
    throughput_i : in std_logic;

    --external input outputs(physical)
    V_o         : out std_logic_vector(filter_bank_controller_output_length_c-1 downto 0) --V4 (= MSB) to V1 (= LSB)
);
end entity filter_bank_controller;

architecture mix of filter_bank_controller is

    constant f2600   : integer := 2600/fmultiFpga;
    constant f3500   : integer := 3500/fmultiFpga;
    constant f4800   : integer := 4800/fmultiFpga;
    constant f6500   : integer := 6500/fmultiFpga;
    
    signal freq_s           : freq_t;

    signal V_s              : std_logic_vector(filter_bank_controller_length_c-1 downto 0);

begin

    freq_decode : freq_decoder
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_i,
        freq_o          => freq_s
    );

    V_o <= V_s(filter_bank_controller_output_length_c-1 downto 0);

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                V_s <= "1000";  --Terminate resistor
            else
                if throughput_i = '1' then
                    V_s <= "0100";  --Throughput mode
                elsif en_i = '1' then
                    if freq_s < f2600 then
                        V_s <= "0011";  --2600 MHz
                    elsif freq_s < f3500 then 
                        V_s <= "0101";  --3500 MHz
                    elsif freq_s < f4800 then
                        V_s <= "0001";  --4800 MHz
                    elsif freq_s < f6500 then
                        V_s <= "0110";  --6500 MHz
                    else
                        V_s <= "0010";  --9170 MHz
                    end if;
                else
                    V_s <= "1000";  --Terminate resistor
                end if;
            end if;
        end if;
    end process;
end architecture mix;
