LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.TL_VNAMI_MAIN_pkg.all;
use work.main_control_pkg.all;


entity att_PE43705_driver is
    generic(
        ADDR                : std_logic_vector(2 downto 0) := (others => '0')
    );
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i   : in integer range 0 to max_spi_clock_divider_c;

        start_i             : in std_logic;
        data_i              : in std_logic_vector(PE43705_power_data_length_c-1 downto 0);

        rdy_o               : out std_logic;

        --external input outputs(physical)
        PAR_SER_o           : out std_logic;
        SERIAL_o            : out std_logic;
        CLK_o               : out std_logic;
        LATCH_ENABLE_o      : out std_logic
	);
end entity att_PE43705_driver;

architecture mix of att_PE43705_driver is
    
--------------------------- SIGNALS ---------------------------
    
    constant ADDR_LENGTH         : integer := 8;
    constant ADDR_SIGNIFICANT_LENGTH : integer := ADDR'left+1;
    constant DATA_LENGTH         : integer := 8;
    constant DATA_SIGNIFICANT_LENGTH : integer := data_i'left+1;
    
    signal clk_counter_s    : integer range 0 to max_spi_clock_divider_c-1;
    signal data_counter_s   : integer range 0 to DATA_LENGTH-1;
    signal addr_counter_s   : integer range 0 to ADDR_LENGTH-1;
    
    type state_t is (
        IDLE,
        DATA_SEQ,
        ADDR_SEQ,
        LATCH
    );
    signal state_s : state_t;
    
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    PAR_SER_o <= '1';   -- SERIAL

    SEQ_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;

                addr_counter_s  <= 0;
                data_counter_s  <= 0;
                clk_counter_s   <= 0;

                rdy_o           <= '0';

                SERIAL_o        <= '0';
                CLK_o           <= '0';
                LATCH_ENABLE_o  <= '0';

            else
                if clk_counter_s >= SPI_clock_speed_i-1 then
                    clk_counter_s <= 0;
                else
                    clk_counter_s <= clk_counter_s + 1;
                end if;
                
                rdy_o           <= '0';
                
                SERIAL_o        <= '0';
                CLK_o           <= '0';
                LATCH_ENABLE_o  <= '0';
                
                case state_s is
                    when IDLE =>
                        addr_counter_s <= 0;
                        data_counter_s <= 0;

                        rdy_o <= '1';

                        clk_counter_s <= 0;

                        if start_i = '1' then
                            state_s <= DATA_SEQ;
                        end if;
                        
                    when DATA_SEQ =>
                        if data_counter_s < DATA_SIGNIFICANT_LENGTH then
                            SERIAL_o <= data_i(data_counter_s);
                        else
                            SERIAL_o <= '0';
                        end if;

                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            CLK_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                if data_counter_s >= DATA_LENGTH-1 then
                                    state_s <= ADDR_SEQ;
                                else
                                    data_counter_s <= data_counter_s + 1;
                                end if;
                             end if;
                        end if;

                    when ADDR_SEQ =>
                        if addr_counter_s < ADDR_SIGNIFICANT_LENGTH then
                            SERIAL_o <= ADDR(addr_counter_s);
                        else
                            SERIAL_o <= '0';
                        end if;

                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            CLK_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                if addr_counter_s >= DATA_LENGTH-1 then
                                    state_s <= LATCH;
                                else
                                    addr_counter_s <= addr_counter_s + 1;
                                end if;
                            end if;
                        end if;
                    
                    when LATCH =>
                        if clk_counter_s >= SPI_clock_speed_i/2 then
                            LATCH_ENABLE_o <= '1';
                        end if;
                        if clk_counter_s >= SPI_clock_speed_i-1 then
                            state_s <= IDLE;
                        end if;            

                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture mix;
