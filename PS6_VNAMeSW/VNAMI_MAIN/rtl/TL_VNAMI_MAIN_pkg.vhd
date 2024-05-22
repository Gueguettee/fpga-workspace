library ieee;
use ieee.std_logic_1164.all;
use work.main_control_pkg.all;
use work.SPI_synth_pkg.all;

package TL_VNAMI_MAIN_pkg is

-------------------------- CONSTANTS ------------------------- 


-------------------------- COMPONENTS ------------------------- 

    component Output_FlipFlops is
        port( 
            clk_i           : in std_logic;                             -- System clock
            rst_i           : in std_logic;                             -- Asynchronous reset

            I_TX_PL_i       : in std_logic_vector(31 downto 0);
            Q_TX_PL_i       : in std_logic_vector(31 downto 0);
            I_RX_PL_i       : in std_logic_vector(31 downto 0);
            Q_RX_PL_i       : in std_logic_vector(31 downto 0);

            IQ_rdy_PL_i     : in std_logic;

            output_tilt_i   : in std_logic_vector(2 downto 0);
            
            SPM_data_i      : in std_logic_vector(27 downto 0);

            I_TX_PL_o       : out std_logic_vector(31 downto 0);
            Q_TX_PL_o       : out std_logic_vector(31 downto 0);
            I_RX_PL_o       : out std_logic_vector(31 downto 0);
            Q_RX_PL_o       : out std_logic_vector(31 downto 0);

            IQ_rdy_PL_o     : out std_logic;

            output_tilt_o   : out std_logic_vector(2 downto 0);
            
            SPM_data_o      : out std_logic_vector(27 downto 0)
        );  
    end component;

    component edge_detector is
        port (
            clk_i                       : in  std_logic;
            reset_i                     : in  std_logic;
            input_i                     : in  std_logic;
            pulse_o                     : out std_logic
        );
    end component;

    component Input_FlipFlops is
    port( 
        clk_i           : in std_logic;                             -- System clock
        rst_i           : in std_logic;                             -- Asynchronous reset

        start_PL_i      : in std_logic;                             -- Start signal for the PL (programmable logic)
        init_meas_i     : in std_logic;                             -- Initialization signal for measurements
        freq_done_i     : in std_logic;                             -- Frequency measurement done signal
        path_done_i     : in std_logic;                             -- Path measurement done signal
        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0); -- Frequency value input
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- IF bandwidth value input
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0); -- Path transmit value input
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0); -- Path receive value input

        output_start_PL_o   : out std_logic;                         -- Synchronized output for start_PL_i
        output_init_meas_o  : out std_logic;                         -- Synchronized output for init_meas_i
        output_freq_done_o  : out std_logic;                         -- Synchronized output for freq_done_i
        output_path_done_o  : out std_logic;                         -- Synchronized output for path_done_i
        output_freq_val_o   : out std_logic_vector(freq_data_length_c - 1 downto 0); -- Synchronized output for freq_val_i
        output_ifbw_val_o   : out std_logic_vector(ifbw_data_length_c - 1 downto 0); -- Synchronized output for ifbw_val_i
        output_path_tx_val_o: out std_logic_vector(path_data_length_c - 1 downto 0); -- Synchronized output for path_tx_val_i
        output_path_rx_val_o: out std_logic_vector(path_data_length_c - 1 downto 0)  -- Synchronized output for path_rx_val_i
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

        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);

        sample_done_i   : in std_logic;
        pll_locked_i    : in std_logic;
        switch_set_i    : in std_logic;
        
        state_o         : out std_logic_vector(3 downto 0);
        
        synth_seq_id_o  : out std_logic_vector(5 downto 0);
        en_set_sw_o     : out std_logic;
        en_set_freq_o   : out std_logic;
        en_rf_o         : out std_logic;

        start_sample_o  : out std_logic;

        IQ_rdy_PL_o     : out std_logic;
        write_IQ_o      : out std_logic;

        freq_val_o      : out std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_o      : out std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0)
    );
    end component;
    
    component IQ_demod is
    port 
    (
        clk_i             : in std_logic;
        reset_i           : in std_logic;
        
        input_signal_i    : in std_logic_vector(13 downto 0);
        start_i           : in std_logic;
        smplNbr_i         : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        
        done_o            : out std_logic;
        I_o               : out std_logic_vector(26 downto 0);
        Q_o               : out std_logic_vector(26 downto 0)
    );
    end component IQ_demod;
    
    component PLL is
    port 
    (
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
    end component SPI_switch_controller;
    
    component SPI_synth_controller is
        generic(
            SPI_CLK_DIVIDER     : integer := 10 --minimum 2, only even numbers allowed
        );
        port(
            clk_i           : in std_logic;
            reset_i         : in std_logic;
        --intern inputs/outputs (from main control,etc)
            seq_id_i        : in std_logic_vector(5 downto 0);
            start_seq_i     : in std_logic;
            freq_i          : in std_logic_vector(5 downto 0);
            pll_locked_o    : out std_logic;
            seq_done_o      : out std_logic;
        --external input outputs(physical)
            RF_MUXout_i     : in std_logic;
            RF_SCK_o        : out std_logic;
            RF_SDI_o        : out std_logic;
            RF_CSB_o        : out std_logic;
            RF_CE_o         : out std_logic;
            LO_MUXout_i     : in std_logic;
            LO_SCK_o        : out std_logic;
            LO_SDI_o        : out std_logic;
            LO_CSB_o        : out std_logic;
            LO_CE_o         : out std_logic
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
    
        --external input outputs(physical)
        V_o : out std_logic_vector(filter_bank_controller_length_c-1 downto 0) --V4 (= MSB) to V1 (= LSB)
    );
    end component filter_bank_controller;

end TL_VNAMI_MAIN_pkg;
