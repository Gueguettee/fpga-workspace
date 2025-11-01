LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.TL_VNAMI_MAIN_pkg.all;
use work.main_control_pkg.all;


entity att_power_controller is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);

        start_i             : in std_logic;
        power_i             : in std_logic_vector(att_power_data_length_c-1 downto 0);

        rdy_o               : out std_logic;

        --external input outputs(physical)
        PAR_SER1_o           : out std_logic;
        SERIAL1_o            : out std_logic;
        CLK1_o               : out std_logic;
        LATCH_ENABLE1_o      : out std_logic;

        CTRL2_o              : out std_logic
	);
end entity att_power_controller;

architecture mix of att_power_controller is
    
--------------------------- SIGNALS ---------------------------

    constant ATTENUATION_MAX_FIRST_ATTENUATOR : unsigned(att_power_data_length_c-1 downto 0) := to_unsigned(127, att_power_data_length_c); --31.75*4
    constant ATTENUATION_SECOND_ATTENUATOR : unsigned(att_power_data_length_c-1 downto 0) := to_unsigned(20*ATTENUATION_MULTIPLE, att_power_data_length_c);

    signal power_i_s : std_logic_vector(att_power_data_length_c-1 downto 0);
    signal ATT_power1_s : std_logic_vector(PE43705_power_data_length_c-1 downto 0);
    signal ATT_power1_temp_s : std_logic_vector(att_power_data_length_c-1 downto 0);

    signal start_seq_pulse_s : std_logic;
    signal start_s : std_logic;
    signal rdy1_s : std_logic;

    signal SPI_clock_speed_s : integer range 0 to max_spi_clock_divider_c;
    
    type state_t is (
        IDLE,
        START,
        WAIT_END
    );
    signal state_s : state_t;
    
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    PE43705_comp1 : att_PE43705_driver
    generic map(
        ADDR                => "000"
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,

        SPI_clock_speed_i => SPI_clock_speed_s,
        
        start_i         => start_s,
        data_i          => ATT_power1_s,

        rdy_o           => rdy1_s,

        PAR_SER_o       => PAR_SER1_o,
        SERIAL_o        => SERIAL1_o,
        CLK_o           => CLK1_o,
        LATCH_ENABLE_o  => LATCH_ENABLE1_o
    );
    
    ATT_power1_temp_s <= std_logic_vector(unsigned(power_i_s) - ATTENUATION_SECOND_ATTENUATOR);

    SEQ_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;

                rdy_o           <= '0';
                start_s         <= '0';
                power_i_s <= (others => '0');
                ATT_power1_s <= (others => '0');

                CTRL2_o <= '0';

                SPI_clock_speed_s <= max_spi_clock_divider_c;

            else
                
                rdy_o           <= '0';
                start_s         <= '0';
                
                case state_s is
                    when IDLE =>
                        rdy_o <= '1';
                        power_i_s <= (others => '0');
                        ATT_power1_s <= (others => '0');

                        if start_seq_pulse_s = '1' then
                            state_s <= START;
                            power_i_s <= power_i;
                        end if;

                        SPI_clock_speed_s <= to_integer(unsigned(SPI_clock_speed_i));
                        
                    when START =>
                        start_s <= '1';
                        if unsigned(power_i_s) > ATTENUATION_MAX_FIRST_ATTENUATOR then
                            ATT_power1_s <= ATT_power1_temp_s(ATT_power1_s'left downto 0);
                            CTRL2_o <= '0';
                        else
                            ATT_power1_s <= power_i_s(ATT_power1_s'left downto 0);
                            CTRL2_o <= '1';
                        end if;

                        if rdy1_s = '0' then
                            state_s <= WAIT_END;
                        end if;

                    when WAIT_END =>
                        if rdy1_s = '1' then
                            state_s <= IDLE;
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
        input_i     => start_i,
        pulse_o     => start_seq_pulse_s
    );

end architecture mix;
