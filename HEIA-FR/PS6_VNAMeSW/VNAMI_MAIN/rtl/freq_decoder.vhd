LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;


entity freq_decoder is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        freq_i              : in std_logic_vector(freq_data_length_c-1 downto 0);
        freq_o              : out freq_t
	);
end entity freq_decoder;

architecture mix of freq_decoder is
    
--------------------------- SIGNALS ---------------------------

-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------
    
    freq_o <= f400  when freq_i = "000001" else
              f600  when freq_i = "000010" else
              f800  when freq_i = "000011" else
              f1000 when freq_i = "000100" else
              f1200 when freq_i = "000101" else
              f1400 when freq_i = "000110" else
              f1600 when freq_i = "000111" else
              f1800 when freq_i = "001000" else
              f2000 when freq_i = "001001" else
              f2200 when freq_i = "001010" else
              f2400 when freq_i = "001011" else
              f2600 when freq_i = "001100" else
              f2800 when freq_i = "001101" else
              f3000 when freq_i = "001110" else
              f3200 when freq_i = "001111" else
              f3400 when freq_i = "010000" else
              f3600 when freq_i = "010001" else
              f3800 when freq_i = "010010" else
              f4000 when freq_i = "010011" else
              f4200 when freq_i = "010100" else
              f4400 when freq_i = "010101" else
              f4600 when freq_i = "010110" else
              f4800 when freq_i = "010111" else
              f5000 when freq_i = "011000" else
              f5200 when freq_i = "011001" else
              f5400 when freq_i = "011010" else
              f5600 when freq_i = "011011" else
              f5800 when freq_i = "011100" else
              f6000 when freq_i = "011101" else
              f6200 when freq_i = "011110" else
              f6400 when freq_i = "011111" else
              f200;
    
end architecture mix;
