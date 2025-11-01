LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity VGA_ADL5206_driver is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i   : in integer range 0 to max_spi_clock_divider_c;

        start_i             : in std_logic;
        gain_i              : in std_logic_vector(4 downto 0);

        rdy_o               : out std_logic;

        --external input outputs(physical)
        SCLK_o              : out std_logic;
        CS_o                : out std_logic;
        SDI_o               : out std_logic;
        FA_o                : out std_logic
	);
end entity VGA_ADL5206_driver;

architecture mix of VGA_ADL5206_driver is
    
--------------------------- SIGNALS ---------------------------
    
    constant ADDR_LENGTH         : integer := 15;
    constant DATA_LENGTH         : integer := 8;

    constant ADDR : std_logic_vector(ADDR_LENGTH-1 downto 0) := (others => '0');

    signal data_s : std_logic_vector(DATA_LENGTH-1 downto 0);

    signal addr_counter_s   : integer range 0 to ADDR_LENGTH-1;
    signal data_counter_s   : integer range 0 to DATA_LENGTH-1;

    signal clk_counter_s    : integer range 0 to max_spi_clock_divider_c-1;
    
    type state_t is (
        IDLE,
        RW,
        ADDR_SEQ,
        DATA_SEQ,
        LATCH
    );
    signal state_s : state_t;
    
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    FA_o <= '0';   -- disable fast attack mode

    data_s(data_s'left downto gain_i'left+1) <= (others => '0');
    data_s(gain_i'left downto 0) <= gain_i;

    SPI_seq_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;

                addr_counter_s  <= ADDR_LENGTH-1;
                data_counter_s  <= DATA_LENGTH-1;
                clk_counter_s   <= 0;

                rdy_o           <= '0';

                SCLK_o          <= '0';
                CS_o            <= '1';
                SDI_o           <= '0';

            else
                if clk_counter_s >= SPI_clock_speed_i-1 then
                    clk_counter_s <= 0;
                else
                    clk_counter_s <= clk_counter_s + 1;
                end if;
                
                rdy_o           <= '0';
                
                SCLK_o          <= '0';
                CS_o            <= '1';
                SDI_o           <= '0';
                
                case state_s is
                    when IDLE =>
                        addr_counter_s  <= ADDR_LENGTH-1;
                        data_counter_s  <= DATA_LENGTH-1;

                        rdy_o <= '1';

                        clk_counter_s <= 0;

                        if start_i = '1' then
                            state_s <= DATA_SEQ;
                        end if;
                        
                    when RW =>
                        SDI_o       <= '0';
                        CS_o        <= '0';

                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            SCLK_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                state_s <= ADDR_SEQ;
                             end if;
                        end if;

                    when ADDR_SEQ =>
                        SDI_o       <= ADDR(addr_counter_s);
                        CS_o        <= '0';

                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            SCLK_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                if addr_counter_s = 0 then
                                    state_s <= DATA_SEQ;
                                else
                                    addr_counter_s <= addr_counter_s - 1;
                                end if;
                            end if;
                        end if;

                    when DATA_SEQ =>
                        SDI_o       <= data_s(data_counter_s);
                        CS_o        <= '0';

                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            SCLK_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                if data_counter_s = 0 then
                                    state_s <= LATCH;
                                else
                                    data_counter_s <= data_counter_s - 1;
                                end if;
                            end if;
                        end if;
                    
                    when LATCH =>
                        if clk_counter_s < SPI_clock_speed_i/2 then
                            CS_o <= '0';
                        elsif clk_counter_s >= SPI_clock_speed_i-1 then
                            state_s <= IDLE;
                        end if;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture mix;
