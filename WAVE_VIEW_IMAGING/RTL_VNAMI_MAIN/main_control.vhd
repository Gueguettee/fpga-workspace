LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity main_control is
    port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;
        
        start_i         : in std_logic;

        init_meas_i     : in std_logic;
        freq_done_i     : in std_logic;
        path_done_i     : in std_logic;
        freqPath_done_i : in std_logic;
        start_cw_i      : in std_logic;
        send_adc_data_i : in std_logic;

        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);
        att_power_i     : in std_logic_vector(att_power_data_length_c - 1 downto 0);
        RF_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        LO_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        cable_calFact_power_i : in std_logic_vector(calFact_power_cable_data_length_c - 1 downto 0);
        path_calFact_freqPath_i : in std_logic_vector(calFact_power_freqPath_data_length_c - 1 downto 0);
        rx1_vga_gain_i   : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        rx2_vga_gain_i   : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        tx1_vga_gain_i   : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        synth_stability_delay_us_i : in std_logic_vector(synth_stability_data_length_c-1 downto 0);

        sample_done_i   : in std_logic;
        pll_locked_i    : in std_logic;
        switch_set_i    : in std_logic;
        switch_exception_i : in std_logic;
        synth_exception_i : in std_logic;
        mode_i          : in mode_t;
        ADC_TX_data_i   : in std_logic_vector(ADC_data_length_c - 1 downto 0);
        ADC_RX_data_i   : in std_logic_vector(ADC_data_length_c - 1 downto 0);
        TX_ADC_sub_threshold_indicator_i : in std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        TX_ADC_sup_threshold_indicator_i : in std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        RX_ADC_sub_threshold_indicator_i : in std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        RX_ADC_sup_threshold_indicator_i : in std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        vga_to_subtract_if_sup_threshold_i : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
		vga_to_add_if_sub_threshold_i : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        synth_stability_delay_for_vga_adjust_us_i : in std_logic_vector(synth_stability_data_length_c - 1 downto 0);
        vga_power_adjust_enable_i : in std_logic_vector(vga_power_adjust_enable_data_length_c - 1 downto 0);

        state_o         : out std_logic_vector(3 downto 0);
        
        synth_seq_id_o  : out seq_id_t;
        en_set_sw_o     : out std_logic;
        sw_store_after_o  : out std_logic;
        sw_store_before_o  : out std_logic;
        en_set_freq_o   : out std_logic;
        en_set_att_power_o : out std_logic;
        en_set_vga_o    : out std_logic;
        en_rf_o         : out std_logic;
        start_adc_average_o : out std_logic;

        start_sample_o  : out std_logic;

        IQ_rdy_PL_o     : out std_logic;
        VNA_rdy_PL_o    : out std_logic;
        write_IQ_o      : out std_logic;   
        write_ADC_o     : out std_logic;
        exceptions_o    : out std_logic_vector(PL_status_data_length_c - 1 downto 0);     

        freq_val_o      : out std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_o      : out std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0);
        ATT_power_o     : out std_logic_vector(att_power_data_length_c - 1 downto 0);
        RF_power_o      : out std_logic_vector(synth_power_data_length_c - 1 downto 0);
        LO_power_o      : out std_logic_vector(synth_power_data_length_c - 1 downto 0);
        rx1_vga_gain_o   : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        rx2_vga_gain_o   : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        tx1_vga_gain_o   : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        ADC_TX_buff_data_o   : out std_logic_vector(ADC_data_length_c - 1 downto 0);
        ADC_RX_buff_data_o   : out std_logic_vector(ADC_data_length_c - 1 downto 0);

        RF_CE_o         : out std_logic;
        LO_CE_o         : out std_logic
    );
end entity main_control;
 
architecture mix of main_control is
    
--------------------------- SIGNALS ---------------------------
	type state_t is
	(
        WAIT_FOR_START_UP,
        START_UP,

        TEST_SW,
        TEST_SET_FREQ,
        TEST_GET_VCO,
        START_TEST_SET_FREQ_VCO,
        TEST_SET_FREQ_VCO,

        BACK_IDLE,
        IDLE,

        CW_BUFFER_DATA,
        CW_SEND_DATA,

        SET_SW,
        LATCH_AND_SET_NEXT_SW,
        SET_FREQ_VCO,
        TIMEOUT_AND_RESET,
        ADJUST_VGA,
        START_SAMPLE,
        RF_ON,
        CW_SEND_DATA2,
        IQ_READY,
        WRITE_IQ,

        INIT_MEAS,
        SAVE_FREQ,
        SAVE_PATH,
        SAVE_FREQ_PATH,

        SET_FREQ,
        GET_VCO
    );
    
    constant N_PERIOD_TO_WAIT_AT_START : integer := 10000 * clk_freq_mhz;
    signal wait_counter_s : integer range N_PERIOD_TO_WAIT_AT_START - 1 downto 0;

    constant SW_COUNTER_MAX : unsigned(path_data_length_c-1 downto 0) := (others => '1');
    signal sw_counter_s : unsigned(path_data_length_c-1 downto 0);
    
    constant MAX_RETRY_SW : integer := 2; -- 0 here could be failed maybe (lower it tests sw_exception_counter_s < MAX_RETRY_SW -> integer < 0 -> we don't know how it behaves)
    signal sw_exception_counter_s : integer range 0 to MAX_RETRY_SW;

    constant MAX_RETRY_SYNTH : integer := 2; -- 0 here could be failed maybe (lower it tests sw_exception_counter_s < MAX_RETRY_SYNTH -> integer < 0 -> we don't know how it behaves)
    signal synth_exception_counter_s : integer range 0 to MAX_RETRY_SYNTH;
    
    constant SYNTH_COUNTER_MAX : unsigned(freq_data_length_c-1 downto 0) := to_unsigned((fmax_div-fmin_div)/fstep_div, freq_data_length_c);
    signal synth_counter_s : unsigned(freq_data_length_c-1 downto 0);

    signal state_s          : state_t;
    signal freq_done_s      : std_logic;
    signal path_done_s      : std_logic;
    signal freqPath_done_s  : std_logic;

    signal freq_val_o_s     : std_logic_vector(freq_data_length_c - 1 downto 0);
    signal RF_power_o_s     : power_t;
    signal LO_power_o_s     : power_t;
    signal ATT_power_ram_s  : att_power_t;
    signal ATT_power_o_s    : att_power_t;
    signal cable_calFact_power_ram_s : std_logic_vector(calFact_power_cable_data_length_c - 1 downto 0);
    signal path_calFact_freqPath_power_o_s : std_logic_vector(calFact_power_freqPath_data_length_c - 1 downto 0);
    signal mode_s           : mode_t;

    signal path_rx_val_i_s  : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_tx_val_i_s  : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_rx_val_o_s  : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_tx_val_o_s  : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_rx_val_by_pass_o_s : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_tx_val_by_pass_o_s : std_logic_vector(path_data_length_c - 1 downto 0);
    signal freq_val_by_pass_o_s : std_logic_vector(freq_data_length_c - 1 downto 0);
    signal RF_power_by_pass_o_s     : power_t;
    signal LO_power_by_pass_o_s     : power_t;
    signal ATT_power_by_pass_o_s    : att_power_t;
    signal ifbw_val_s     : std_logic_vector(ifbw_data_length_c - 1 downto 0);
    signal rx1_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal rx2_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal tx1_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal rx1_vga_gain_by_pass_o_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal rx2_vga_gain_by_pass_o_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal tx1_vga_gain_by_pass_o_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal vga_to_subtract_if_sup_threshold_s : unsigned(vga_gain_data_length_c - 1 downto 0);
    signal vga_to_add_if_sub_threshold_s : unsigned(vga_gain_data_length_c - 1 downto 0);
    signal vga_power_adjust_enable_s : std_logic_vector(vga_power_adjust_enable_data_length_c - 1 downto 0);

    signal path_by_pass_RAM_s : std_logic;
    signal freq_by_pass_RAM_s : std_logic;
    signal power_by_pass_RAM_s : std_logic;
    signal vga_by_pass_RAM_s : std_logic;

    signal sw_exception_s : std_logic;
    signal synth_exception_s : std_logic;
    signal synth_exception_while_measurement_s : std_logic;

    signal only_one_frequency_power_s : std_logic;
    signal first_save_freq_s : std_logic;

    signal first_freq_s : std_logic_vector(freq_data_length_c - 1 downto 0);
    signal first_rx1_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal first_rx2_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal first_tx1_vga_gain_s : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
    signal first_ifbw_s : std_logic_vector(ifbw_data_length_c - 1 downto 0);
    signal first_att_power_s : std_logic_vector(att_power_data_length_c - 1 downto 0);

    signal first_measurement_loop_s : std_logic;

    signal cw_s : std_logic;
    signal cw_buffer_s : std_logic;
    signal cw_buffer_n_s : integer range 0 to CW_BUFFER_SIZE_CHAINED - 1;
    signal counter_max_s : unsigned(max_smpl_nmbr_c downto 0);

    signal send_adc_data_s : std_logic;

    signal ADC_RX_buff_data_s : ADC_Buffer_Array_t;
    signal ADC_TX_buff_data_s : ADC_Buffer_Array_t;

    signal synth_stability_delay_s : integer range 0 to (2**synth_stability_data_length_c - 1)*clk_freq_mhz;
    signal stability_counter_s : integer range 0 to (2**synth_stability_data_length_c - 1)*clk_freq_mhz;
    signal synth_stability_delay_for_vga_adjust_us_s : integer range 0 to (2**synth_stability_data_length_c - 1)*clk_freq_mhz;

    signal vga_adjust_done_s : std_logic;

    -- RAMs write and read enable
    signal freq_wr_en_s     : std_logic;
    signal path_wr_en_s     : std_logic;
    signal path_calFact_freqPath_wr_en_s : std_logic;

    signal freq_rd_en_s     : std_logic;
    signal path_rd_en_s     : std_logic;
    signal path_calFact_freqPath_rd_en_s : std_logic;

    -- RAMs address
    signal freq_RAM_wr_add_s   : unsigned(freq_addr_length_c - 1 downto 0);
    signal freq_RAM_rd_add_s   : unsigned(freq_addr_length_c - 1 downto 0);

    signal path_RAM_wr_add_s   : unsigned(path_addr_length_c - 1 downto 0);
    signal path_RAM_rd_add_s   : unsigned(path_addr_length_c - 1 downto 0);

    signal path_calFact_freqPath_RAM_wr_add_s   : unsigned(calFact_power_freqPath_addr_length_c - 1 downto 0);
    signal path_calFact_freqPath_RAM_rd_add_s   : unsigned(calFact_power_freqPath_addr_length_c - 1 downto 0);
	
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    --next state logic
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= WAIT_FOR_START_UP;
                wait_counter_s <= 0;
                sw_counter_s <= (others => '0');
                synth_counter_s <= (others => '0');
            
                freq_RAM_wr_add_s   <= (others => '0');
                freq_RAM_rd_add_s   <= (others => '0');
            
                path_RAM_wr_add_s   <= (others => '0');
                path_RAM_rd_add_s   <= (others => '0');

                path_calFact_freqPath_RAM_wr_add_s   <= (others => '0');
                path_calFact_freqPath_RAM_rd_add_s   <= (others => '0');

                IQ_rdy_PL_o     <= '0';
                VNA_rdy_PL_o    <= '0';
                write_IQ_o      <= '0';
                write_ADC_o     <= '0';
                
                sw_exception_counter_s <= 0;
                synth_exception_counter_s <= 0;
                sw_exception_s <= '0';
                synth_exception_s <= '0';
                synth_exception_while_measurement_s <= '0';

                path_tx_val_i_s  <= (others => '0');
                path_rx_val_i_s  <= (others => '0');

                en_set_sw_o     <= '0';
                en_set_freq_o   <= '0';
                en_set_att_power_o <= '0';
                en_set_vga_o    <= '0';

                RF_CE_o   <= '0';
                LO_CE_o   <= '0';

                path_by_pass_RAM_s <= '0';
                freq_by_pass_RAM_s <= '0';
                power_by_pass_RAM_s <= '0';
                vga_by_pass_RAM_s <= '0';

                path_rx_val_by_pass_o_s <= (others => '0');
                path_tx_val_by_pass_o_s <= (others => '0');
                freq_val_by_pass_o_s      <= (others => '0');
                RF_power_by_pass_o_s      <= (others => '0');
                LO_power_by_pass_o_s     <= (others => '0');
                ATT_power_by_pass_o_s    <= (others => '1');
                rx1_vga_gain_by_pass_o_s <= (others => '0');
                rx2_vga_gain_by_pass_o_s <= (others => '0');
                tx1_vga_gain_by_pass_o_s <= (others => '0');
                vga_to_subtract_if_sup_threshold_s <= (others => '0');
                vga_to_add_if_sub_threshold_s <= (others => '0');
                synth_stability_delay_for_vga_adjust_us_s <= 0;
                vga_power_adjust_enable_s <= (others => '0');
                synth_stability_delay_s <= 0;

                mode_s <= S21;

                only_one_frequency_power_s <= '1';
                first_save_freq_s <= '1';

                first_freq_s <= (others => '0');
                first_rx1_vga_gain_s <= (others => '0');
                first_rx2_vga_gain_s <= (others => '0');
                first_tx1_vga_gain_s <= (others => '0');
                first_ifbw_s <= (others => '0');
                first_att_power_s <= (others => '0');

                first_measurement_loop_s <= '1';

                cw_s <= '0';
                cw_buffer_s <= '0';
                cw_buffer_n_s <= 0;
                counter_max_s <= (others => '0');
                
                send_adc_data_s <= '0';

                en_rf_o         <= '0';     --used to put filter bank as a terminate resistor too

                stability_counter_s <= 0;

                start_adc_average_o <= '0';

                freq_done_s <= '0';
                vga_adjust_done_s <= '0';

            else
                IQ_rdy_PL_o     <= '0'; --in general, can change inside of certain states, in which it needs to be updated at each clock
                VNA_rdy_PL_o    <= '0';
                write_IQ_o      <= '0';
                write_ADC_o     <= '0';
                
                en_set_sw_o     <= '0';
                en_set_freq_o   <= '0';
                en_set_att_power_o <= '0';
                en_set_vga_o    <= '0';

                path_tx_val_i_s <= path_tx_val_i;
                path_rx_val_i_s <= path_rx_val_i;

                RF_CE_o   <= '1';
                LO_CE_o   <= '1';

                path_by_pass_RAM_s <= '0';
                freq_by_pass_RAM_s <= '0';
                power_by_pass_RAM_s <= '0';
                vga_by_pass_RAM_s <= '0';

                cw_buffer_s <= '0';

                start_adc_average_o <= '0';

                case state_s is
                    when WAIT_FOR_START_UP =>
                        power_by_pass_RAM_s <= '1';

                        if wait_counter_s < N_PERIOD_TO_WAIT_AT_START - 1 then
                            wait_counter_s <= wait_counter_s + 1;
                        else
                            state_s     <= START_UP;
                            en_set_sw_o     <= '1';
                            en_set_freq_o   <= '1';
                            en_set_att_power_o <= '1';
                        end if;

                    when START_UP =>
                        path_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            state_s     <= TEST_SW;
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            en_set_sw_o     <= '1';
                            sw_counter_s <= sw_counter_s + 1;
                            path_rx_val_by_pass_o_s <= std_logic_vector(sw_counter_s + 1);
                            path_tx_val_by_pass_o_s <= std_logic_vector(sw_counter_s + 1);
                        end if;

                    when TEST_SW =>
                        path_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if switch_set_i = '1' then
                            if sw_counter_s = 0 then
                                state_s <= TEST_SET_FREQ;
                                en_set_freq_o   <= '1';
                                freq_by_pass_RAM_s <= '1';
                            elsif sw_counter_s < SW_COUNTER_MAX then 
                                sw_counter_s <= sw_counter_s + 1;
                                path_rx_val_by_pass_o_s <= std_logic_vector(sw_counter_s + 1);
                                path_tx_val_by_pass_o_s <= std_logic_vector(sw_counter_s + 1);
                                en_set_sw_o     <= '1';
                            else
                                sw_counter_s <= (others => '0');
                                path_rx_val_by_pass_o_s <= (others => '0');
                                path_tx_val_by_pass_o_s <= (others => '0');
                                en_set_sw_o     <= '1';
                            end if;
                            if switch_exception_i = '1' then
                                sw_exception_s <= '1';
                                write_IQ_o      <= '1';
                            end if;
                        end if;

                    when TEST_SET_FREQ =>
                        freq_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            state_s     <= TEST_GET_VCO;
                            en_set_freq_o   <= '1';
                        end if;

                    when TEST_GET_VCO =>
                        freq_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            state_s     <= TEST_SET_FREQ;
                            en_set_freq_o   <= '1';
                            if synth_counter_s = SYNTH_COUNTER_MAX then
                                state_s <= START_TEST_SET_FREQ_VCO;
                                synth_counter_s <= (others => '0');
                                freq_val_by_pass_o_s <= (others => '0');
                            else
                                synth_counter_s <= synth_counter_s + 1;
                                freq_val_by_pass_o_s <= std_logic_vector(synth_counter_s + 1);
                            end if;
                        end if;

                    when START_TEST_SET_FREQ_VCO => --to add the forcing of VCO values
                        freq_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            state_s     <= TEST_SET_FREQ_VCO;
                            en_set_freq_o   <= '1';
                        end if;

                    when TEST_SET_FREQ_VCO =>
                        freq_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            if synth_counter_s = SYNTH_COUNTER_MAX then
                                state_s     <= BACK_IDLE;
                                freq_done_s <= not freq_done_i; --IQ_rdy_PL_o should be down at init
                                freq_by_pass_RAM_s <= '1';
                                power_by_pass_RAM_s <= '1';
                                freq_val_by_pass_o_s <= (others => '0');
                                en_set_freq_o   <= '1';
                                en_set_att_power_o <= '1';
                                sw_exception_s <= '0';
                                write_IQ_o      <= '1';
                            else
                                state_s     <= TEST_SET_FREQ_VCO;
                                en_set_freq_o   <= '1';
                                synth_counter_s <= synth_counter_s + 1;
                                freq_val_by_pass_o_s <= std_logic_vector(synth_counter_s + 1);
                            end if;
                        end if;

                    when IDLE =>
                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;
                        VNA_rdy_PL_o    <= '1';
                        cw_s <= '0';

                        if start_i = '1' or start_cw_i = '1' then
                            state_s     <= SET_SW;
                            en_set_sw_o     <= '1';
                            sw_exception_s <= '0';
                            synth_exception_s <= '0';
                            synth_exception_while_measurement_s <= '0';
                            sw_exception_counter_s <= 0;
                            freq_done_s <= not freq_done_i; --for first measure, no need to wait before update value
                            path_done_s <= path_done_i; --to go out the routine if path_done is toggled (avoid to get stuck in IQ_READY)
                            mode_s <= mode_i;
                            first_measurement_loop_s <= '1';
                            send_adc_data_s <= send_adc_data_i;
                            synth_stability_delay_s <= to_integer(unsigned(synth_stability_delay_us_i))*clk_freq_mhz;
                            vga_to_subtract_if_sup_threshold_s <= unsigned(vga_to_subtract_if_sup_threshold_i);
                            vga_to_add_if_sub_threshold_s <= unsigned(vga_to_add_if_sub_threshold_i);
                            synth_stability_delay_for_vga_adjust_us_s <= to_integer(unsigned(synth_stability_delay_for_vga_adjust_us_i))*clk_freq_mhz;
                            vga_power_adjust_enable_s <= vga_power_adjust_enable_i;

                            en_rf_o     <= '1';     --used to put filter bank as a terminate resistor too, don't touch it (issue VNAMSF-75)

                            if start_cw_i = '1' then
                                cw_s <= '1';
                            end if;

                        elsif init_meas_i = '1' then
                            state_s     <= INIT_MEAS;
                            freq_done_s <=  freq_done_i;
                            path_done_s <=  path_done_i;
                            freqPath_done_s <= freqPath_done_i;
                            synth_exception_s <= '0';
                            only_one_frequency_power_s <= '1';
                            first_save_freq_s <= '1';

                            -- Init read and write addresses to 0
                            freq_RAM_wr_add_s   <= (others => '0');
                            freq_RAM_rd_add_s   <= (others => '0');
                        
                            path_RAM_wr_add_s   <= (others => '0');
                            path_RAM_rd_add_s   <= (others => '0');

                            path_calFact_freqPath_RAM_wr_add_s   <= (others => '0');
                            path_calFact_freqPath_RAM_rd_add_s   <= (others => '0');

                        end if;

                    when CW_BUFFER_DATA =>
                        cw_buffer_s <= '1';
                        if cw_buffer_n_s = CW_BUFFER_SIZE_CHAINED - 1 then
                            state_s <= CW_SEND_DATA;
                            cw_buffer_n_s <= 0;
                            write_ADC_o      <= '1';
                            freq_done_s <= freq_done_i;
                        else
                            cw_buffer_n_s <= cw_buffer_n_s + 1;
                        end if;
                        
                    when CW_SEND_DATA =>
                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                        if (freq_done_s xor freq_done_i) = '1' then
                            if cw_buffer_n_s = CW_BUFFER_SIZE_CHAINED - 1 then
                                state_s <= CW_BUFFER_DATA;
                                cw_buffer_n_s <= 0;
                                cw_buffer_s <= '1';
                            else
                                cw_buffer_n_s <= cw_buffer_n_s + 1;
                                write_ADC_o      <= '1';
                                freq_done_s <= freq_done_i;
                                cw_buffer_s <= '1';
                                IQ_rdy_PL_o     <= '0';
                            end if;
                        end if;

                        if start_cw_i = '0' then
                            state_s     <= BACK_IDLE;
                            freq_done_s <= not freq_done_i; --IQ_rdy_PL_o should be down at init
                            freq_by_pass_RAM_s <= '1';
                            power_by_pass_RAM_s <= '1';
                            en_set_freq_o   <= '1';
                            en_set_att_power_o <= '1';
                        end if;

                    when SET_SW =>
                        if switch_set_i = '1' then
                            path_RAM_rd_add_s   <= path_RAM_rd_add_s + 1;
                            state_s             <= LATCH_AND_SET_NEXT_SW;
                            en_set_sw_o     <= '1';
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when LATCH_AND_SET_NEXT_SW =>
                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= 0;
                        end if;

                        if switch_set_i = '1' then
                            if switch_exception_i = '1' and sw_exception_counter_s < MAX_RETRY_SW then
                                state_s <= SET_SW;
                                path_RAM_rd_add_s   <= path_RAM_rd_add_s - 1;
                                sw_exception_counter_s <= sw_exception_counter_s + 1;
                                en_set_sw_o     <= '1';
                            else
                                if switch_exception_i = '1' then
                                    sw_exception_s <= '1';
                                else
                                    sw_exception_s <= '0';
                                end if;
                                if first_measurement_loop_s = '1' or only_one_frequency_power_s = '0' then
                                    state_s <= SET_FREQ_VCO;
                                    en_set_freq_o   <= '1';
                                    en_set_att_power_o <= '1';
                                    en_set_vga_o    <= '1';
                                    synth_exception_counter_s <= 0;
                                else
                                    state_s     <= TIMEOUT_AND_RESET;
                                    stability_counter_s <= 0;
                                    vga_adjust_done_s <= '0';
                                end if;
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when SET_FREQ_VCO =>
                        if send_adc_data_s = '1' or cw_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= 0;
                        end if;
                        stability_counter_s <= 0;
                        vga_adjust_done_s <= '0';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                if synth_exception_counter_s < MAX_RETRY_SYNTH then
                                    en_set_freq_o   <= '1';
                                    synth_exception_counter_s <= synth_exception_counter_s + 1;
                                else
                                    synth_exception_while_measurement_s <= '1';
                                    if cw_s = '1' then
                                        state_s    <= CW_BUFFER_DATA;
                                    else
                                        state_s     <= TIMEOUT_AND_RESET;
                                    end if;
                                end if;
                            else
                                synth_exception_while_measurement_s <= '0';
                                if cw_s = '1' then
                                    state_s    <= CW_BUFFER_DATA;
                                else
                                    state_s     <= TIMEOUT_AND_RESET;
                                end if;
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when TIMEOUT_AND_RESET =>
                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= 0;
                        end if;

                        if stability_counter_s = synth_stability_delay_s then
                            if vga_adjust_done_s = '1' then
                                state_s <= ADJUST_VGA;
                                en_set_vga_o    <= '1';
                                vga_by_pass_RAM_s <= '1';
                            elsif vga_power_adjust_enable_s(VGA_ADJUST_ENABLE) = '0' then
                                state_s <= ADJUST_VGA;
                            end if;
                        else
                            if stability_counter_s = synth_stability_delay_for_vga_adjust_us_s and vga_power_adjust_enable_s(VGA_ADJUST_ENABLE) = '1' then
                                start_adc_average_o <= '1';
                            end if;
                            stability_counter_s <= stability_counter_s + 1;
                        end if;
                        
                        if pll_locked_i = '1' then
                            vga_adjust_done_s <= '1';
                            tx1_vga_gain_by_pass_o_s <= tx1_vga_gain_s;
                            rx1_vga_gain_by_pass_o_s <= rx1_vga_gain_s;
                            rx2_vga_gain_by_pass_o_s <= rx2_vga_gain_s;
                            if to_integer(unsigned(TX_ADC_sup_threshold_indicator_i)) > 0 then
                                if unsigned(tx1_vga_gain_s) <= "11110" - vga_to_subtract_if_sup_threshold_s then
                                    tx1_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(tx1_vga_gain_s) + vga_to_subtract_if_sup_threshold_s);
                                else
                                    tx1_vga_gain_by_pass_o_s <= "11110";
                                end if;
                            elsif to_integer(unsigned(TX_ADC_sub_threshold_indicator_i)) > 6 * (to_integer(unsigned(vga_adjust_ifbw_c)) + 1) then
                                if unsigned(tx1_vga_gain_s) >= vga_to_add_if_sub_threshold_s then
                                    tx1_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(tx1_vga_gain_s) - vga_to_add_if_sub_threshold_s);
                                else
                                    tx1_vga_gain_by_pass_o_s <= "00000";
                                end if;
                            end if;
                            if to_integer(unsigned(RX_ADC_sup_threshold_indicator_i)) > 0 then
                                if unsigned(rx1_vga_gain_s) <= "11110" - vga_to_subtract_if_sup_threshold_s then
                                    rx1_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(rx1_vga_gain_s) + vga_to_subtract_if_sup_threshold_s);
                                else
                                    rx1_vga_gain_by_pass_o_s <= "11110";
                                    if unsigned(rx2_vga_gain_s) <= "11110" - (unsigned(rx1_vga_gain_s) - ("11110" - vga_to_subtract_if_sup_threshold_s)) then
                                        rx2_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(rx2_vga_gain_s) + (unsigned(rx1_vga_gain_s) - ("11110" - vga_to_subtract_if_sup_threshold_s)));
                                    else
                                        rx2_vga_gain_by_pass_o_s <= "11110";
                                    end if;
                                end if;
                            elsif to_integer(unsigned(RX_ADC_sub_threshold_indicator_i)) > 6 * (to_integer(unsigned(vga_adjust_ifbw_c)) + 1) then
                                if unsigned(rx1_vga_gain_s) >= vga_to_add_if_sub_threshold_s then
                                    rx1_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(rx1_vga_gain_s) - vga_to_add_if_sub_threshold_s);
                                else
                                    rx1_vga_gain_by_pass_o_s <= "00000";
                                    if unsigned(rx2_vga_gain_s) >= "00000" + (vga_to_add_if_sub_threshold_s - unsigned(rx1_vga_gain_s)) then
                                        rx2_vga_gain_by_pass_o_s <= std_logic_vector(unsigned(rx2_vga_gain_s) - (vga_to_add_if_sub_threshold_s - unsigned(rx1_vga_gain_s)));
                                    else
                                        rx2_vga_gain_by_pass_o_s <= "00000";
                                    end if;
                                end if;
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when ADJUST_VGA =>
                        if vga_power_adjust_enable_s(VGA_ADJUST_ENABLE) = '1' then
                            vga_by_pass_RAM_s <= '1';
                        end if;
                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= 0;
                        end if;

                        if pll_locked_i = '1' or vga_power_adjust_enable_s(VGA_ADJUST_ENABLE) = '0' then
                            state_s <= START_SAMPLE;
                            --update addresses for next values (values are loaded in state IQ_READY)
                            if freq_RAM_rd_add_s = (freq_RAM_wr_add_s - 1) then
                                freq_RAM_rd_add_s   <= (others => '0');
                                path_RAM_rd_add_s   <= path_RAM_rd_add_s + 1;
                            else
                                freq_RAM_rd_add_s   <= freq_RAM_rd_add_s + 1;
                            end if;
                            path_calFact_freqPath_RAM_rd_add_s   <= path_calFact_freqPath_RAM_rd_add_s + 1;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when START_SAMPLE =>    --This state is to avoid reading 1 directly on sample_done_i as it is set to 0 only after start_sample 
                        if sample_done_i = '0' then
                            state_s     <= RF_ON;
                        end if;

                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= cw_buffer_n_s + 1;
                            counter_max_s   <= shift_left(to_unsigned(8, max_smpl_nmbr_c+1), to_integer(unsigned(ifbw_val_s)));   --8*(2^smplNbr_i) -> verified
                        end if;

                        first_measurement_loop_s <= '0';

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when RF_ON =>
                        if send_adc_data_s = '1' then
                            if cw_buffer_n_s < CW_BUFFER_SIZE_CHAINED - 1 and to_unsigned(cw_buffer_n_s, max_smpl_nmbr_c+1) < counter_max_s - 1 then
                                cw_buffer_s <= '1';
                                cw_buffer_n_s <= cw_buffer_n_s + 1;
                            end if;
                        end if;

                        if sample_done_i = '1' then 
                            if send_adc_data_s = '1' then
                                state_s     <= CW_SEND_DATA2;
                                cw_buffer_n_s <= 0;
                            else
                                state_s     <= IQ_READY;
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when CW_SEND_DATA2 =>
                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                        if (freq_done_i xor freq_done_s) = '1' then --wait for PS to have read the last IQ value before update with the first ADC data
                            if cw_buffer_n_s = CW_BUFFER_SIZE_CHAINED - 1 then
                                state_s <= IQ_READY;
                                cw_buffer_n_s <= 0;
                            else
                                cw_buffer_n_s <= cw_buffer_n_s + 1;
                            end if;
                            write_ADC_o     <= '1';
                            freq_done_s     <= freq_done_i;
                            cw_buffer_s     <= '1';
                            IQ_rdy_PL_o     <= '0';
                        end if;
                        if (path_done_i xor path_done_s) = '1' then --if path_done toggle -> back to IDLE (to stop the routine from PS)
                            state_s <= BACK_IDLE;
                            freq_done_s     <= not freq_done_i; --IQ_rdy_PL_o low in IDLE
                            IQ_rdy_PL_o     <= '0';
                            write_IQ_o      <= '1';
                            freq_by_pass_RAM_s <= '1';
                            power_by_pass_RAM_s <= '1';
                            en_set_freq_o   <= '1';
                            en_set_att_power_o <= '1';
                        end if;

                    when IQ_READY =>
                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                        end if;

                        if (freq_done_i xor freq_done_s) = '1' then --wait for PS to have read the last value before update with the new one
                            freq_done_s <= freq_done_i;
                            IQ_rdy_PL_o     <= '0';
                            write_IQ_o      <= '1';
                            state_s     <= WRITE_IQ;
                        end if;
                        if (path_done_i xor path_done_s) = '1' then --if path_done toggle -> back to IDLE (to stop the routine from PS)
                            state_s <= BACK_IDLE;
                            freq_done_s         <= not freq_done_i; --IQ_rdy_PL_o low in IDLE
                            IQ_rdy_PL_o     <= '0';
                            write_IQ_o      <= '1';
                            freq_by_pass_RAM_s <= '1';
                            power_by_pass_RAM_s <= '1';
                            en_set_freq_o   <= '1';
                            en_set_att_power_o <= '1';
                        end if;

                    when WRITE_IQ =>
                        if send_adc_data_s = '1' then
                            cw_buffer_s <= '1';
                            cw_buffer_n_s <= 0;
                        end if;

                        if path_RAM_rd_add_s = path_RAM_wr_add_s + 1 then --check if it was the last path (if next path is out of initialized RAM)
                            state_s <= BACK_IDLE;
                            freq_by_pass_RAM_s <= '1';
                            power_by_pass_RAM_s <= '1';
                            en_set_freq_o   <= '1';
                            en_set_att_power_o <= '1';
                        elsif freq_RAM_rd_add_s = 0 then --if next frequency is the first of the list, change path before frequency
                            state_s <= LATCH_AND_SET_NEXT_SW;
                            en_set_sw_o     <= '1';
                            sw_exception_counter_s <= 0;
                        else
                            --next frequency
                            if only_one_frequency_power_s = '0' then
                                state_s <= SET_FREQ_VCO;
                                en_set_freq_o   <= '1';
                                en_set_att_power_o <= '1';
                                en_set_vga_o    <= '1';
                                synth_exception_counter_s <= 0;
                            else
                                state_s     <= TIMEOUT_AND_RESET;
                                stability_counter_s <= 0;
                                vga_adjust_done_s <= '0';
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= '1';

                    when INIT_MEAS =>
                        if init_meas_i = '0' then
                            state_s     <= SET_FREQ;
                            en_set_freq_o   <= '1';
                            power_by_pass_RAM_s <= '1';
                            freq_done_s <= not freq_done_i;
                        elsif (freq_done_i xor freq_done_s) = '1' then
                            state_s     <= SAVE_FREQ;
                            freq_done_s <= freq_done_i;
                            if first_save_freq_s = '1' then
                                first_save_freq_s <= '0';
                                first_freq_s <= freq_val_i;
                                first_rx1_vga_gain_s <= rx1_vga_gain_i;
                                first_rx2_vga_gain_s <= rx2_vga_gain_i;
                                first_tx1_vga_gain_s <= tx1_vga_gain_i;
                                first_ifbw_s <= ifbw_val_i;
                                first_att_power_s <= att_power_i;
                            else
                                if freq_val_i /= first_freq_s then
                                    only_one_frequency_power_s <= '0';
                                elsif rx1_vga_gain_i /= first_rx1_vga_gain_s then
                                    only_one_frequency_power_s <= '0';
                                elsif rx2_vga_gain_i /= first_rx2_vga_gain_s then
                                    only_one_frequency_power_s <= '0';
                                elsif tx1_vga_gain_i /= first_tx1_vga_gain_s then
                                    only_one_frequency_power_s <= '0';
                                elsif ifbw_val_i /= first_ifbw_s then
                                    only_one_frequency_power_s <= '0';
                                elsif att_power_i /= first_att_power_s then
                                    only_one_frequency_power_s <= '0';
                                end if;
                            end if;
                        elsif (path_done_i xor path_done_s) = '1' then
                            state_s     <= SAVE_PATH;
                            path_done_s <= path_done_i;
                        elsif (freqPath_done_i xor freqPath_done_s) = '1' then
                            state_s     <= SAVE_FREQ_PATH;
                            freqPath_done_s <= freqPath_done_i;
                        end if;

                    when SAVE_FREQ =>
                        state_s <= INIT_MEAS;

                        freq_RAM_wr_add_s   <= freq_RAM_wr_add_s + 1;
                    
                    when SAVE_PATH =>
                        state_s <= INIT_MEAS;

                        path_RAM_wr_add_s   <= path_RAM_wr_add_s + 1;

                    when SAVE_FREQ_PATH =>
                        state_s <= INIT_MEAS;

                        path_calFact_freqPath_RAM_wr_add_s   <= path_calFact_freqPath_RAM_wr_add_s + 1;

                    when SET_FREQ =>
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            state_s     <= GET_VCO;
                            en_set_freq_o   <= '1';
                        end if;

                    when GET_VCO =>
                        power_by_pass_RAM_s <= '1';

                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            if freq_RAM_rd_add_s = (freq_RAM_wr_add_s - 1) then
                                state_s     <= BACK_IDLE;
                                freq_done_s         <= not freq_done_i; --IQ_rdy_PL_o low in IDLE
                                freq_by_pass_RAM_s <= '1';
                                en_set_freq_o   <= '1';
                                en_set_att_power_o <= '1';
                            else
                                state_s     <= SET_FREQ;
                                freq_RAM_rd_add_s   <= freq_RAM_rd_add_s + 1;
                                en_set_freq_o   <= '1';
                            end if;
                        end if;

                    when BACK_IDLE =>
                        freq_by_pass_RAM_s <= '1';
                        power_by_pass_RAM_s <= '1';

                        -- reset read adresses 
                        freq_RAM_rd_add_s   <= (others => '0');
                        path_RAM_rd_add_s   <= (others => '0');
                        path_calFact_freqPath_RAM_rd_add_s   <= (others => '0');

                        mode_s <= S21;
                        
                        if pll_locked_i = '1' then
                            if synth_exception_i = '1' then
                                synth_exception_s <= '1';
                            end if;
                            en_rf_o     <= '0';     --used to put filter bank as a terminate resistor too, don't touch it (issue VNAMSF-75)
                            state_s     <= IDLE;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;
                        
                    when others =>
                        state_s     <= IDLE;
                end case;
            end if;
        end if;
    end process;

    --output logic
    process(state_s)
    begin

        state_o         <= "0000";
        synth_seq_id_o  <= SEQ_ID_INIT;
        start_sample_o  <= '0';
        sw_store_before_o  <= '0';
        sw_store_after_o  <= '0';

        freq_wr_en_s    <= '0';
        path_wr_en_s    <= '0';
        path_calFact_freqPath_wr_en_s <= '0';

        freq_rd_en_s    <= '0';
        path_rd_en_s    <= '0';
        path_calFact_freqPath_rd_en_s <= '0';
            
        case state_s is
            when WAIT_FOR_START_UP =>
                state_o         <= "1111";

            when START_UP =>
                state_o         <= "0001";

            when TEST_SW =>
                state_o <= "0010";
                sw_store_before_o  <= '1';

            when TEST_SET_FREQ =>
                state_o <= "0011";
                synth_seq_id_o  <= SEQ_ID_SET_FREQ;

            when TEST_GET_VCO =>
                state_o <= "0100";
                synth_seq_id_o  <= SEQ_ID_READ_VCO;

            when START_TEST_SET_FREQ_VCO =>
                state_o <= "0101";
                synth_seq_id_o  <= SEQ_ID_IDLE;

            when TEST_SET_FREQ_VCO =>
                state_o <= "0110";
                synth_seq_id_o  <= SEQ_ID_SET_FREQ_VCO;

            when IDLE =>
                state_o         <= "1000";

                freq_rd_en_s    <= '1';
                path_rd_en_s    <= '1';
                path_calFact_freqPath_rd_en_s <= '1';

            when CW_BUFFER_DATA =>
                state_o         <= "0001";

            when CW_SEND_DATA =>
                state_o         <= "0011";

            when SET_SW =>
                state_o         <= "1001";
                path_rd_en_s    <= '1';

            when LATCH_AND_SET_NEXT_SW =>
                state_o         <= "1010";
                sw_store_before_o  <= '1';
                path_rd_en_s    <= '1';

            when SET_FREQ_VCO =>
                state_o         <= "1011";
                synth_seq_id_o  <= SEQ_ID_SET_FREQ_VCO;

            when TIMEOUT_AND_RESET =>
                state_o         <= "1100";

            when ADJUST_VGA =>
                state_o         <= "1100";

            when START_SAMPLE =>
                state_o         <= "1100";
                start_sample_o  <= '1';

            when RF_ON =>
                state_o         <= "1101";

            when CW_SEND_DATA2 =>
                state_o         <= "0011";

            when IQ_READY =>
                state_o         <= "1110";
                
                -- Load next values for synthesizer and SW (for next measurement)
                freq_rd_en_s    <= '1';
                path_rd_en_s    <= '1';
                path_calFact_freqPath_rd_en_s <= '1';

            when WRITE_IQ =>
                state_o         <= "1000";

            when INIT_MEAS =>
                state_o         <= "0001";

            when SAVE_FREQ =>
                state_o         <= "0010";
                freq_wr_en_s    <= '1';
            
            when SAVE_PATH =>
                state_o         <= "0011";
                path_wr_en_s    <= '1';

            when SAVE_FREQ_PATH =>
                state_o         <= "0100";
                path_calFact_freqPath_wr_en_s <= '1';

            when SET_FREQ =>
                state_o         <= "0101";
                freq_rd_en_s    <= '1';
                synth_seq_id_o  <= SEQ_ID_SET_FREQ;

            when GET_VCO =>
                state_o         <= "0110";
                synth_seq_id_o  <= SEQ_ID_READ_VCO;

            when BACK_IDLE =>
                state_o         <= "0111";
                synth_seq_id_o  <= SEQ_ID_IDLE;

            when others =>
                state_o         <= "0000";
            end case;
    end process;

    process(ATT_power_ram_s, path_calFact_freqPath_power_o_s, cable_calFact_power_ram_s, mode_s)
    begin
        ATT_power_o_s     <= std_logic_vector(unsigned(ATT_power_ram_s));
        if resize(unsigned(path_calFact_freqPath_power_o_s), att_power_data_length_c) + resize(unsigned(cable_calFact_power_ram_s), att_power_data_length_c) <= unsigned(ATT_power_ram_s) and (mode_s = S21 or mode_s = S11) then
            ATT_power_o_s     <= std_logic_vector(unsigned(ATT_power_ram_s) - resize(unsigned(path_calFact_freqPath_power_o_s), att_power_data_length_c) - resize(unsigned(cable_calFact_power_ram_s), att_power_data_length_c));
        end if;
    end process;

    exceptions_o(SW_EXCEPTION_BIT) <= sw_exception_s;
    exceptions_o(SYNTH_EXCEPTION_BIT) <= synth_exception_s;
    exceptions_o(SYNTH_EXCEPTION_WHILE_MEASUREMENT_BIT) <= synth_exception_while_measurement_s;

    FREQ_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => freq_data_length_c,
        ADDR_LENGTH     => freq_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => freq_val_i,
        data_o      => freq_val_o_s
    );
    freq_val_o <= freq_val_o_s when freq_by_pass_RAM_s = '0' else freq_val_by_pass_o_s;

    IFBW_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => ifbw_data_length_c,
        ADDR_LENGTH     => ifbw_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => ifbw_val_i,
        data_o      => ifbw_val_s
    );
    ifbw_val_o <= ifbw_val_s;

    RX1_VGA_GAIN_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => vga_gain_data_length_c,
        ADDR_LENGTH     => vga_gain_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => rx1_vga_gain_i,
        data_o      => rx1_vga_gain_s
    );
    rx1_vga_gain_o <= rx1_vga_gain_s when vga_by_pass_RAM_s = '0' else rx1_vga_gain_by_pass_o_s;

    RX2_VGA_GAIN_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => vga_gain_data_length_c,
        ADDR_LENGTH     => vga_gain_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => rx2_vga_gain_i,
        data_o      => rx2_vga_gain_s
    );
    rx2_vga_gain_o <= rx2_vga_gain_s when vga_by_pass_RAM_s = '0' else rx2_vga_gain_by_pass_o_s;

    TX1_VGA_GAIN_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => vga_gain_data_length_c,
        ADDR_LENGTH     => vga_gain_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => tx1_vga_gain_i,
        data_o      => tx1_vga_gain_s
    );
    tx1_vga_gain_o <= tx1_vga_gain_s when vga_by_pass_RAM_s = '0' else tx1_vga_gain_by_pass_o_s;

    ATTENUATOR_POWER_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => att_power_data_length_c,
        ADDR_LENGTH     => att_power_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => att_power_i,
        data_o      => ATT_power_ram_s
    );
    ATT_power_o <= ATT_power_o_s when power_by_pass_RAM_s = '0' else ATT_power_by_pass_o_s;

    RF_POWER_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => synth_power_data_length_c,
        ADDR_LENGTH     => power_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => RF_power_i,
        data_o      => RF_power_o_s
    );
    RF_power_o <= RF_power_o_s when power_by_pass_RAM_s = '0' else RF_power_by_pass_o_s;

    LO_POWER_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => synth_power_data_length_c,
        ADDR_LENGTH     => power_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => LO_power_i,
        data_o      => LO_power_o_s
    );
    LO_power_o <= LO_power_o_s when power_by_pass_RAM_s = '0' else LO_power_by_pass_o_s;

    TX_PATH_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => path_data_length_c,
        ADDR_LENGTH     => path_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => path_wr_en_s,
        rd_en_i     => path_rd_en_s,
        wr_addr_i   => std_logic_vector(path_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(path_RAM_rd_add_s),
        data_i      => path_tx_val_i_s,
        data_o      => path_tx_val_o_s
    );
    path_tx_val_o <= path_tx_val_o_s when path_by_pass_RAM_s = '0' else path_tx_val_by_pass_o_s;

    RX_PATH_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => path_data_length_c,
        ADDR_LENGTH     => path_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => path_wr_en_s,
        rd_en_i     => path_rd_en_s,
        wr_addr_i   => std_logic_vector(path_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(path_RAM_rd_add_s),
        data_i      => path_rx_val_i_s,
        data_o      => path_rx_val_o_s
    );
    path_rx_val_o <= path_rx_val_o_s when path_by_pass_RAM_s = '0' else path_rx_val_by_pass_o_s;

    TX_Path_CalFact_freqPath_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => calFact_power_freqPath_data_length_c,
        ADDR_LENGTH     => calFact_power_freqPath_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => path_calFact_freqPath_wr_en_s,
        rd_en_i     => path_calFact_freqPath_rd_en_s,
        wr_addr_i   => std_logic_vector(path_calFact_freqPath_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(path_calFact_freqPath_RAM_rd_add_s),
        data_i      => path_calFact_freqPath_i,
        data_o      => path_calFact_freqPath_power_o_s
    );

    TX_Cable_CalFact_freqPath_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => calFact_power_cable_data_length_c,
        ADDR_LENGTH     => att_power_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => cable_calFact_power_i,
        data_o      => cable_calFact_power_ram_s
    );

    ADC_RX_buff_data_s(0) <= ADC_RX_data_i;
    ADC_RX_buff_data_o <= ADC_RX_buff_data_s(CW_N_ADC_CHAINED_BUFFERS);

    ADC_TX_buff_data_s(0) <= ADC_TX_data_i;
    ADC_TX_buff_data_o <= ADC_TX_buff_data_s(CW_N_ADC_CHAINED_BUFFERS);

    chained_shift_regs : for i in 0 to CW_N_ADC_CHAINED_BUFFERS-1 generate
    begin
        -- Instantiate each shift register and connect inputs/outputs dynamically based on `i`
        ADC_RX_data_buffer : c_shift_ram_0
            port map (
                D => ADC_RX_buff_data_s(i),  -- First shift register gets ADC_RX_data_i, others get previous register output
                CLK => clk_i,
                CE => cw_buffer_s,
                Q => ADC_RX_buff_data_s(i+1)  -- Connect output of this shift register to input of next
            );
        ADC_TX_data_buffer : c_shift_ram_0
            port map (
                D => ADC_TX_buff_data_s(i),  -- First shift register gets ADC_TX_data_i, others get previous register output
                CLK => clk_i,
                CE => cw_buffer_s,
                Q => ADC_TX_buff_data_s(i+1)  -- Connect output of this shift register to input of next
            );
    end generate chained_shift_regs;

end architecture mix;
