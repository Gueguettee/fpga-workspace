LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;

entity TL_VNA_MAIN is
port
	(
        clk_i           : in std_logic;     --don't used
        reset_i         : in std_logic;
        
      --clocks on FMC
        clk_100_o       : out std_logic;
        clk_80_o        : out std_logic;
        clk_40_o        : out std_logic;
        clk_10_o        : out std_logic;
        
      --PL/PS IO
        start_PL_i      : in std_logic;

        init_meas_i     : in std_logic;
        freq_done_i     : in std_logic; 
        path_done_i     : in std_logic;     
        
        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);

        IQ_rdy_PL_o     : out std_logic;

        I_TX_PL_o       : out std_logic_vector(31 downto 0);
        Q_TX_PL_o       : out std_logic_vector(31 downto 0);
        I_RX_PL_o       : out std_logic_vector(31 downto 0);
        Q_RX_PL_o       : out std_logic_vector(31 downto 0);
        
      --Debug help
        write_IQ_o      : out std_logic;

      --Onboard utility 
        sw_i            : in std_logic_vector(7 downto 0);
        led_o           : out std_logic_vector(7 downto 0);
        btn_u_i         : in std_logic;
        btn_d_i         : in std_logic;
        btn_l_i         : in std_logic;
        btn_r_i         : in std_logic;
		
	  --FMC IO signals
        ADC_TX_i        : in std_logic_vector(13 downto 0);
        ADC_RX_i        : in std_logic_vector(13 downto 0);
	  
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
        
        ---TX SIGNALS----
        SWR_TX_SER_o    : out std_logic; --named this based on 8 bit shift register datasheet
        SWR_TX_SRCLK_o  : out std_logic;
        
        SWR_TX_SRCLR_o  : out std_logic;
        SWR_TX_RCLK_o   : out std_logic;
        --SWR_TX_RCLR_o   : out std_logic;
        
        ---RX SIGNALS----
        SWR_RX_SER_o    : out std_logic; --named this based on 8 bit shift register datasheet
        SWR_RX_SRCLK_o  : out std_logic;
        
        SWR_RX_SRCLR_o  : out std_logic;
        SWR_RX_RCLK_o   : out std_logic;
        --SWR_RX_RCLR_o   : out std_logic

        --Filter bank signals
        V_o : out std_logic_vector(filter_bank_controller_length_c-1 downto 0)
        
	);
end entity TL_VNA_MAIN;

architecture mix of TL_VNA_MAIN is

--------------------------- SIGNALS ---------------------------
    
    signal clk_100M_s           : std_logic;
    signal clk_80M_s            : std_logic;
    signal clk_40M_s            : std_logic;
    signal clk_10M_s            : std_logic;
    signal clk_PL_main_s        : std_logic;
    signal reset_s              : std_logic;
    
    signal start_PL_i_s         : std_logic;                             
    signal init_meas_i_s        : std_logic;                             
    signal freq_done_i_s        : std_logic;                             
    signal path_done_i_s        : std_logic;                             
    signal freq_val_i_s         : std_logic_vector(freq_data_length_c - 1 downto 0); 
    signal ifbw_val_i_s         : std_logic_vector(ifbw_data_length_c - 1 downto 0); 
    signal path_tx_val_i_s      : std_logic_vector(path_data_length_c - 1 downto 0); 
    signal path_rx_val_i_s      : std_logic_vector(path_data_length_c - 1 downto 0); 

    signal start_s              : std_logic;
    signal start_pulse_s        : std_logic;
    
    signal state_s              : std_logic_vector(3 downto 0);
    signal IQ_rdy_PL_s          : std_logic;
    signal write_IQ_s           : std_logic;
    
    signal set_switch_s         : std_logic;
    signal set_freq_s           : std_logic;
    signal synth_seq_id_s       : std_logic_vector(5 downto 0);
    signal synth_pll_locked_s      : std_logic;
    signal synth_seq_done_s        : std_logic;
    
    signal PLL_locked_seq_done  : std_logic;

    signal start_sample_s       : std_logic;
    
    signal sampleTX_done_s      : std_logic;
    signal sampleRX_done_s      : std_logic;
    signal sample_done_s        : std_logic;

    signal freq_val_s           : std_logic_vector(freq_data_length_c - 1 downto 0);
    signal ifbw_val_s           : std_logic_vector(ifbw_data_length_c - 1 downto 0);
    signal path_tx_val_s        : std_logic_vector(path_data_length_c - 1 downto 0);
    signal path_rx_val_s        : std_logic_vector(path_data_length_c - 1 downto 0);
    
    signal RF_SCK_s             : std_logic;
    signal RF_SDI_s             : std_logic;
    signal RF_CSB_s             : std_logic;
    
    signal LO_SCK_s             : std_logic;
    signal LO_SDI_s             : std_logic;
    signal LO_CSB_s             : std_logic;
    
    signal ADC_TX_s             : std_logic_vector(13 downto 0);
    signal ADC_RX_s             : std_logic_vector(13 downto 0);
    
    signal I_TX_s               : std_logic_vector(26 downto 0);
    signal Q_TX_s               : std_logic_vector(26 downto 0);
    signal I_RX_s               : std_logic_vector(26 downto 0);
    signal Q_RX_s               : std_logic_vector(26 downto 0);

    signal sw_tx_rdy_s          : std_logic;
    signal sw_rx_rdy_s          : std_logic;

    signal sw_ready_s           : std_logic;
    signal synth_ready_s        : std_logic;

    signal I_TX_PL_o_s          : std_logic_vector(31 downto 0);
    signal Q_TX_PL_o_s          : std_logic_vector(31 downto 0);
    signal I_RX_PL_o_s          : std_logic_vector(31 downto 0);
    signal Q_RX_PL_o_s          : std_logic_vector(31 downto 0);

    signal IQ_rdy_PL_o_s     : std_logic;

    signal output_tilt_o_s   : std_logic_vector(2 downto 0);
        
    signal SPM_data_o_s      : std_logic_vector(27 downto 0);
    
-------------------------- COMPONENTS -------------------------

    --in main package

begin
--------------------------- DESIGN ----------------------------

    PLL_80M : PLL
    port map ( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        reset_o         => reset_s,
        clk_100M_o      => clk_100M_s,
        clk_80M_o       => clk_80M_s,
        clk_40M_o       => clk_40M_s,
        clk_10M_o       => clk_10M_s
    );
    clk_100_o       <= clk_i;
    clk_80_o        <= clk_80M_s;
    clk_40_o        <= clk_40M_s;
    clk_10_o        <= clk_10M_s;

    clk_PL_main_s   <= clk_80M_s;
   
    --READING ADC VALUES
    readADC: process(clk_PL_main_s)
    begin
        if falling_edge(clk_PL_main_s) then
            if reset_s = '1' then
                ADC_TX_s <= (others => '0');
                ADC_RX_s <= (others => '0');
            else
                ADC_TX_s <= ADC_TX_i;
                ADC_RX_s <= ADC_RX_i;
            end if;
        end if;
    end process;

    process(clk_PL_main_s)
    begin
        if rising_edge(clk_PL_main_s) then
            if reset_s = '1' then
                sample_done_s           <= '0';
                IQ_rdy_PL_o_s             <= '0';
            else
                sample_done_s           <= sampleTX_done_s and sampleRX_done_s;
                --IQ_rdy_PL_o             <= IQ_rdy_PL_s;
                IQ_rdy_PL_o_s            <= IQ_rdy_PL_s;
                if write_IQ_s = '1' then
                    --I_TX_PL_o   <= std_logic_vector(resize(signed(I_TX_s), I_TX_PL_o'length));
                    I_TX_PL_o_s <= std_logic_vector(resize(signed(I_TX_s), I_TX_PL_o'length));
                    --Q_TX_PL_o   <= std_logic_vector(resize(signed(Q_TX_s), Q_TX_PL_o'length));
                    Q_TX_PL_o_s   <= std_logic_vector(resize(signed(Q_TX_s), Q_TX_PL_o'length));
                    --I_RX_PL_o   <= std_logic_vector(resize(signed(I_RX_s), I_RX_PL_o'length));
                    I_RX_PL_o_s   <= std_logic_vector(resize(signed(I_RX_s), I_RX_PL_o'length));
                    --Q_RX_PL_o   <= std_logic_vector(resize(signed(Q_RX_s), Q_RX_PL_o'length));
                    Q_RX_PL_o_s   <= std_logic_vector(resize(signed(Q_RX_s), Q_RX_PL_o'length));
                end if;
            end if;
        end if;
    end process;
    
    --only for debuggin! changing between synthesizers without having 2 synths
    -- RF_CSB_o  <= RF_CSB_s when sw_i(7) = '1' else LO_CSB_s;
    -- RF_SDI_o  <= RF_SDI_s when sw_i(7) = '1' else LO_SDI_s;
    -- RF_SCK_o  <= RF_SCK_s when sw_i(7) = '1' else LO_SCK_s;

    led_o(3 downto 0) <=  state_s;
    write_IQ_o  <= write_IQ_s;
    
    --start signal is either sent from PC through PS or by pressing up button on ZedBoard
    start_s     <= btn_u_i or start_PL_i_s;

    PLL_locked_seq_done     <= (synth_seq_done_s and synth_PLL_locked_s);
    
    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_PL_main_s,
        reset_i     => reset_s,
        input_i     => start_s,
        pulse_o     => start_pulse_s
    );

    synthesisers_ready_edge_detect : edge_detector
    port map(
        clk_i       => clk_PL_main_s,
        reset_i     => reset_s,
        input_i     => PLL_locked_seq_done,
        pulse_o     => synth_ready_s
    );

    switches_ready_edge_detect : edge_detector
    port map(
        clk_i       => clk_PL_main_s,
        reset_i     => reset_s,
        input_i     => sw_tx_rdy_s and sw_rx_rdy_s,
        pulse_o     => sw_ready_s
    );
    
    PreventMetastability : Input_FlipFlops
    port map( 
        clk_i                   => clk_PL_main_s,
        rst_i                   => reset_s,

        start_PL_i              => start_PL_i,
        init_meas_i             => init_meas_i,
        freq_done_i             => freq_done_i,
        path_done_i             => path_done_i,
        freq_val_i              => freq_val_i,
        ifbw_val_i              => ifbw_val_i,
        path_tx_val_i           => path_tx_val_i,
        path_rx_val_i           => path_rx_val_i,

        output_start_PL_o       => start_PL_i_s,
        output_init_meas_o      => init_meas_i_s,
        output_freq_done_o      => freq_done_i_s,
        output_path_done_o      => path_done_i_s,
        output_freq_val_o       => freq_val_i_s,
        output_ifbw_val_o       => ifbw_val_i_s,
        output_path_tx_val_o    => path_tx_val_i_s,
        output_path_rx_val_o    => path_rx_val_i_s
    );

    PreventMetastability2 : Output_FlipFlops
    port map( 
        clk_i                   => clk_PL_main_s,
        rst_i                   => reset_s,

        I_TX_PL_i               => I_TX_PL_o_s,
        Q_TX_PL_i               => Q_TX_PL_o_s,
        I_RX_PL_i               => I_RX_PL_o_s,
        Q_RX_PL_i               => Q_RX_PL_o_s,

        IQ_rdy_PL_i             => IQ_rdy_PL_o_s,

        output_tilt_i           => output_tilt_o_s,

        SPM_data_i              => SPM_data_o_s,

        I_TX_PL_o               => I_TX_PL_o,
        Q_TX_PL_o               => Q_TX_PL_o,
        I_RX_PL_o               => I_RX_PL_o,
        Q_RX_PL_o               => Q_RX_PL_o,

        IQ_rdy_PL_o             => IQ_rdy_PL_o,

        output_tilt_o           => output_tilt_o,

        SPM_data_o              => SPM_data_o
    );
    
    Control : main_control
    port map(
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,
		
        start_i         => start_pulse_s,
        
        init_meas_i     => init_meas_i_s or sw_i(0), --for testing purposes
        freq_done_i     => freq_done_i_s or sw_i(1), --for testing purposes
        path_done_i     => path_done_i_s or sw_i(2), --for testing purposes

        freq_val_i      => freq_val_i_s,
        ifbw_val_i      => ifbw_val_i_s,
        path_tx_val_i   => path_tx_val_i_s,
        path_rx_val_i   => path_rx_val_i_s,

        sample_done_i   => sample_done_s,
        pll_locked_i    => synth_ready_s or sw_i(6), --for testing purposes
        switch_set_i    => sw_ready_s or sw_i(7), --for testing purposes
        
        state_o         => state_s,

        synth_seq_id_o  => synth_seq_id_s,
        en_set_sw_o     => set_switch_s, 
        en_set_freq_o   => set_freq_s,
        en_rf_o         => open,

        start_sample_o  => start_sample_s,

        IQ_rdy_PL_o     => IQ_rdy_PL_s,
        write_IQ_o      => write_IQ_s,
    
        freq_val_o      => freq_val_s,
        ifbw_val_o      => ifbw_val_s,
        path_tx_val_o   => path_tx_val_s,
        path_rx_val_o   => path_rx_val_s
	);
    
    IQ_TX : IQ_demod
    port map (
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,
        input_signal_i  => ADC_TX_s,
        start_i         => start_sample_s,
        smplNbr_i       => ifbw_val_s,
        done_o          => sampleTX_done_s,
        I_o             => I_TX_s,
        Q_o             => Q_TX_s
    );
    IQ_RX : IQ_demod
    port map (
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,
        input_signal_i  => ADC_RX_s,
        start_i         => start_sample_s,
        smplNbr_i       => ifbw_val_s,
        done_o          => sampleRX_done_s,
        I_o             => I_RX_s,
        Q_o             => Q_RX_s
    );
    
    SYNTH_CONTROLLER : SPI_synth_controller
    generic map (
        SPI_CLK_DIVIDER     => 100 --minimum 2, only even numbers allowed
    )
    port map ( 
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,
        seq_id_i        => synth_seq_id_s,
        start_seq_i     => set_freq_s,
        freq_i          => freq_val_s,
        pll_locked_o    => synth_pll_locked_s,
        seq_done_o      => synth_seq_done_s,
        RF_MUXout_i     => RF_MUXout_i,
        RF_SCK_o        => RF_SCK_o,
        RF_SDI_o        => RF_SDI_o,
        RF_CSB_o        => RF_CSB_o,
        RF_CE_o         => RF_CE_o,
        LO_MUXout_i     => LO_MUXout_i,
        LO_SCK_o        => LO_SCK_o,
        LO_SDI_o        => LO_SDI_o,
        LO_CSB_o        => LO_CSB_o,
        LO_CE_o         => LO_CE_o
    );
    
    TILT_POSITION : tilt_position_controller
    port map (
        input_tilt_1    => input_tilt_1,
        input_tilt_2    => input_tilt_2,
        input_tilt_3    => input_tilt_3,
        output_tilt_o   => output_tilt_o_s
        
    );
    
    SEPARATION_DISTANCE : SPI_SPM_LA11D01
    generic map(
        SPI_CLK_DIVIDER     => 18,
        DATA_LENGTH         => 28
        )
    port map (
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,
        start_i         => '1',
        
        data_o          => SPM_data_o_s,
        
        MISO_i          => SPM_MISO_i,
        SCK_o           => SPM_SCLK_o,
        CSB_o           => SPM_CSB_o
        
    );
    
    ------------------- TO ADD LATER -----------------
    SWITCH_REGISTER_TX : SPI_switch_controller
    generic map(
        SPI_CLK_DIVIDER     => 10, --minimum 2, only even numbers allowed
        PATH_DATA_LENGTH    => path_data_length_c
    )
    port map (
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,

        start_seq_i     => set_switch_s,
        path_data_i     => path_tx_val_s,
        rdy_o           => sw_tx_rdy_s,

        pico_o          => SWR_TX_SER_o,
        poci_i          => '0',

        sck_o           => SWR_TX_SRCLK_o,
        srclr_n_o       => SWR_TX_SRCLR_o,

        --rclk_o          => open,
        rclr_n_o        => open,

        cs_o            => SWR_TX_RCLK_o
    );
    
    SWITCH_REGISTER_RX : SPI_switch_controller
    generic map(
        SPI_CLK_DIVIDER     => 10, --minimum 2, only even numbers allowed
        PATH_DATA_LENGTH    => path_data_length_c
    )
    port map (
        clk_i           => clk_PL_main_s,
        reset_i         => reset_s,

        start_seq_i     => set_switch_s,
        path_data_i     => path_rx_val_s,
        rdy_o           => sw_rx_rdy_s,

        pico_o          => SWR_RX_SER_o,
        poci_i          => '0',

        sck_o           => SWR_RX_SRCLK_o,
        srclr_n_o       => SWR_RX_SRCLR_o,

        --rclk_o          => open,
        rclr_n_o        => open,

        cs_o            => SWR_RX_RCLK_o
    );

    Filter_bank : filter_bank_controller
    port map(
        clk_i               => clk_PL_main_s,
        reset_i             => reset_i,
        freq_i              => freq_val_s,
        V_o                 => V_o
    );

end architecture mix;
