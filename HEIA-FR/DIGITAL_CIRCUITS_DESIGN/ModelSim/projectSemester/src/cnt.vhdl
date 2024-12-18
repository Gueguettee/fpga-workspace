library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;

entity cnt is
    port(
        rst_i: in std_logic;
        clk_i: in std_logic;
        cnt_finish_o: out std_logic
    );
end entity;

architecture mix of cnt is
    constant DATA_BUS_WIDTH_c : integer := 8;

    signal cnt_s : integer := 0;
    signal cnt_finish_s : std_logic;

    begin
        cnt_finish_o <= cnt_finish_s;

        reg: process(clk_i, rst_i)
        begin
            if (rst_i = '0') then
                cnt_s <= 0;
            else
                if rising_edge(clk_i) then
                    if (cnt_s + 1 >= DATA_BUS_WIDTH_c) then
                        cnt_finish_s <= '1';
                        cnt_s <= 0;
                    else
                        cnt_finish_s <= '0';
                        cnt_s <= cnt_s + 1;
                    end if;
                end if;
            end if;
        end process;
end architecture;
