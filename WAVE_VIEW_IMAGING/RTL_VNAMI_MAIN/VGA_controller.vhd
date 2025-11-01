LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.TL_VNAMI_MAIN_pkg.all;
use work.main_control_pkg.all;


entity VGA_controller is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);

        start_i             : in std_logic;

        TX_VGA1_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA1_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA2_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);

		TX_VGA1_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA1_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA2_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);

        rdy_o           : out std_logic;

        --external input outputs(physical)
        input_rx_i     : in std_logic_vector(ADC_data_length_c-1 downto 0);
        input_tx_i     : in std_logic_vector(ADC_data_length_c-1 downto 0);

        -- value_o     : out std_logic_vector(VGA_data_length_c-1 downto 0);

        SCLK_o              : out std_logic;
        SDI_o               : out std_logic;

        CS_TX1_o            : out std_logic;
        CS_RX1_o            : out std_logic;
        CS_RX2_o            : out std_logic
	);
end entity VGA_controller;

architecture mix of VGA_controller is
    
--------------------------- SIGNALS ---------------------------

    --constant FULL_SCALE_ADC : unsigned(2*ADC_data_length_c-1 downto 0) := x"000145F";   -- = 0x1FFF * PI / 2

    signal input_s          : std_logic_vector(ADC_data_length_c-1 downto 0);
    -- signal value_s          : std_logic_vector(ADC_data_length_c-1 downto 0);
    signal start_seq_pulse_s : std_logic;
    signal start1_s : std_logic;
    signal start2_s : std_logic;
    signal start3_s : std_logic;
    signal gain_s : std_logic_vector(vga_gain_data_length_c-1 downto 0);
    signal rdy1_s : std_logic;
    signal rdy2_s : std_logic;
    signal rdy3_s : std_logic;
    signal SCLK1_s : std_logic;
    signal SCLK2_s : std_logic;
    signal SCLK3_s : std_logic;
    signal SDI1_s : std_logic;
    signal SDI2_s : std_logic;
    signal SDI3_s : std_logic;
    signal SPI_clock_speed_s : integer range 0 to max_spi_clock_divider_c;
    --signal value2_s          : std_logic_vector(ADC_data_length_c-1 downto 0);
    --signal value_100_s      : unsigned(2*ADC_data_length_c-1 downto 0);
    --signal value_100_2_s    : unsigned(2*ADC_data_length_c-1 downto 0);
    --signal value_100_3_s    : unsigned(2*ADC_data_length_c-1 downto 0);
    --signal value_100_4_s    : unsigned(2*ADC_data_length_c-1 downto 0);
    --signal value_o_s        : unsigned(VGA_data_length_c-1 downto 0);

    type state_t is (
        IDLE,
        WAIT_START1,
        SEQ1,
        WAIT_START2,
        SEQ2,
        WAIT_START3,
        SEQ3
    );
    signal state_s : state_t;

-------------------------- COMPONENTS -------------------------

    component VGA_ADL5206_driver is
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;

            --intern inputs/outputs (from main control,etc)
            SPI_clock_speed_i : integer range 0 to max_spi_clock_divider_c;

            start_i             : in std_logic;
            gain_i              : in std_logic_vector(4 downto 0);

            rdy_o               : out std_logic;

            --external input outputs(physical)
            SCLK_o              : out std_logic;
            CS_o                : out std_logic;
            SDI_o               : out std_logic;
            FA_o                : out std_logic
        );
    end component VGA_ADL5206_driver;

begin
--------------------------- DESIGN ----------------------------

    --value_100_s <= unsigned(value2_s) * 100;
    --value_100_3_s <= value_100_2_s / FULL_SCALE_ADC;
    --value_o_s <=  resize(value_100_4_s, VGA_data_length_c);
    --value_o <= value_s(VGA_data_length_c-1 downto 0);

    process(input_rx_i)
    begin
        input_s <= input_rx_i;
        if signed(input_rx_i) < 0 then
            input_s <= std_logic_vector(-signed(input_rx_i));
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;

                rdy_o           <= '0';
                start1_s         <= '0';
                start2_s         <= '0';
                start3_s         <= '0';

                gain_s <= (others => '0');

                SPI_clock_speed_s <= max_spi_clock_divider_c;

                TX_VGA1_gain_o <= (others => '0');
                RX_VGA1_gain_o <= (others => '0');
                RX_VGA2_gain_o <= (others => '0');

            else
                
                rdy_o           <= '0';
                start1_s         <= '0';
                start2_s         <= '0';
                start3_s         <= '0';
                
                case state_s is
                    when IDLE =>
                        rdy_o <= '1';

                        if start_seq_pulse_s = '1' then
                            state_s <= WAIT_START1;
                            start1_s <= '1';
                            gain_s <= TX_VGA1_gain_i;
                            SPI_clock_speed_s <= to_integer(unsigned(SPI_clock_speed_i));
                            TX_VGA1_gain_o <= TX_VGA1_gain_i;
                            RX_VGA1_gain_o <= RX_VGA1_gain_i;
                            RX_VGA2_gain_o <= RX_VGA2_gain_i;
                        end if;

                    when WAIT_START1 =>
                        if rdy1_s = '0' then
                            state_s <= SEQ1;
                        end if;

                    when SEQ1 =>
                        if rdy1_s = '1' then
                            state_s <= WAIT_START2;
                            start2_s <= '1';
                            gain_s <= RX_VGA1_gain_i;
                        end if;

                    when WAIT_START2 =>
                        if rdy2_s = '0' then
                            state_s <= SEQ2;
                        end if;

                    when SEQ2 =>
                        if rdy2_s = '1' then
                            state_s <= WAIT_START3;
                            start3_s <= '1';
                            gain_s <= RX_VGA2_gain_i;
                        end if;

                    when WAIT_START3 =>
                        if rdy3_s = '0' then
                            state_s <= SEQ3;
                        end if;

                    when SEQ3 =>
                        if rdy3_s = '1' then
                            state_s <= IDLE;
                        end if;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

    SCLK_o <= SCLK1_s when state_s = SEQ1 else
            SCLK2_s when state_s = SEQ2 else
            SCLK3_s when state_s = SEQ3 else
            '0';

    SDI_o <= SDI1_s when state_s = SEQ1 else
            SDI2_s when state_s = SEQ2 else
            SDI3_s when state_s = SEQ3 else
            '0';

    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => start_i,
        pulse_o     => start_seq_pulse_s
    );

    -- absolute_MA : moving_average
    -- generic map(
    --     BIT_WIDTH           => ADC_data_length_c,
    --     N_SAMPLES           => 8,
    --     OFFSET              => 3  --must be egal to log2(N_SAMPLES)
    -- )
    -- port map( 
    --     clk_i           => clk_i,
    --     reset_i         => reset_i,
        
    --     en_i            => '1',
    --     input_i         => input_s,
        
    --     valid_o         => open, --TODO
    --     value_o         => value_s
    -- );

    SPI_driver_TX1 : VGA_ADL5206_driver
    port map(
        clk_i               => clk_i,
        reset_i             => reset_i,

        --intern inputs/outputs (from main control, etc)
        SPI_clock_speed_i   => SPI_clock_speed_s,

        start_i             => start1_s,
        gain_i              => gain_s,

        rdy_o               => rdy1_s,

        --external input outputs(physical)
        SCLK_o              => SCLK1_s,
        CS_o                => CS_TX1_o,
        SDI_o               => SDI1_s,
        FA_o                => open
    );

    SPI_driver_RX1 : VGA_ADL5206_driver
    port map(
        clk_i               => clk_i,
        reset_i             => reset_i,

        --intern inputs/outputs (from main control, etc)
        SPI_clock_speed_i   => SPI_clock_speed_s,

        start_i             => start2_s,
        gain_i              => gain_s,

        rdy_o               => rdy2_s,

        --external input outputs(physical)
        SCLK_o              => SCLK2_s,
        CS_o                => CS_RX1_o,
        SDI_o               => SDI2_s,
        FA_o                => open
    );

    SPI_driver_RX2 : VGA_ADL5206_driver
    port map(
        clk_i               => clk_i,
        reset_i             => reset_i,

        --intern inputs/outputs (from main control, etc)
        SPI_clock_speed_i   => SPI_clock_speed_s,

        start_i             => start3_s,
        gain_i              => gain_s,

        rdy_o               => rdy3_s,

        --external input outputs(physical)
        SCLK_o              => SCLK3_s,
        CS_o                => CS_RX2_o,
        SDI_o               => SDI3_s,
        FA_o                => open
    );

end architecture mix;
