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

    signal freq_s : freq_t;

-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    freq_s <= ((to_integer(unsigned(freq_i)) * fstep_div + fmin_div));
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                freq_o <= fmin_div;
            else
                freq_o <= freq_s;
            end if;
        end if;
    end process;
    
end architecture mix;
