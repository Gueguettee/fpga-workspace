library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.my_pkg.all;

entity TestBench_TL is
end TestBench_TL;

architecture mix of TestBench_TL is

    constant DATA_BUS_WIDTH_c : integer := 8;

    signal tb_en_i : std_logic;
    signal tb_rst_i : std_logic;
    signal tb_clk_i : std_logic;
    signal tb_clk_pll_o : std_logic;
    signal tb_sw_i : std_logic_vector(DATA_BUS_WIDTH_c - 1 downto 0);
    signal tb_led_o : std_logic_vector(DATA_BUS_WIDTH_c - 1 downto 0);
    signal tb_ser_o : std_logic;
    signal tb_ser_i : std_logic;

    signal send_data_s : std_logic := '0';

    component TL
        port (
            en_i : in std_logic;
            rst_i : in std_logic;
            clk_i : in std_logic;
            clk_pll_o : out std_logic;
            sw_i : in std_logic_vector(DATA_BUS_WIDTH_c - 1 downto 0);
            led_o : out std_logic_vector(DATA_BUS_WIDTH_c - 1 downto 0);
            ser_o : out std_logic;
            ser_i : in std_logic
        );
    end component;

    begin

        dut : TL
            port map(
                en_i => tb_en_i,
                rst_i => tb_rst_i,
                clk_i => tb_clk_i,
                clk_pll_o => tb_clk_pll_o,
                sw_i => tb_sw_i,
                led_o => tb_led_o,
                ser_o => tb_ser_o,
                ser_i => tb_ser_i
            );

        rst : process
            begin
                tb_rst_i <= '1';
                wait for 105 ns;
                tb_rst_i <= '0';
                wait;
        end process;

        enable : process
            begin 
                tb_en_i <= '0';
                wait for 15000 ns;
                tb_en_i <= '1';
                wait;
        end process;

        clk : process
            begin
                tb_clk_i <= '0';
                wait for 10 ns;
                tb_clk_i <= '1';
                wait for 10 ns;
        end process;
        
        data_in : process(tb_clk_pll_o, tb_rst_i)
            begin
                if tb_rst_i = '1' then
                    tb_sw_i <= (others=>'0');
                elsif rising_edge(tb_clk_pll_o) then
                    if tb_en_i = '1' then
                        if send_data_s = '1' then
                            if tb_sw_i < "11111111" then
                                tb_sw_i <= std_logic_vector(unsigned(tb_sw_i) + 1);
                            else
                                tb_sw_i <= (others=>'0');
                            end if;
                        else
                            send_data_s <= '1';
                        end if;
                    end if;
                end if;
        end process;

        data_out : process(tb_clk_pll_o, tb_rst_i)
        begin
            if tb_rst_i = '1' then
                
            elsif falling_edge(tb_clk_pll_o) then
                if tb_en_i = '1' then
                    if tb_led_o /= tb_sw_i then
                        --report "test failed" severity error;
                    end if;
                end if;
            end if;
        end process;

end architecture mix;

