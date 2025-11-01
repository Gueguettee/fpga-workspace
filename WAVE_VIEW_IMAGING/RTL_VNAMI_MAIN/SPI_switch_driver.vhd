LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_switch_driver is
    generic(
        PATH_DATA_LENGTH    : integer := path_data_length_c --only multiple of 8 allowed
    );
    port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i : in integer range 0 to max_spi_clock_divider_c;
        start_seq_i     : in std_logic;
        latch_before_i  : in std_logic;
        latch_after_i   : in std_logic;
        path_data_i     : in std_logic_vector(PATH_DATA_LENGTH-1 downto 0);
        path_data_length_i : in std_logic;

        rdy_o           : out std_logic;
        path_data_o     : out std_logic_vector(PATH_DATA_LENGTH-1 downto 0);

        --external input outputs(physical)
        pico_o          : out std_logic;    --ser_o
        poci_i          : in std_logic;     --ser_i (to check the previously loaded bit code)

        sck_o           : out std_logic;    --srclk_o
        srclr_n_o       : out std_logic;    --RESET clk

        --rclk_o          : out std_logic;    --STORE
        rclr_n_o        : out std_logic;    --RESET store

        cs_o            : out std_logic     --CS (used to store register)
    );
end entity SPI_switch_driver;


architecture mix of SPI_switch_driver is

    type spi_state_t is (
        IDLE,
        START_WRITE,
        WRITE,
        LAST_WRITE,
        LATCH
    );

--------------------------- SIGNALS ---------------------------

    signal spi_state_s       : spi_state_t;
    signal next_spi_state_s  : spi_state_t;

    signal bit_count_s : integer range path_data_i'left downto 0;
    signal clk_counter_s : integer range 0 to max_spi_clock_divider_c;
    signal path_data_s : std_logic_vector(path_data_i'left downto 0);
    signal read_path_data_s : std_logic_vector(path_data_i'left downto 0);
    
-------------------------- COMPONENTS -------------------------  


--------------------------- DESIGN ----------------------------
begin

    next_spi_state: process(spi_state_s, clk_counter_s, start_seq_i, bit_count_s, path_data_s, poci_i, path_data_i, latch_before_i, read_path_data_s, latch_after_i)
    begin
        next_spi_state_s <= spi_state_s;

        case spi_state_s is
            when IDLE =>
                if start_seq_i = '1' then
                    next_spi_state_s <= START_WRITE;
                    if latch_before_i = '1' then
                        next_spi_state_s <= LATCH;
                    end if;
                end if;
            when START_WRITE =>
                if clk_counter_s = 0 then
                    next_spi_state_s <= WRITE;
                end if;
            when WRITE =>
                if clk_counter_s = 0 then
                    if bit_count_s = 0 then
                        next_spi_state_s <= LAST_WRITE;
                    end if;
                end if;
            when LAST_WRITE =>
                if clk_counter_s = 0 then
                    if latch_after_i = '1' then
                        next_spi_state_s <= LATCH;
                    else
                        next_spi_state_s <= IDLE;
                    end if;
                end if;
            when LATCH =>
                if clk_counter_s = 0 then
                    if latch_before_i = '1' then
                        next_spi_state_s <= START_WRITE;
                    else
                        next_spi_state_s <= IDLE;
                    end if;
                end if;
            when others => null;
        end case;
    end process;
    
    clk_process: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                spi_state_s <= IDLE;

                clk_counter_s <= 0;

                rdy_o <= '0';
                pico_o <= '0';
                sck_o <= '0';
                srclr_n_o <= '0';
                --rclk_o <= '0';
                rclr_n_o <= '0';
                cs_o <= '0';
                bit_count_s <= 0;
                path_data_s <= (others => '0');
                read_path_data_s <= (others => '0');
                path_data_o <= (others => '0');

            else
                spi_state_s <= next_spi_state_s;

                clk_counter_s <= clk_counter_s + 1;
                if clk_counter_s >= SPI_clock_speed_i-1 then
                    clk_counter_s <= 0;
                end if;

                rdy_o <= '0';
                pico_o <= '0';
                sck_o <= '0';
                srclr_n_o <= '1';
                --rclk_o <= '0';
                rclr_n_o <= '1';
                cs_o <= '0';

                case next_spi_state_s is
                    when IDLE =>

                        rdy_o <= '1';
                        if path_data_length_i = '1' then
                            bit_count_s <= path_data_i'left;
                        else
                            bit_count_s <= 7;
                        end if;
                        clk_counter_s <= 0;

                    when START_WRITE =>

                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';

                        if clk_counter_s = 0 then
                            path_data_s <= path_data_i;
                            pico_o <= path_data_i(bit_count_s);
                            read_path_data_s(bit_count_s) <= poci_i;
                        elsif clk_counter_s > SPI_clock_speed_i/2-1 then
                            sck_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                bit_count_s <= bit_count_s - 1;
                            end if;
                        end if;

                    when WRITE =>
                        
                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';
                        
                        if clk_counter_s = 0 then
                            read_path_data_s(bit_count_s) <= poci_i;
                        elsif clk_counter_s > SPI_clock_speed_i/2-1 then
                            sck_o <= '1';
                            if clk_counter_s >= SPI_clock_speed_i-1 then
                                bit_count_s <= bit_count_s - 1;
                            end if;
                        end if;

                    when LAST_WRITE =>

                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';
                        
                        if clk_counter_s = 0 then
                            read_path_data_s(bit_count_s) <= poci_i;
                            path_data_o <= read_path_data_s;
                            path_data_o(bit_count_s) <= poci_i;
                        elsif clk_counter_s > SPI_clock_speed_i/2-1 then
                            sck_o <= '1';
                        end if;

                    when LATCH =>

                        --rclk_o <= '1';
                        if clk_counter_s > SPI_clock_speed_i/2-1 then
                            cs_o <= '1';
                        end if;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

end architecture mix;
