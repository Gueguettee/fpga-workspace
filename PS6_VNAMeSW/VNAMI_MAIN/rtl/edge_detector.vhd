library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
    port (
        clk_i                       : in  std_logic;
        reset_i                     : in  std_logic;
        input_i                     : in  std_logic;
        pulse_o                     : out std_logic
    );
end edge_detector;


architecture rtl of edge_detector is

--------------------------- SIGNALS ---------------------------

    signal r0_input                           : std_logic;
    signal r1_input                           : std_logic;

-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    rising_edge_detector : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i='1' then
                r0_input           <= '0';
                r1_input           <= '0';
            else
                r0_input           <= input_i;
                r1_input           <= r0_input;
            end if;
        end if;
        
    end process;
    
    pulse_o     <= not r1_input and r0_input;
    
    
end rtl;