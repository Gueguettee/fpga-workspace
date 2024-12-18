LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.SPI_synth_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity SPI_synth_LMX2572 is
    generic(
        SPI_CLK_DIVIDER     : integer := 10;    --minimum 2
        ADDR_LENGTH         : integer := 7;
        DATA_LENGTH         : integer := 16);
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        
        RW_i                : in std_logic; --0 is write, 1 is read
        addr_i              : in std_logic_vector(ADDR_LENGTH-1 downto 0);
        data_i              : in std_logic_vector(DATA_LENGTH-1 downto 0);
        data_o              : out std_logic_vector(DATA_LENGTH-1 downto 0);
        
        MUXout_i            : in std_logic;
        SCK_o               : out std_logic;
        SDI_o               : out std_logic;
        CSB_o               : out std_logic;
        CE_o                : out std_logic;
        
        rdy_o               : out std_logic
	);
end entity SPI_synth_LMX2572;

architecture mix of SPI_synth_LMX2572 is
    
--------------------------- SIGNALS ---------------------------
    
    --constant TOTAL_LENGTH   : integer := ADDR_LENGTH + DATA_LENGTH + 1;
    
    signal RW_counter_s     : integer range 1 downto 0;
    signal addr_counter_s   : integer range addr_i'left+1 downto 0;
    signal data_counter_s   : integer range data_i'left+1 downto 0;
    signal clk_counter_s    : integer range 0 to SPI_CLK_DIVIDER;
    
    signal RW_s             : std_logic;
    signal addr_s           : std_logic_vector(addr_i'left downto 0);
    signal data_s           : std_logic_vector(data_i'left downto 0);
    signal MUXout_s         : std_logic;
    
    type spi_state_t is (
        IDLE,
        RW,
        ADDR,
        WRITE,
        READ,
        END_RW);
    signal spi_state_s, next_spi_state_s : spi_state_t;
    
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    next_spi_state: process(spi_state_s, clk_counter_s, start_i, RW_i, RW_s, addr_i, addr_s, data_i, data_s, MUXout_i, RW_counter_s, addr_counter_s, data_counter_s, MUXout_s)
    begin
        next_spi_state_s <= spi_state_s;

        case spi_state_s is
            when IDLE =>
                if start_i = '1' then
                    next_spi_state_s <= RW;
                end if;
            when RW =>
                if clk_counter_s = 0 then
                    next_spi_state_s <= ADDR;
                end if;
            when ADDR =>
                if clk_counter_s = 0 then
                    if addr_counter_s = 0 then
                        if RW_s = RW_WRITE then
                            next_spi_state_s <= WRITE;
                        else
                            next_spi_state_s <= READ;
                        end if;
                    end if;
                end if;
            when WRITE =>
                if clk_counter_s = 0 then
                    if data_counter_s = 0 then
                        next_spi_state_s <= END_RW;
                    end if;
                end if;
            when READ =>
                if clk_counter_s = 0 then
                    if data_counter_s = 0 then
                        next_spi_state_s <= END_RW;
                    end if;
                end if;
            when END_RW =>
                if clk_counter_s = 0 then
                    next_spi_state_s <= IDLE;
                    if start_i = '1' then
                        next_spi_state_s <= RW;
                    end if;
                end if;
            when others => null;
        end case;
    end process;

    SPI_RW_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                spi_state_s     <= IDLE;

                addr_counter_s  <= addr_i'left+1;
                data_counter_s  <= data_i'left+1;
                clk_counter_s   <= 0;

                RW_s            <= RW_READ;
                addr_s          <= (others => '0');
                data_s          <= (others => '0');
                MUXout_s        <= '0';
                
                data_o          <= (others => '0');
                rdy_o           <= '0';
                
                SCK_o           <= '1';
                SDI_o           <= '0';
                CSB_o           <= '1';
                CE_o            <= '0';

            else
                spi_state_s     <= next_spi_state_s;

                clk_counter_s <= clk_counter_s + 1;
                if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                    clk_counter_s <= 0;
                end if;
                
                data_o          <= (others => '0');
                rdy_o           <= '0';
                
                SCK_o           <= '1';
                SDI_o           <= '0';
                CSB_o           <= '1';
                CE_o            <= '1';
                
                case next_spi_state_s is
                    when IDLE =>
                        addr_counter_s <= addr_i'left+1;
                        data_counter_s <= data_i'left+1;

                        rdy_o <= '1';

                        clk_counter_s <= 0;
                        
                    when RW =>
                        CSB_o <= '0';
                        SDI_o <= RW_s;
                        SCK_o <= '0';

                        if clk_counter_s = 0 then
                            RW_s <= RW_i;
                            SDI_o <= RW_i;
                        elsif clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            SCK_o <= '1';
                        end if;

                    when ADDR =>
                        CSB_o <= '0';
                        SDI_o <= addr_s(addr_counter_s-1);
                        SCK_o <= '0';

                        if clk_counter_s = 0 then
                            if addr_counter_s = addr_i'left+1 then
                                addr_s <= addr_i;
                                SDI_o <= addr_i(addr_counter_s-1);
                            end if;
                        elsif clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                                addr_counter_s <= addr_counter_s-1;
                            end if;
                        end if;
                    
                    when WRITE =>
                        CSB_o <= '0';
                        SDI_o <= data_s(data_counter_s-1);
                        SCK_o <= '0';

                        if clk_counter_s = 0 then
                            if data_counter_s = data_i'left+1 then
                                data_s <= data_i;
                                SDI_o <= data_i(data_counter_s-1);
                            end if;
                        elsif clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                                data_counter_s <= data_counter_s - 1;
                            end if;
                        end if;

                    when READ =>
                        CSB_o <= '0';
                        DATA_o(data_counter_s-1) <= MUXout_s;
                        SCK_o <= '0';

                        if clk_counter_s = 0 then
                            MUXout_s <= MUXout_i;
                            DATA_o(data_counter_s-1) <= MUXout_i;
                        elsif clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                                data_counter_s <= data_counter_s - 1;
                            end if;
                        end if;
                    
                    when END_RW =>
                        CSB_o <= '1';
                        rdy_o <= '1';

                        addr_counter_s <= addr_i'left+1;
                        data_counter_s <= data_i'left+1;
                        
                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture mix;
