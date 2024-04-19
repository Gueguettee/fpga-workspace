library ieee;
use ieee.std_logic_1164.all;


component en_res is 
    port
    (
        in1 : in std_logic_vector(8 downto 0);
        en : in std_logic;
        res : out std_logic_vector(8 downto 0);
    );
end component;
