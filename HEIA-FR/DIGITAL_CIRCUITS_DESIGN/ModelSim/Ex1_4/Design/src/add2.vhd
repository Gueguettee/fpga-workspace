library ieee;
use ieee.std_logic_1164.all;


component add2 is 
    port
    (
        in_a : in std_logic_vector(7 downto 0);
        in_b : in std_logic_vector(7 downto 0);
        res : out std_logic_vector(8 downto 0);
    );
end component;
