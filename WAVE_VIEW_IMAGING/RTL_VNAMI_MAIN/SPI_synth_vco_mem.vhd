LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_synth_vco_mem is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        freq_i              : in std_logic_vector(freq_data_length_c-1 downto 0);
        rw_i                : in std_logic;

        vco_i               : in vco_t;

        vco_o               : out vco_t
	);
end entity SPI_synth_vco_mem;

architecture mix of SPI_synth_vco_mem is
    
--------------------------- SIGNALS ---------------------------
    
    type vco_arr_t is array (0 to n_freq-1) of vco_t;
    signal vco_arr_s : vco_arr_t;
  
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    write_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                -- Vivado cannot reset RAM, it will cause a inifinite linting design
                null;
            else
                if rw_i = '1' then
                    vco_arr_s(to_integer(unsigned(freq_i))) <= vco_i;
                end if;
            end if;
        end if;
    end process;

    read_proc : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                vco_o <= (others => (others => '0'));
            else
                vco_o <= vco_arr_s(to_integer(unsigned(freq_i)));
            end if;
        end if;
    end process;

end architecture mix;
