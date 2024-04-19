library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;

entity data_flow is
    port(
        en_i     : in std_logic;
        rst_i    : in std_logic;
        clk_i    : in std_logic;
        
        shift_o  : out std_logic;
        enSIPO_o : out std_logic;
        enPISO_o : out std_logic
    );
end entity;

architecture mix of data_flow is
    constant DATA_BUS_WIDTH_c : integer := 8;

    signal shift_s : std_logic;
    signal clk_and_en_s : std_logic;
    signal nClk_s : integer := 0;

    begin
        enSIPO_o <= en_i;
        enPISO_o <= en_i;

        shift_o <= shift_s;

        clk_and_en_s <= (clk_i and en_i);

        process(rst_i, clk_and_en_s)
        begin
            if (rst_i = '0') then
                shift_s <= '0';
                nClk_s <= DATA_BUS_WIDTH_c;
            elsif falling_edge(clk_and_en_s) then
                if(nClk_s + 1 >= DATA_BUS_WIDTH_c) then
                    shift_s <= '1';
                    nClk_s <= 0;
                else
                    shift_s <= '0';
                    nClk_s <= nClk_s + 1;
                end if;
            end if;
        end process;

end architecture;
