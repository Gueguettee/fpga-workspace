library ieee;
use ieee.std_logic_1164.all;


entity ADD_TL is
    port
    (
        en_i = in std_logic;
        a_i = in std_logic_vector(7 downto 0);
        b_i = in std_logic_vector(7 downto 0);
        y_o = out std_logic_vector(8 downto 0);
    );
end entity ADD_TL;

architecture arch of ent is

    signal res_s;

    comp_1:add2
        port map
        (
            in_a => a_i,
            in_b => b_i,
            res => res_s
        );

    comp_2:en_res
        port map
        (
            in1 <= res_s
        );

    begin
        ...;

end architecture arch;
