library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.main_control_pkg.all;

entity sp_RAM is
    generic(
        DATA_LENGTH         : integer := 8;
        ADDR_LENGTH         : integer := 8
    );
    port
    (
        clk_i       :in  std_logic;
        rst_i       :in  std_logic;
        wr_en_i     :in  std_logic;
        rd_en_i     :in  std_logic;
        wr_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
        rd_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
        data_i      :in  std_logic_vector(DATA_LENGTH - 1 downto 0);
        data_o      :out  std_logic_vector(DATA_LENGTH - 1 downto 0)
    );
end entity sp_RAM;

architecture mix of sp_RAM is

    type RAM_data_type is array (1 to 2**ADDR_LENGTH) of std_logic_vector(DATA_LENGTH - 1 downto 0);

    signal RAM_data_s :RAM_data_type;

    attribute ram_style : string;
    attribute ram_style of RAM_data_s : signal is "block"; -- or "distributed"

    begin
    WR_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if wr_en_i = '1' then
            RAM_data_s(to_integer(unsigned(wr_addr_i)) + 1) <= data_i;
            end if;
        end if;
    end process;
    
    RD_reg: process(clk_i, rst_i)
    begin
        if rst_i = '1' then
        data_o <= (others=>'0');
        elsif rising_edge(clk_i) then
        if rd_en_i = '1' then
            data_o <= RAM_data_s(to_integer(unsigned(rd_addr_i)) + 1);
        end if;
        end if;
    end process;
end architecture mix;
    