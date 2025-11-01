LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_switch_controller is
    generic(
        PATH_DATA_LENGTH    : integer := path_data_length_c --only multiple of 8 allowed
    );
    port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;

        --intern inputs/outputs (from main control,etc)
        read_back_i     : in std_logic;  -- to check the previously loaded bit code to raise exception if not equal
        SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
        start_seq_i     : in std_logic;
        store_after_i   : in std_logic;
        store_before_i  : in std_logic;
        path_data_i     : in std_logic_vector(PATH_DATA_LENGTH-1 downto 0);
        path_data_length_i : in std_logic;

        rdy_o           : out std_logic;
        exception_o     : out std_logic;

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
        SEQ
    );

--------------------------- SIGNALS ---------------------------

    signal spi_state_s       : spi_state_t;

    signal start_seq_pulse_s : std_logic;
    signal rdy_s : std_logic;
    signal rdy_pulse_s : std_logic;
    signal driver_on_s : std_logic;
    signal store_before_s : std_logic;
    signal store_after_s : std_logic;

    signal bit_count_s : integer range path_data_i'left downto 0;
    signal clk_counter_s : integer range 0 to max_spi_clock_divider_c;
    signal last_path_data_s : std_logic_vector(path_data_i'left downto 0);
    signal path_data_s : std_logic_vector(path_data_i'left downto 0);
    signal read_path_data_s : std_logic_vector(path_data_i'left downto 0);
    signal SPI_clock_speed_s : integer range 0 to max_spi_clock_divider_c;
    
-------------------------- COMPONENTS -------------------------  


--------------------------- DESIGN ----------------------------
begin
    
    clk_process: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                spi_state_s <= IDLE;

                rdy_o <= '0';
                exception_o <= '0';
                path_data_s <= (others => '0');
                last_path_data_s <= (others => '0');
                driver_on_s <= '0';
                store_before_s <= '0';
                store_after_s <= '0';
                SPI_clock_speed_s <= max_spi_clock_divider_c;

            else
                rdy_o <= '0';
                driver_on_s <= '0';

                case spi_state_s is
                    when IDLE =>

                        rdy_o <= '1';

                        if start_seq_pulse_s = '1' then
                            SPI_clock_speed_s <= to_integer(unsigned(SPI_clock_speed_i));
                            exception_o <= '0';
                            driver_on_s <= '1';
                            store_before_s <= store_before_i;
                            store_after_s <= store_after_i;
                            path_data_s <= path_data_i;
                            if store_before_i = '1' then
                                last_path_data_s <= path_data_s;
                            end if;
                            spi_state_s <= SEQ;
                        end if;

                    when SEQ =>

                        if rdy_pulse_s = '1' then
                            spi_state_s <= IDLE;
                            if read_back_i = '1' then
                                if store_before_s = '1' then
                                    if read_path_data_s /= last_path_data_s then
                                        exception_o <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;

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

    ready_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => rdy_s,
        pulse_o     => rdy_pulse_s
    );

    driver : SPI_switch_driver
    generic map(
        PATH_DATA_LENGTH    => PATH_DATA_LENGTH
    )
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        SPI_clock_speed_i => SPI_clock_speed_s,
        start_seq_i     => driver_on_s,
        latch_before_i  => store_before_s,
        latch_after_i   => store_after_s,
        path_data_i     => path_data_s,
        path_data_length_i => path_data_length_i,
        rdy_o           => rdy_s,

        path_data_o     => read_path_data_s,

        pico_o          => pico_o,
        poci_i          => poci_i,

        sck_o           => sck_o,
        srclr_n_o       => srclr_n_o,

        --rclk_o          => open,
        rclr_n_o        => rclr_n_o,

        cs_o            => cs_o
    );

end architecture mix;
