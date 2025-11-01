LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity TL_VNA_MAIN is
port
	(
        clk_i           : in std_logic;
        reset_i         : in std_logic;
        
      --PL/PS IO
        start_PL_i      : in std_logic;

        init_meas_i     : in std_logic;
        freq_done_i     : in std_logic; 
        path_done_i     : in std_logic;     
        freqPath_done_i : in std_logic;
        start_cw_i      : in std_logic;
        send_adc_data_i : in std_logic;
        
        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(24 - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(24 - 1 downto 0);
        mode_i          : in std_logic_vector(mode_data_length_c - 1 downto 0);
        RF_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        LO_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        ATT_power_i     : in std_logic_vector(att_power_data_length_c - 1 downto 0);
        cable_calFact_power_i : in std_logic_vector(calFact_power_cable_data_length_c - 1 downto 0); 
        path_calFact_freqPath_i : in std_logic_vector(calFact_power_freqPath_data_length_c - 1 downto 0);

        TX_VGA1_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA1_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA2_gain_o  : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);

		TX_VGA1_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA1_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		RX_VGA2_gain_i  : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);

        path_data_length_i : in std_logic;
        rising_edge_adc_data_i : in std_logic;
        synth_stability_delay_us_i : in std_logic_vector(synth_stability_data_length_c - 1 downto 0);

        ADC_sub_threshold_i : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        ADC_sup_threshold_i : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        LED_indicators_i : in std_logic_vector(LED_INDICATORS_DATA_LENGTH_c - 1 downto 0);

		SYNTH_SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
		VGA_SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
		SWITCH_ARRAY_SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
		ATTENUATOR_SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);

        offset_i : in std_logic_vector(offset_data_length_c - 1 downto 0);

        vga_to_subtract_if_sup_threshold_i : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		vga_to_add_if_sub_threshold_i : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        synth_stability_delay_for_vga_adjust_us_i : in std_logic_vector(synth_stability_data_length_c - 1 downto 0);
        vga_power_adjust_enable_i : in std_logic_vector(vga_power_adjust_enable_data_length_c - 1 downto 0);

        IQ_rdy_PL_o     : out std_logic;

        I_TX_PL_o       : out std_logic_vector(31 downto 0);
        Q_TX_PL_o       : out std_logic_vector(31 downto 0);
        I_RX_PL_o       : out std_logic_vector(31 downto 0);
        Q_RX_PL_o       : out std_logic_vector(31 downto 0);

        ADC_TX_o        : out std_logic_vector(31 downto 0);
        ADC_RX_o        : out std_logic_vector(31 downto 0);

        PL_status_o     : out std_logic_vector(PL_status_data_length_c - 1 downto 0);
        
        VNA_rdy_PL_o    : out std_logic;

        ADC_TX_sub_threshold_indicator_o : out std_logic_vector(31 downto 0);
        ADC_TX_sup_threshold_indicator_o : out std_logic_vector(31 downto 0);
        ADC_RX_sub_threshold_indicator_o : out std_logic_vector(31 downto 0);
        ADC_RX_sup_threshold_indicator_o : out std_logic_vector(31 downto 0);

        filter_bank_throughput_i : in std_logic;
        read_back_switch_array_i : in std_logic;

      --Onboard utility 
        LED0_N_PL_o     : out std_logic;
        LED1_N_PL_o     : out std_logic;
        LED2_N_PL_o     : out std_logic;
        LED3_N_PL_o     : out std_logic;

        BTN_i           : in std_logic;
		
	  --FMC IO signals
        ADC_TX_i        : in std_logic_vector(ADC_data_length_c-1 downto 0);
        ADC_RX_i        : in std_logic_vector(ADC_data_length_c-1 downto 0);
	  
        RF_MUXout_i     : in std_logic;
        RF_SCK_o        : out std_logic;
        RF_CSB_o        : out std_logic;
        RF_SDI_o        : out std_logic;
        RF_CE_o         : out std_logic;
        
        LO_MUXout_i     : in std_logic;
        LO_SCK_o        : out std_logic;
        LO_CSB_o        : out std_logic;
        LO_SDI_o        : out std_logic;
        LO_CE_o         : out std_logic;
        
        output_tilt_o   : out std_logic_vector(2 downto 0);
        input_tilt_1    : in std_logic;
        input_tilt_2    : in std_logic;
        input_tilt_3    : in std_logic;
        
        SPM_data_o      : out std_logic_vector(27 downto 0);
        SPM_MISO_i      : in std_logic;
        SPM_SCLK_o      : out std_logic;
        SPM_CSB_o       : out std_logic;

        RF_ON_o         : out std_logic;
        PWR_STAT_ON_o   : out std_logic;
        RUN_STAT_ON_o   : out std_logic;
        LED_CS_o        : out std_logic;

        CAL_CTRL_o      : out std_logic_vector(1 downto 0);
        STATE_CTRL_o    : out std_logic_vector(1 downto 0);
        
        ---TX SIGNALS----
        SWR_TX_SER_o    : out std_logic; --named this based on 8 bit shift register datasheet
        SWR_TX_SRCLK_o  : out std_logic;
        
        SWR_TX_SRCLR_o  : out std_logic;
        SWR_TX_RCLK_o   : out std_logic;
        --SWR_TX_RCLR_o   : out std_logic;

        SWR_TX_SER_BACK_i   : in std_logic;
        
        ---RX SIGNALS----
        SWR_RX_SER_o    : out std_logic; --named this based on 8 bit shift register datasheet
        SWR_RX_SRCLK_o  : out std_logic;
        
        SWR_RX_SRCLR_o  : out std_logic;
        SWR_RX_RCLK_o   : out std_logic;
        --SWR_RX_RCLR_o   : out std_logic

        SWR_RX_SER_BACK_i   : in std_logic;

        --Filter bank signals
        V_o : out std_logic_vector(filter_bank_controller_output_length_c-1 downto 0);

        --Attenuators signals
        PAR_SER1_o           : out std_logic;
        SERIAL1_o            : out std_logic;
        CLK1_o               : out std_logic;
        LATCH_ENABLE1_o      : out std_logic;

        CTRL2_o              : out std_logic;

        --VGAs signals
        VGA_SCLK_o           : out std_logic;
        VGA_SDI_o            : out std_logic;
        RX1_VGA_CS_o         : out std_logic;
        RX2_VGA_CS_o         : out std_logic;
        TX1_VGA_CS_o         : out std_logic;

        --Testing signals
        sine_0_o    : out std_logic_vector(ADC_data_length_c-1 downto 0);
        sine_90_o   : out std_logic_vector(ADC_data_length_c-1 downto 0)
	);
end entity TL_VNA_MAIN;

architecture mix of TL_VNA_MAIN is

--------------------------- SIGNALS ---------------------------

    signal start_pulse_s        : std_logic;
    
    signal state_s              : std_logic_vector(3 downto 0);
    signal IQ_rdy_PL_s          : std_logic;
    signal write_IQ_s           : std_logic;
    signal write_ADC_s          : std_logic;
    
    signal set_switch_s         : std_logic;
    signal set_freq_s           : std_logic;
    signal set_att_power_s      : std_logic;
    signal set_vga_s            : std_logic;
    signal synth_seq_id_s       : seq_id_t;
    signal RF_synth_pll_locked_s      : std_logic;
    signal LO_synth_pll_locked_s      : std_logic;
    signal synth_pll_locked_s      : std_logic;
    signal RF_synth_seq_done_s        : std_logic;
    signal LO_synth_seq_done_s        : std_logic;
    
    signal PLL_locked_seq_done  : std_logic;

    signal start_sample_s       : std_logic;
    
    signal sampleTX_done_s      : std_logic;
    signal sampleRX_done_s      : std_logic;
    signal sample_done_s        : std_logic;

    signal freq_val_s           : std_logic_vector(freq_data_length_c - 1 downto 0);
    signal offset_s             : offset_t;
    signal RF_power_s           : power_t;
    signal LO_power_s           : power_t;
    signal ATT_power_s          : att_power_t;
    signal ifbw_val_s           : std_logic_vector(ifbw_data_length_c - 1 downto 0);
    signal path_tx_val_s        : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_rx_val_s        : std_logic_vector(path_data_length_c - 1 downto 0);
    signal RX1_VGA_gain_s       : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal RX2_VGA_gain_s       : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal TX1_VGA_gain_s       : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal RX1_VGA_gain_o_s     : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal RX2_VGA_gain_o_s     : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal TX1_VGA_gain_o_s     : std_logic_vector(vga_gain_data_length_c - 1 downto 0);

    signal ADC_TX_s             : std_logic_vector(ADC_data_length_c-1 downto 0);
    signal ADC_RX_s             : std_logic_vector(ADC_data_length_c-1 downto 0);

    signal ADC_TX_buff_s        : std_logic_vector(ADC_data_length_c-1 downto 0);
    signal ADC_RX_buff_s        : std_logic_vector(ADC_data_length_c-1 downto 0);
    
    signal I_TX_s               : std_logic_vector(26 downto 0);
    signal Q_TX_s               : std_logic_vector(26 downto 0);
    signal I_RX_s               : std_logic_vector(26 downto 0);
    signal Q_RX_s               : std_logic_vector(26 downto 0);

    signal sw_tx_rdy_s          : std_logic;
    signal sw_rx_rdy_s          : std_logic;
    signal sw_rdy_s             : std_logic;

    signal sw_ready_s           : std_logic;
    signal synth_ready_s        : std_logic;

    signal sw_store_after_s     : std_logic;
    signal sw_store_before_s    : std_logic;
    signal sw_rx_exception_s    : std_logic;
    signal sw_tx_exception_s    : std_logic;
    signal sw_exception_s       : std_logic;

    signal synth_exception_s    : std_logic;
    signal RF_synth_exception_s : std_logic;
    signal LO_synth_exception_s : std_logic;

    signal vga_rdy_s            : std_logic;

    signal en_rf_s              : std_logic;

    signal att_seq_done_s       : std_logic;

    signal mode_s               : mode_t;
    signal PL_status_s          : std_logic_vector(PL_status_data_length_c-1 downto 0);
    signal error_while_measurement_s : std_logic;

    signal ADC_TX_sup_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c-1 downto 0);
    signal ADC_RX_sup_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c-1 downto 0);
    signal ADC_TX_sub_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c-1 downto 0);
    signal ADC_RX_sub_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c-1 downto 0);

    signal start_adc_average_s : std_logic;
    signal tx_adc_average_done_s : std_logic;
    signal rx_adc_average_done_s : std_logic;
    signal ADJUST_VGA_TX_ADC_sub_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
    signal ADJUST_VGA_RX_ADC_sub_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
    signal ADJUST_VGA_TX_ADC_sup_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
    signal ADJUST_VGA_RX_ADC_sup_threshold_indicator_s : std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);

-------------------------- COMPONENTS -------------------------

    --in main package

begin
--------------------------- DESIGN ----------------------------

    CAL_CTRL_o <= mode_i(3 downto 2);
    STATE_CTRL_o <= mode_i(1 downto 0);

    RF_ON_o <= en_rf_s;
    PWR_STAT_ON_o <= LED_indicators_i(0);
    RUN_STAT_ON_o <= LED_indicators_i(1);
    LED_CS_o <= LED_indicators_i(2);

    sine_0_o <= ADC_TX_buff_s;
    sine_90_o <= ADC_RX_buff_s;

    offset_s <= to_integer(unsigned(offset_i));

    PL_status_o(SYNTH_EXCEPTION_BIT) <= PL_status_s(SYNTH_EXCEPTION_BIT);
   
    --READING ADC VALUES
    readADC: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                ADC_TX_s <= (others => '0');
                ADC_RX_s <= (others => '0');
            else
                if rising_edge_adc_data_i = '1' then -- so much better with rising edge than with rising edge
                    ADC_TX_s <= ADC_TX_i;
                    ADC_RX_s <= ADC_RX_i;
                end if;
            end if;
        end if;
        if falling_edge(clk_i) then
            if reset_i = '1' then
                ADC_TX_s <= (others => '0');
                ADC_RX_s <= (others => '0');
            else
                if rising_edge_adc_data_i = '0' then -- so much worse with falling edge than with rising edge
                    ADC_TX_s <= ADC_TX_i;
                    ADC_RX_s <= ADC_RX_i;
                end if;
            end if;
        end if;
    end process;

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                sample_done_s           <= '0';

                IQ_rdy_PL_o             <= '0';

                I_TX_PL_o               <= (others => '0');
                Q_TX_PL_o               <= (others => '0');
                I_RX_PL_o               <= (others => '0');
                Q_RX_PL_o               <= (others => '0');

                ADC_TX_o                <= (others => '0');
                ADC_RX_o                <= (others => '0');

                ADC_TX_sub_threshold_indicator_o <= (others => '0');
                ADC_TX_sup_threshold_indicator_o <= (others => '0');
                ADC_RX_sub_threshold_indicator_o <= (others => '0');
                ADC_RX_sup_threshold_indicator_o <= (others => '0');

                PL_status_o(SW_EXCEPTION_BIT) <= '0';
                PL_status_o(SYNTH_EXCEPTION_WHILE_MEASUREMENT_BIT) <= '0';
            else
                sample_done_s           <= sampleTX_done_s and sampleRX_done_s;

                IQ_rdy_PL_o             <= IQ_rdy_PL_s;

                if write_IQ_s = '1' then
                    I_TX_PL_o   <= std_logic_vector(resize(signed(I_TX_s), I_TX_PL_o'length));
                    Q_TX_PL_o   <= std_logic_vector(resize(signed(Q_TX_s), Q_TX_PL_o'length));
                    I_RX_PL_o   <= std_logic_vector(resize(signed(I_RX_s), I_RX_PL_o'length));
                    Q_RX_PL_o   <= std_logic_vector(resize(signed(Q_RX_s), Q_RX_PL_o'length));

                    ADC_TX_sup_threshold_indicator_o <= std_logic_vector(resize(unsigned(ADC_TX_sup_threshold_indicator_s), ADC_TX_sup_threshold_indicator_o'length));
                    ADC_RX_sup_threshold_indicator_o <= std_logic_vector(resize(unsigned(ADC_RX_sup_threshold_indicator_s), ADC_RX_sup_threshold_indicator_o'length));
                    ADC_TX_sub_threshold_indicator_o <= std_logic_vector(resize(unsigned(ADC_TX_sub_threshold_indicator_s), ADC_TX_sub_threshold_indicator_o'length));
                    ADC_RX_sub_threshold_indicator_o <= std_logic_vector(resize(unsigned(ADC_RX_sub_threshold_indicator_s), ADC_RX_sub_threshold_indicator_o'length));

                    TX_VGA1_gain_o <= TX1_VGA_gain_o_s;
                    RX_VGA1_gain_o <= RX1_VGA_gain_o_s;
                    RX_VGA2_gain_o <= RX2_VGA_gain_o_s;

                    PL_status_o(SW_EXCEPTION_BIT) <= PL_status_s(SW_EXCEPTION_BIT);
                    PL_status_o(SYNTH_EXCEPTION_WHILE_MEASUREMENT_BIT) <= PL_status_s(SYNTH_EXCEPTION_WHILE_MEASUREMENT_BIT);

                elsif write_ADC_s = '1' then
                    ADC_TX_o   <= std_logic_vector(resize(signed(ADC_TX_buff_s), ADC_TX_o'length));
                    ADC_RX_o   <= std_logic_vector(resize(signed(ADC_RX_buff_s), ADC_RX_o'length));
                end if;
            end if;
        end if;
    end process;

    LED0_N_PL_o <= state_s(0);
    LED1_N_PL_o <= state_s(1);
    LED2_N_PL_o <= state_s(2);
    LED3_N_PL_o <= state_s(3);
    
    synth_pll_locked_s <= RF_synth_pll_locked_s and LO_synth_pll_locked_s;
    PLL_locked_seq_done     <= (RF_synth_seq_done_s and LO_synth_seq_done_s and synth_pll_locked_s and att_seq_done_s and vga_rdy_s and tx_adc_average_done_s and rx_adc_average_done_s);

    sw_exception_s <= sw_tx_exception_s or sw_rx_exception_s;
    synth_exception_s <= RF_synth_exception_s or LO_synth_exception_s;
    
    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => start_PL_i,
        pulse_o     => start_pulse_s
    );

    synthesisers_ready_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => PLL_locked_seq_done,
        pulse_o     => synth_ready_s
    );
    
    sw_rdy_s <= sw_tx_rdy_s and sw_rx_rdy_s;
    
    switches_ready_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => sw_rdy_s,
        pulse_o     => sw_ready_s
    );

    mode_s <= MODE_LUT(to_integer(unsigned(mode_i)));
    
    Control : main_control
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
		
        start_i         => start_pulse_s,
        
        init_meas_i     => init_meas_i,
        freq_done_i     => freq_done_i,
        path_done_i     => path_done_i,
        freqPath_done_i => freqPath_done_i,
        start_cw_i      => start_cw_i,
        send_adc_data_i => send_adc_data_i,

        freq_val_i      => freq_val_i,
        ifbw_val_i      => ifbw_val_i,
        RF_power_i      => RF_power_i,
        LO_power_i      => LO_power_i,
        ATT_power_i     => ATT_power_i,
        path_tx_val_i   => path_tx_val_i(path_data_length_c - 1 downto 0),
        path_rx_val_i   => path_rx_val_i(path_data_length_c - 1 downto 0),
        cable_calFact_power_i => cable_calFact_power_i,
        path_calFact_freqPath_i => path_calFact_freqPath_i,
        tx1_vga_gain_i   => TX_VGA1_gain_i,
        rx1_vga_gain_i   => RX_VGA1_gain_i,
        rx2_vga_gain_i   => RX_VGA2_gain_i,
        synth_stability_delay_us_i => synth_stability_delay_us_i,

        sample_done_i   => sample_done_s,
        pll_locked_i    => synth_ready_s,
        switch_set_i    => sw_ready_s,
        switch_exception_i => sw_exception_s,
        synth_exception_i => synth_exception_s,
        mode_i         => mode_s,
        ADC_TX_data_i  => ADC_TX_s,
        ADC_RX_data_i  => ADC_RX_s,
        TX_ADC_sub_threshold_indicator_i => ADJUST_VGA_TX_ADC_sub_threshold_indicator_s,
        TX_ADC_sup_threshold_indicator_i => ADJUST_VGA_TX_ADC_sup_threshold_indicator_s,
        RX_ADC_sub_threshold_indicator_i => ADJUST_VGA_RX_ADC_sub_threshold_indicator_s,
        RX_ADC_sup_threshold_indicator_i => ADJUST_VGA_RX_ADC_sup_threshold_indicator_s,
        vga_to_subtract_if_sup_threshold_i => vga_to_subtract_if_sup_threshold_i,
        vga_to_add_if_sub_threshold_i => vga_to_add_if_sub_threshold_i,
        synth_stability_delay_for_vga_adjust_us_i => synth_stability_delay_for_vga_adjust_us_i,
        vga_power_adjust_enable_i => vga_power_adjust_enable_i,

        state_o         => state_s,

        synth_seq_id_o  => synth_seq_id_s,
        en_set_sw_o     => set_switch_s, 
        en_set_freq_o   => set_freq_s,
        en_set_att_power_o => set_att_power_s,
        en_set_vga_o    => set_vga_s,
        en_rf_o         => en_rf_s,
        sw_store_after_o  => sw_store_after_s, 
        sw_store_before_o  => sw_store_before_s, 
        exceptions_o    => PL_status_s,
        start_adc_average_o => start_adc_average_s,

        start_sample_o  => start_sample_s,

        IQ_rdy_PL_o     => IQ_rdy_PL_s,
        VNA_rdy_PL_o    => VNA_rdy_PL_o,
        write_IQ_o      => write_IQ_s,
        write_ADC_o     => write_ADC_s,
    
        freq_val_o      => freq_val_s,
        RF_power_o      => RF_power_s,
        LO_power_o      => LO_power_s,
        ATT_power_o     => ATT_power_s,
        ifbw_val_o      => ifbw_val_s,
        path_tx_val_o   => path_tx_val_s,
        path_rx_val_o   => path_rx_val_s,
        rx1_vga_gain_o   => RX1_VGA_gain_s,
        rx2_vga_gain_o   => RX2_VGA_gain_s,
        tx1_vga_gain_o   => TX1_VGA_gain_s,
        ADC_TX_buff_data_o => ADC_TX_buff_s,
        ADC_RX_buff_data_o => ADC_RX_buff_s,

        RF_CE_o         => RF_CE_o,
        LO_CE_o         => LO_CE_o
	);
    
    IQ_TX : IQ_demod
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        input_signal_i  => ADC_TX_s,
        start_i         => start_sample_s,
        smplNbr_i       => ifbw_val_s,
        sub_threshold_i => ADC_sub_threshold_i,
        sup_threshold_i => ADC_sup_threshold_i,
        done_o          => sampleTX_done_s,
        I_o             => I_TX_s,
        Q_o             => Q_TX_s,
        ADC_sub_threshold_indicator_o => ADC_TX_sub_threshold_indicator_s,
        ADC_sup_threshold_indicator_o => ADC_TX_sup_threshold_indicator_s,
        sine_0_o => open,
        sine_90_o => open
    );
    IQ_RX : IQ_demod
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        input_signal_i  => ADC_RX_s,
        start_i         => start_sample_s,
        smplNbr_i       => ifbw_val_s,
        sub_threshold_i => ADC_sub_threshold_i,
        sup_threshold_i => ADC_sup_threshold_i,
        done_o          => sampleRX_done_s,
        I_o             => I_RX_s,
        Q_o             => Q_RX_s,
        ADC_sub_threshold_indicator_o => ADC_RX_sub_threshold_indicator_s,
        ADC_sup_threshold_indicator_o => ADC_RX_sup_threshold_indicator_s,
        sine_0_o => open,
        sine_90_o => open
    );

    VGA_CTRL : VGA_controller
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        SPI_clock_speed_i => VGA_SPI_clock_speed_i,
        start_i         => set_vga_s,
        input_rx_i         => ADC_RX_s,
        input_tx_i         => ADC_TX_s,

        rdy_o           => vga_rdy_s,

        TX_VGA1_gain_o  => TX1_VGA_gain_o_s,
        RX_VGA1_gain_o  => RX1_VGA_gain_o_s,
        RX_VGA2_gain_o  => RX2_VGA_gain_o_s,

		TX_VGA1_gain_i => TX1_VGA_gain_s,
        RX_VGA1_gain_i => RX1_VGA_gain_s,
        RX_VGA2_gain_i => RX2_VGA_gain_s,

        SCLK_o              => VGA_SCLK_o,
        SDI_o               => VGA_SDI_o,

        CS_TX1_o            => TX1_VGA_CS_o,
        CS_RX1_o            => RX1_VGA_CS_o,
        CS_RX2_o            => RX2_VGA_CS_o
    );
    
    SYNTH_CONTROLLER_RF : SPI_synth_controller
    generic map (
        SYNTHESIZER         => LMX2594,
        RF_LO               => RF,
        BLOCK_PROGRAMMING   => NO,   --only avaiable for LMX2572
        BYPASS_SAME_ONES    => YES
    )
    port map ( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        SPI_clock_speed_i => SYNTH_SPI_clock_speed_i,
        seq_id_i        => synth_seq_id_s,
        start_seq_i     => set_freq_s,
        freq_i          => freq_val_s,
        offset_i        => offset_s,
        power_i         => RF_power_s,
        pll_locked_o    => RF_synth_pll_locked_s,
        seq_done_o      => RF_synth_seq_done_s,
        exception_o     => RF_synth_exception_s,
        MUXout_i        => RF_MUXout_i,
        SCK_o           => RF_SCK_o,
        SDI_o           => RF_SDI_o,
        CSB_o           => RF_CSB_o
    );

    SYNTH_CONTROLLER_LO : SPI_synth_controller
    generic map (
        SYNTHESIZER         => LMX2594,
        RF_LO               => LO,
        BLOCK_PROGRAMMING   => NO,   --only avaiable for LMX2572
        BYPASS_SAME_ONES    => YES
    )
    port map ( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        SPI_clock_speed_i => SYNTH_SPI_clock_speed_i,
        seq_id_i        => synth_seq_id_s,
        start_seq_i     => set_freq_s,
        freq_i          => freq_val_s,
        offset_i        => offset_s,
        power_i         => LO_power_s,
        pll_locked_o    => LO_synth_pll_locked_s,
        seq_done_o      => LO_synth_seq_done_s,
        exception_o     => LO_synth_exception_s,
        MUXout_i        => LO_MUXout_i,
        SCK_o           => LO_SCK_o,
        SDI_o           => LO_SDI_o,
        CSB_o           => LO_CSB_o
    );
    
    TILT_POSITION : tilt_position_controller
    port map (
        input_tilt_1    => input_tilt_1,
        input_tilt_2    => input_tilt_2,
        input_tilt_3    => input_tilt_3,
        output_tilt_o   => output_tilt_o
        
    );
    
    SEPARATION_DISTANCE : SPI_SPM_LA11D01
    generic map(
        SPI_CLK_DIVIDER     => 20,
        DATA_LENGTH         => 28
        )
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => '1',
        
        data_o          => SPM_data_o,
        
        MISO_i          => SPM_MISO_i,
        SCK_o           => SPM_SCLK_o,
        CSB_o           => SPM_CSB_o
        
    );
    
    SWITCH_REGISTER_TX : SPI_switch_controller
    generic map(
        PATH_DATA_LENGTH    => path_data_length_c
    )
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        read_back_i     => read_back_switch_array_i,
        SPI_clock_speed_i => SWITCH_ARRAY_SPI_clock_speed_i,
        start_seq_i     => set_switch_s,
        path_data_i     => path_tx_val_s,
        store_after_i   => sw_store_after_s,
        store_before_i  => sw_store_before_s,
        path_data_length_i => path_data_length_i,
        rdy_o           => sw_tx_rdy_s,
        exception_o     => sw_tx_exception_s,

        pico_o          => SWR_TX_SER_o,
        poci_i          => SWR_TX_SER_BACK_i,

        sck_o           => SWR_TX_SRCLK_o,
        srclr_n_o       => SWR_TX_SRCLR_o,

        --rclk_o          => open,
        rclr_n_o        => open,

        cs_o            => SWR_TX_RCLK_o
    );
    
    SWITCH_REGISTER_RX : SPI_switch_controller
    generic map(
        PATH_DATA_LENGTH    => path_data_length_c
    )
    port map (
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        read_back_i     => read_back_switch_array_i,
        SPI_clock_speed_i => SWITCH_ARRAY_SPI_clock_speed_i,
        start_seq_i     => set_switch_s,
        path_data_i     => path_rx_val_s,
        store_after_i   => sw_store_after_s,
        store_before_i  => sw_store_before_s,
        path_data_length_i => path_data_length_i,
        rdy_o           => sw_rx_rdy_s,
        exception_o     => sw_rx_exception_s,

        pico_o          => SWR_RX_SER_o,
        poci_i          => SWR_RX_SER_BACK_i,

        sck_o           => SWR_RX_SRCLK_o,
        srclr_n_o       => SWR_RX_SRCLR_o,

        --rclk_o          => open,
        rclr_n_o        => open,

        cs_o            => SWR_RX_RCLK_o
    );

    Filter_bank : filter_bank_controller
    port map(
        clk_i               => clk_i,
        reset_i             => reset_i,
        freq_i              => freq_val_s,
        en_i                => en_rf_s,
        throughput_i        => filter_bank_throughput_i,
        V_o                 => V_o
    );

    att_power_controller_comp : att_power_controller
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        SPI_clock_speed_i => ATTENUATOR_SPI_clock_speed_i,
        start_i         => set_att_power_s,
        power_i         => ATT_power_s,

        rdy_o           => att_seq_done_s,

        PAR_SER1_o      => PAR_SER1_o,
        SERIAL1_o       => SERIAL1_o,
        CLK1_o          => CLK1_o,
        LATCH_ENABLE1_o => LATCH_ENABLE1_o,

        CTRL2_o         => CTRL2_o
    );

    tx_average_adc_data_for_vga : average_ADC
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_adc_average_s,
        smplNbr_i       => vga_adjust_ifbw_c,
        adc_input_i     => ADC_TX_i,
        sub_threshold_i => ADC_sub_threshold_i,
        sup_threshold_i => ADC_sup_threshold_i,
        done_o          => tx_adc_average_done_s,
        ADC_sub_threshold_indicator_o => ADJUST_VGA_TX_ADC_sub_threshold_indicator_s,
        ADC_sup_threshold_indicator_o => ADJUST_VGA_TX_ADC_sup_threshold_indicator_s
    );

    rx_average_adc_data_for_vga : average_ADC
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_adc_average_s,
        smplNbr_i       => vga_adjust_ifbw_c,
        adc_input_i     => ADC_RX_i,
        sub_threshold_i => ADC_sub_threshold_i,
        sup_threshold_i => ADC_sup_threshold_i,
        done_o          => rx_adc_average_done_s,
        ADC_sub_threshold_indicator_o => ADJUST_VGA_RX_ADC_sub_threshold_indicator_s,
        ADC_sup_threshold_indicator_o => ADJUST_VGA_RX_ADC_sup_threshold_indicator_s
    );

end architecture mix;
