LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity SPI_synth_driver is
    generic(
        ADDR_LENGTH         : integer := 7;
        DATA_LENGTH         : integer := 16;
        BLOCK_PROGRAMMING   : boolean_t := NO
    );
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        spi_clk_divider_i   : in integer range 0 to max_spi_clock_divider_c;
        
        RW_i                : in std_logic; --0 is write, 1 is read
        addr_i              : in std_logic_vector(ADDR_LENGTH-1 downto 0);
        data_i              : in std_logic_vector(DATA_LENGTH-1 downto 0);
        data_o              : out std_logic_vector(DATA_LENGTH-1 downto 0);
        
        MUXout_i            : in std_logic;
        SCK_o               : out std_logic;
        SDI_o               : out std_logic;
        CSB_o               : out std_logic;
        CE_o                : out std_logic;
        
        rdy_o               : out std_logic;
        rdy_next_data_o     : out std_logic
	);
end entity SPI_synth_driver;

architecture mix of SPI_synth_driver is
    
--------------------------- SIGNALS ---------------------------
    
    --constant TOTAL_LENGTH   : integer := ADDR_LENGTH + DATA_LENGTH + 1;
    
    signal addr_counter_s   : integer range addr_i'left+1 downto 0;
    signal data_counter_s   : integer range data_i'left+1 downto 0;
    signal clk_counter_s    : integer range 0 to max_spi_clock_divider_c;
    
    signal RW_s             : std_logic;
    signal addr_s           : std_logic_vector(addr_i'left downto 0);
    signal data_s           : std_logic_vector(data_i'left downto 0);
    
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

    next_spi_state: process(spi_state_s, clk_counter_s, start_i, RW_i, RW_s, addr_i, addr_s, data_i, data_s, MUXout_i, addr_counter_s, data_counter_s)
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
                        if start_i = '1' then
                            if BLOCK_PROGRAMMING = YES and 
                                (unsigned(addr_i) = unsigned(addr_s)-1) and
                                (RW_i = RW_WRITE) then
                                next_spi_state_s <= WRITE;
                            end if;
                        end if;
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
                
                data_o          <= (others => '0');
                rdy_o           <= '0';
                
                SCK_o           <= '0';
                SDI_o           <= '1';
                CSB_o           <= '1';
                CE_o            <= '0';

            else
                spi_state_s     <= next_spi_state_s;

                clk_counter_s <= clk_counter_s + 1;
                if clk_counter_s >= spi_clk_divider_i-1 then
                    clk_counter_s <= 0;
                end if;
                
                rdy_o           <= '0';
                rdy_next_data_o <= '0';
                
                SCK_o           <= '0';
                SDI_o           <= '1';
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

                        if clk_counter_s = 0 then
                            RW_s <= RW_i;
                            SDI_o <= RW_i;
                        elsif clk_counter_s > spi_clk_divider_i/2-1 then
                            SCK_o <= '1';
                        end if;

                    when ADDR =>
                        CSB_o <= '0';
                        SDI_o <= addr_s(addr_counter_s-1);

                        if clk_counter_s = 0 then
                            if addr_counter_s = addr_i'left+1 then
                                addr_s <= addr_i;
                                SDI_o <= addr_i(addr_counter_s-1);
                            end if;
                        elsif clk_counter_s > spi_clk_divider_i/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= spi_clk_divider_i-1 then
                                addr_counter_s <= addr_counter_s-1;
                            end if;
                        end if;
                    
                    when WRITE =>
                        CSB_o <= '0';
                        if data_counter_s > 0 then
                            SDI_o <= data_s(data_counter_s-1);
                        end if;

                        if clk_counter_s = 0 then
                            if data_counter_s = data_i'left+1 or data_counter_s = 0 then
                                addr_s <= addr_i;
                                data_s <= data_i;
                                SDI_o <= data_i(data_i'left);
                                data_counter_s <= data_i'left+1;
                                rdy_next_data_o <= '1';
                            end if;
                        elsif clk_counter_s > spi_clk_divider_i/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= spi_clk_divider_i-1 then
                                data_counter_s <= data_counter_s - 1;
                            end if;
                        end if;

                    when READ =>
                        CSB_o <= '0';
                        SDI_o <= '0';

                        if clk_counter_s = 0 then
                            null;
                        elsif clk_counter_s > spi_clk_divider_i/2-1 then
                            SCK_o <= '1';
                            if clk_counter_s >= spi_clk_divider_i-1 then
                                data_counter_s <= data_counter_s - 1;
                            end if;
                            if clk_counter_s = spi_clk_divider_i/2 then
                                data_s(data_counter_s-1) <= MUXout_i;
                                if data_counter_s-1 = 0 then
                                    data_o(data_o'left downto 1) <= data_s(data_o'left downto 1);
                                    data_o(0) <= MUXout_i;
                                end if;
                            end if;
                        end if;
                    
                    when END_RW =>
                        rdy_o <= '1';

                        if clk_counter_s <= spi_clk_divider_i/2-1 then
                            CSB_o <= '0';
                        end if;

                        addr_counter_s <= addr_i'left+1;
                        data_counter_s <= data_i'left+1;
                        
                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture mix;
