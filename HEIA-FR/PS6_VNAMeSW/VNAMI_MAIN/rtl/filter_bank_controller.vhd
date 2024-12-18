library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;

entity filter_bank_controller is
port (
    clk_i : in std_logic;
    reset_i : in std_logic;

    --intern inputs/outputs (from main control,etc)
    freq_i : in std_logic_vector(freq_data_length_c - 1 downto 0);

    --external input outputs(physical)
    V_o : out std_logic_vector(filter_bank_controller_length_c-1 downto 0) --V4 (= MSB) to V1 (= LSB)
);
end entity filter_bank_controller;

architecture mix of filter_bank_controller is

    signal freq_s           : freq_t;

begin

    freq_decode : freq_decoder
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_i,
        freq_o          => freq_s
    );

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                V_o <= "0011";  --Thru
            else
                if freq_s = f200 then
                    V_o <= "0101";  --216 MHz
                elsif freq_s = f400 or freq_s = f600 then
                    V_o <= "0001";  --550 MHz
                elsif freq_s = f800 or freq_s = f1000 or freq_s = f1200 then 
                    V_o <= "0110";  --1094 MHz
                elsif freq_s = f1400 or freq_s = f1600 or freq_s = f1800 or freq_s = f2000 
                or freq_s = f2200 or freq_s = f2400 or freq_s = f2600 or freq_s = f2800 then
                    V_o <= "0010";  --2900 MHz
                elsif freq_s = f3000 or freq_s = f3200 or freq_s = f3400 or freq_s = f3600 
                or freq_s = f3800 or freq_s = f4000 or freq_s = f4200 or freq_s = f4400 
                or freq_s = f4600 or freq_s = f4800 or freq_s = f5000 or freq_s = f5200 
                or freq_s = f5400 or freq_s = f5600 or freq_s = f5800 or freq_s = f6000 then
                    V_o <= "0100";  --7090 MHz
                elsif freq_s = f6200 or freq_s = f6400 then
                    V_o <= "0011";  --Thru
                else
                    V_o <= "0011";  --Thru
                end if;
            end if;
        end if;
    end process;
end architecture mix;
