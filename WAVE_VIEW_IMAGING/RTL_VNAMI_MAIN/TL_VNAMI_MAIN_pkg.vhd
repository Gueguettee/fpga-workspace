library ieee;
use ieee.std_logic_1164.all;
use work.main_control_pkg.all;
use work.SPI_synth_pkg.all;

package TL_VNAMI_MAIN_pkg is

-------------------------- CONSTANTS ------------------------- 


-------------------------- COMPONENTS ------------------------- 

    component edge_detector is
        port (
            clk_i                       : in  std_logic;
            reset_i                     : in  std_logic;
            input_i                     : in  std_logic;
            pulse_o                     : out std_logic
        );
    end component;

    component sp_RAM is
        generic(
            DATA_LENGTH         : integer := 8;
            ADDR_LENGTH         : integer := 8
        );
        port
        (
            clk_i       :in  std_logic;
            rst_i       :in  std_logic;
            wr_en_i     :in  std_logic;
            rd_en_i     :in  std_logic;
            wr_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
            rd_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
            data_i      :in  std_logic_vector(DATA_LENGTH - 1 downto 0);
            data_o      :out std_logic_vector(DATA_LENGTH - 1 downto 0)
        );
    end component;

    component main_control is
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
        ATT_power_i     : in std_logic_vector(att_power_data_length_c - 1 downto 0);
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
    end component main_control;
    
    component IQ_demod is
    port(
		clk_i             : in std_logic;
		reset_i           : in std_logic;
		
		input_signal_i    : in std_logic_vector(ADC_data_length_c - 1 downto 0);
		start_i           : in std_logic;
		smplNbr_i         : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        sub_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        sup_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
		
		done_o            : out std_logic;

		I_o               : out std_logic_vector(26 downto 0);
		Q_o               : out std_logic_vector(26 downto 0);

        ADC_sub_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        ADC_sup_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);

        sine_0_o    : out std_logic_vector(ADC_data_length_c - 1 downto 0);
        sine_90_o   : out std_logic_vector(ADC_data_length_c - 1 downto 0)
		
	);
    end component IQ_demod;
    
    component PLL is
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        reset_o     : out std_logic;
        clk_100M_o  : out std_logic;
        clk_40M_o   : out std_logic;
        clk_80M_o   : out std_logic;
        clk_10M_o   : out std_logic
    );
    end component PLL;

    component SPI_switch_controller is
        generic(
            PATH_DATA_LENGTH    : integer := path_data_length_c --only multiple of 8 allowed
        );
        port(
            clk_i           : in std_logic;
            reset_i         : in std_logic;
    
            --intern inputs/outputs (from main control,etc)
            read_back_i     : in std_logic;
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
    end component SPI_switch_controller;

    component SPI_switch_driver is
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
    end component SPI_switch_driver;
    
    component SPI_synth_controller is
        generic(
            SYNTHESIZER         : synthesizer_t := LMX2594;
            RF_LO               : RF_LO_t := RF;
            BLOCK_PROGRAMMING   : boolean_t := NO;   --only avaiable for LMX2572
            BYPASS_SAME_ONES    : boolean_t := YES
        );
        port(
            clk_i           : in std_logic;
            reset_i         : in std_logic;
            
            --intern inputs/outputs (from main control,etc)
            SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
            seq_id_i        : in seq_id_t;
            start_seq_i     : in std_logic;
            freq_i          : in std_logic_vector(freq_data_length_c-1 downto 0);
            offset_i        : in offset_t;
            power_i         : in power_t;

            pll_locked_o    : out std_logic;
            seq_done_o      : out std_logic;
            exception_o     : out std_logic;

            --external input outputs(physical)
            MUXout_i        : in std_logic;

            SCK_o           : out std_logic;
            SDI_o           : out std_logic;
            CSB_o           : out std_logic
        );
    end component SPI_synth_controller;
    
    component tilt_position_controller is
    port (
        input_tilt_1    : in std_logic;
        input_tilt_2    : in std_logic;
        input_tilt_3    : in std_logic;
        output_tilt_o   : out std_logic_vector(2 downto 0)
    );
    end component tilt_position_controller;

    component att_power_controller is
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
    end component att_power_controller;
    
    component att_PE43705_driver is
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
    end component att_PE43705_driver;
    
    component SPI_SPM_LA11D01 is
    generic(
        SPI_CLK_DIVIDER     : integer := 18;
        DATA_LENGTH         : integer := 28
    );
    port (
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        
        data_o              : out std_logic_vector(27 downto 0);
        
        MISO_i              : in std_logic;
        SCK_o               : out std_logic;
        CSB_o               : out std_logic
    );
    end component SPI_SPM_LA11D01;

    component freq_decoder is
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;
            
            freq_i              : in std_logic_vector(freq_data_length_c-1 downto 0);
            freq_o              : out freq_t
        );
    end component freq_decoder;
    
    component filter_bank_controller is
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
    
        --intern inputs/outputs (from main control,etc)
        freq_i : in std_logic_vector(freq_data_length_c - 1 downto 0);
        en_i   : in std_logic;
        throughput_i : in std_logic;
    
        --external input outputs(physical)
        V_o : out std_logic_vector(filter_bank_controller_output_length_c-1 downto 0) --V4 (= MSB) to V1 (= LSB)
    );
    end component filter_bank_controller;

    component VGA_controller is
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;

            --intern inputs/outputs (from main control,etc)
            SPI_clock_speed_i   : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
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
    end component VGA_controller;

    COMPONENT c_shift_ram_0
        PORT (
            D : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
            CLK : IN STD_LOGIC;
            CE : IN STD_LOGIC;
            Q : OUT STD_LOGIC_VECTOR(13 DOWNTO 0) 
        );
    END COMPONENT;

    component average_IQ
        generic(
            BIT_WIDTH   : integer := 27
        );
        port(
            clk_i       : in std_logic;
            reset_i     : in std_logic;
            
            smplNbr_i   : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- 2^k of periods sampled (8 sample per period)
            start_i     : in std_logic;
            IQ_input_i  : in std_logic_vector(BIT_WIDTH-1 downto 0);
            
            done_o      : out std_logic;
            result_o    : out std_logic_vector(BIT_WIDTH-1 downto 0)
        );
    end component;

    component average_ADC is
        generic(
            BIT_WIDTH   : integer := 27
        );
        port(
            clk_i       : in std_logic;
            reset_i     : in std_logic;
            
            
            smplNbr_i   : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- 2^k of periods sampled (8 sample per period)
            start_i     : in std_logic;
            adc_input_i : in std_logic_vector(ADC_data_length_c - 1 downto 0);
            sub_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
            sup_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
            
            done_o      : out std_logic;

            ADC_sub_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
            ADC_sup_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0)
        );
    end component;

end TL_VNAMI_MAIN_pkg;
