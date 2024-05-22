LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_switch_controller is
    generic(
        SPI_CLK_DIVIDER     : integer := 10; --minimum 2, only even numbers allowed
        PATH_DATA_LENGTH    : integer := path_data_length_c --only multiple of 8 allowed
    );
    port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;

        --intern inputs/outputs (from main control,etc)
        start_seq_i     : in std_logic;
        path_data_i     : in std_logic_vector(PATH_DATA_LENGTH-1 downto 0);
        rdy_o           : out std_logic;

        --external input outputs(physical)
        pico_o          : out std_logic;    --ser_o
        poci_i          : in std_logic;     --ser_i (to check the previously loaded bit code)

        sck_o           : out std_logic;    --srclk_o
        srclr_n_o       : out std_logic;    --RESET clk

        --rclk_o          : out std_logic;    --STORE
        rclr_n_o        : out std_logic;    --RESET store

        cs_o            : out std_logic     --CS (used to store register)
    );
end entity SPI_switch_controller;


architecture mix of SPI_switch_controller is

    type spi_state_t is (
        IDLE,
        START_WRITE,
        WRITE,
        LAST_WRITE,
        STORE
    );

--------------------------- SIGNALS ---------------------------

    signal spi_state_s       : spi_state_t;
    signal next_spi_state_s  : spi_state_t;

    signal start_seq_pulse_s : std_logic;

    signal bit_count_s : integer range path_data_i'left downto 0;
    signal clk_counter_s : integer range 0 to SPI_CLK_DIVIDER;
    signal path_data_s : std_logic_vector(path_data_i'left downto 0);
    
-------------------------- COMPONENTS -------------------------  


--------------------------- DESIGN ----------------------------
begin

    next_spi_state: process(spi_state_s, clk_counter_s, start_seq_pulse_s, bit_count_s, path_data_s, poci_i, path_data_i)
    begin
        next_spi_state_s <= spi_state_s;

        case spi_state_s is
            when IDLE =>
                if start_seq_pulse_s = '1' then
                    next_spi_state_s <= START_WRITE;
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
                    next_spi_state_s <= STORE;
                end if;
            when STORE =>
                if clk_counter_s = 0 then
                    next_spi_state_s <= IDLE;
                    if start_seq_pulse_s = '1' then
                        next_spi_state_s <= START_WRITE;
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
                sck_o <= '1';
                srclr_n_o <= '0';
                --rclk_o <= '0';
                rclr_n_o <= '0';
                cs_o <= '1';
                bit_count_s <= path_data_i'left;
                path_data_s <= (others => '0');

            else
                spi_state_s <= next_spi_state_s;

                clk_counter_s <= clk_counter_s + 1;
                if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                    clk_counter_s <= 0;
                end if;

                rdy_o <= '0';
                pico_o <= '0';
                sck_o <= '1';
                srclr_n_o <= '1';
                --rclk_o <= '0';
                rclr_n_o <= '1';
                cs_o <= '1';

                case next_spi_state_s is
                    when IDLE =>

                        rdy_o <= '1';
                        bit_count_s <= path_data_i'left;
                        clk_counter_s <= 0;

                    when START_WRITE =>

                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';
                        cs_o <= '0';

                        if clk_counter_s = 0 then
                            path_data_s <= path_data_i;
                            pico_o <= path_data_i(bit_count_s);
                        elsif clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            sck_o <= '1';
                            if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                                bit_count_s <= bit_count_s - 1;
                            end if;
                        end if;

                    when WRITE =>
                        
                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';
                        cs_o <= '0';

                        if clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            sck_o <= '1';
                            if clk_counter_s >= SPI_CLK_DIVIDER-1 then
                                bit_count_s <= bit_count_s - 1;
                            end if;
                        end if;

                    when LAST_WRITE =>

                        pico_o <= path_data_s(bit_count_s);
                        sck_o <= '0';
                        cs_o <= '0';

                        if clk_counter_s > SPI_CLK_DIVIDER/2-1 then
                            sck_o <= '1';
                        end if;

                    when STORE =>

                        --rclk_o <= '1';
                        rdy_o <= '1';
                        bit_count_s <= path_data_i'left;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => start_seq_i,
        pulse_o     => start_seq_pulse_s
    );

end architecture mix;
