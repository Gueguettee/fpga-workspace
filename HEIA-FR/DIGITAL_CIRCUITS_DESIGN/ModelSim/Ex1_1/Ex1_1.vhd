library ieee;
use ieee.std_logic_1164.all;


entity ent is
    port
    (
        a_i, b_i, c_i : in std_logic;

        y1_o, y2_o : out std_logic
    );
end entity ent;


architecture arch of ent is

    signal s : std_logic;

    begin

        s <= a_i and b_i and c_i;

        y1_o <= a_i and b_i;
        y2_o <= (not b_i) or s;

end architecture arch;
