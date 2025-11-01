----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.03.2022 18:37:59
-- Design Name: 
-- Module Name: TestBench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TestBench_TL_MAIN is
--  Port ( );
end TestBench_TL_MAIN;

architecture Behavioral of TestBench_TL_MAIN is

  component TL_VNA_MAIN is
    port
    (
        clk_i           : in std_logic;
        reset_i         : in std_logic;

        clk_80_i        : in std_logic;
        clk_100_i       : in std_logic;
        
      --clocks on FMC
        clk_80_o        : out std_logic;
        clk_100_o       : out std_logic;
        
      --PL/PS IO
        start_PL_i      : in std_logic;

        init_meas_i     : in std_logic;
        freq_done_i     : in std_logic; 
        path_done_i     : in std_logic;     
        freqPath_done_i : in std_logic;
        start_cw_i      : in std_logic;

        mode_i          : in std_logic_vector(mode_data_length_c - 1 downto 0);
        
        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(24 - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(24 - 1 downto 0);
        RF_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        LO_power_i      : in std_logic_vector(synth_power_data_length_c - 1 downto 0);
        ATT_power_i     : in std_logic_vector(att_power_data_length_c - 1 downto 0);
        calFact_freqPath_i : in std_logic_vector(calFact_power_freqPath_data_length_c - 1 downto 0);
        RX_VGA_gain_i   : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        TX_VGA_gain_i   : in std_logic_vector(vga_gain_data_length_c - 1 downto 0);

        RX_VGA_gain_o   : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);
        TX_VGA_gain_o   : out std_logic_vector(vga_gain_data_length_c - 1 downto 0);

        IQ_rdy_PL_o     : out std_logic;

        I_TX_PL_o       : out std_logic_vector(31 downto 0);
        Q_TX_PL_o       : out std_logic_vector(31 downto 0);
        I_RX_PL_o       : out std_logic_vector(31 downto 0);
        Q_RX_PL_o       : out std_logic_vector(31 downto 0);

        PL_status_o     : out std_logic_vector(PL_status_data_length_c - 1 downto 0);
        
      --Debug help
        VNA_rdy_PL_o    : out std_logic;

      --Onboard utility 
        LED0_N_PL_o     : out std_logic;
        LED1_N_PL_o     : out std_logic;
        LED2_N_PL_o     : out std_logic;
        LED3_N_PL_o     : out std_logic;

        BTN_i           : in std_logic;
        
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

        RF_ON_o         : out std_logic;
        
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
        RX_VGA_SCLK_o        : out std_logic;
        RX_VGA_CS_o          : out std_logic;
        RX_VGA_SDI_o         : out std_logic;

        TX_VGA_SCLK_o        : out std_logic;
        TX_VGA_CS_o          : out std_logic;
        TX_VGA_SDI_o         : out std_logic;

        --Testing signals
        sine_0_o    : out std_logic_vector(14-1 downto 0);
        sine_90_o   : out std_logic_vector(14-1 downto 0);

        VGA_val_o : out std_logic_vector(VGA_data_length_c-1 downto 0)
    );
    end component TL_VNA_MAIN;

   --Inputs

  --Outputs

   -- Clock period definitions
   constant clk_i_period : time := 12.5 ns;

   signal clk_i_s           : std_logic;
   signal reset_i_s         : std_logic;
  
  -- Clocks on FMC
  signal clk_100_o_s       : std_logic;
  signal clk_80_o_s        : std_logic;
  signal clk_40_o_s        : std_logic;
  signal clk_10_o_s        : std_logic;
  
  -- PL/PS IO
  signal start_PL_i_s      : std_logic;
  signal init_meas_i_s     : std_logic;
  signal freq_done_i_s     : std_logic; 
  signal path_done_i_s     : std_logic;     
  signal freqPath_done_i_s : std_logic;
  signal start_cw_i_s    : std_logic;
  
  signal mode_i_s          : std_logic_vector(mode_data_length_c - 1 downto 0);
  signal freq_val_i_s      : std_logic_vector(freq_data_length_c - 1 downto 0);
  signal ifbw_val_i_s      : std_logic_vector(ifbw_data_length_c - 1 downto 0);
  signal path_tx_val_i_s   : std_logic_vector(24 - 1 downto 0);
  signal path_rx_val_i_s   : std_logic_vector(24 - 1 downto 0);
  signal RF_power_i_s      : std_logic_vector(synth_power_data_length_c - 1 downto 0);
  signal LO_power_i_s      : std_logic_vector(synth_power_data_length_c - 1 downto 0);
  signal ATT_power_i_s     : std_logic_vector(att_power_data_length_c - 1 downto 0);
  signal calFact_freqPath_i_s: std_logic_vector(calFact_power_freqPath_data_length_c - 1 downto 0);
  signal RX_VGA_gain_i_s   : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
  signal TX_VGA_gain_i_s   : std_logic_vector(vga_gain_data_length_c - 1 downto 0);

  signal RX_VGA_gain_o_s   : std_logic_vector(vga_gain_data_length_c - 1 downto 0);
  signal TX_VGA_gain_o_s   : std_logic_vector(vga_gain_data_length_c - 1 downto 0);

  signal IQ_rdy_PL_o_s     : std_logic;
  
  signal I_TX_PL_o_s       : std_logic_vector(31 downto 0);
  signal Q_TX_PL_o_s       : std_logic_vector(31 downto 0);
  signal I_RX_PL_o_s       : std_logic_vector(31 downto 0);
  signal Q_RX_PL_o_s       : std_logic_vector(31 downto 0);

  signal PL_status_o_s     : std_logic_vector(PL_status_data_length_c - 1 downto 0);
  
  --Debug help
  signal VNA_rdy_PL_o_s    : std_logic;

  --Onboard utility 
  signal LED0_N_PL_o_s     : std_logic;
  signal LED1_N_PL_o_s     : std_logic;
  signal LED2_N_PL_o_s     : std_logic;
  signal LED3_N_PL_o_s     : std_logic;

  signal BTN_i_s           : std_logic;
  
  --FMC IO signals
  signal ADC_TX_i_s        : std_logic_vector(13 downto 0);
  signal ADC_RX_i_s        : std_logic_vector(13 downto 0);
  
  signal RF_MUXout_i_s     : std_logic;
  signal RF_SCK_o_s        : std_logic;
  signal RF_CSB_o_s        : std_logic;
  signal RF_SDI_o_s        : std_logic;
  signal RF_CE_o_s         : std_logic;
  
  signal LO_MUXout_i_s     : std_logic;
  signal LO_SCK_o_s        : std_logic;
  signal LO_CSB_o_s        : std_logic;
  signal LO_SDI_o_s        : std_logic;
  signal LO_CE_o_s         : std_logic;
  
  signal output_tilt_o_s   : std_logic_vector(2 downto 0);
  signal input_tilt_1_s    : std_logic;
  signal input_tilt_2_s    : std_logic;
  signal input_tilt_3_s    : std_logic;
  
  signal SPM_data_o_s      : std_logic_vector(27 downto 0);
  signal SPM_MISO_i_s      : std_logic;
  signal SPM_SCLK_o_s      : std_logic;
  signal SPM_CSB_o_s       : std_logic;

  signal RF_ON_o_s         : std_logic;
  
  ---TX SIGNALS----
  signal SWR_TX_SER_o_s    : std_logic; --named this based on 8 bit shift register datasheet
  signal SWR_TX_SRCLK_o_s  : std_logic;
  
  signal SWR_TX_SRCLR_o_s  : std_logic;
  signal SWR_TX_RCLK_o_s   : std_logic;
  --signal SWR_TX_RCLR_o_s   : std_logic;

  signal SWR_TX_SER_BACK_i_s   : std_logic;
  
  ---RX SIGNALS----
  signal SWR_RX_SER_o_s    : std_logic; --named this based on 8 bit shift register datasheet
  signal SWR_RX_SRCLK_o_s  : std_logic;
  
  signal SWR_RX_SRCLR_o_s  : std_logic;
  signal SWR_RX_RCLK_o_s   : std_logic;
  --signal SWR_RX_RCLR_o_s   : std_logic

  signal SWR_RX_SER_BACK_i_s   : std_logic;

  --Filter bank signals
  signal V_o_s : std_logic_vector(filter_bank_controller_output_length_c-1 downto 0);

  --Attenuators signals
  signal PAR_SER1_o_s           : std_logic;
  signal SERIAL1_o_s            : std_logic;
  signal CLK1_o_s               : std_logic;
  signal LATCH_ENABLE1_o_s      : std_logic;

  signal CTRL2_o_s              : std_logic;

  --VGAs signals
  signal RX_VGA_SCLK_o_s        : std_logic;
  signal RX_VGA_CS_o_s          : std_logic;
  signal RX_VGA_SDI_o_s         : std_logic;

  signal TX_VGA_SCLK_o_s        : std_logic;
  signal TX_VGA_CS_o_s          : std_logic;
  signal TX_VGA_SDI_o_s         : std_logic;

  --Testing signals
  signal sine_0_o_s    : std_logic_vector(14-1 downto 0);
  signal sine_90_o_s   : std_logic_vector(14-1 downto 0);

  signal VGA_val_o_s : std_logic_vector(VGA_data_length_c-1 downto 0);

  constant N_POINTS_MEASURE : integer := 4;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut: TL_VNA_MAIN
  port map (
      clk_i => clk_i_s,
      reset_i => reset_i_s,

      clk_80_i => '0',
      clk_100_i => '0',
      
      --clocks on FMC
      clk_80_o => clk_80_o_s,
      clk_100_o => clk_100_o_s,
      
      --PL/PS IO
      start_PL_i => start_PL_i_s,

      init_meas_i => init_meas_i_s,
      freq_done_i => freq_done_i_s, 
      path_done_i => path_done_i_s,     
      freqPath_done_i => freqPath_done_i_s,
      start_cw_i => start_cw_i_s,

      mode_i => mode_i_s,
      
      freq_val_i => freq_val_i_s,
      ifbw_val_i => ifbw_val_i_s,
      path_tx_val_i => path_tx_val_i_s,
      path_rx_val_i => path_rx_val_i_s,
      RF_power_i => RF_power_i_s,
      LO_power_i => LO_power_i_s,
      ATT_power_i => ATT_power_i_s,
      calFact_freqPath_i => calFact_freqPath_i_s,
      RX_VGA_gain_i => RX_VGA_gain_i_s,
      TX_VGA_gain_i => TX_VGA_gain_i_s,

      RX_VGA_gain_o => RX_VGA_gain_o_s,
      TX_VGA_gain_o => TX_VGA_gain_o_s,

      IQ_rdy_PL_o => IQ_rdy_PL_o_s,

      I_TX_PL_o => I_TX_PL_o_s,
      Q_TX_PL_o => Q_TX_PL_o_s,
      I_RX_PL_o => I_RX_PL_o_s,
      Q_RX_PL_o => Q_RX_PL_o_s,

      PL_status_o => PL_status_o_s,
      
      --Debug help
      VNA_rdy_PL_o => VNA_rdy_PL_o_s,

      --Onboard utility 
      LED0_N_PL_o => LED0_N_PL_o_s,
      LED1_N_PL_o => LED1_N_PL_o_s,
      LED2_N_PL_o => LED2_N_PL_o_s,
      LED3_N_PL_o => LED3_N_PL_o_s,

      BTN_i => BTN_i_s,
      
      --FMC IO signals
      ADC_TX_i => ADC_TX_i_s,
      ADC_RX_i => ADC_RX_i_s,
      
      RF_MUXout_i => RF_MUXout_i_s,
      RF_SCK_o => RF_SCK_o_s,
      RF_CSB_o => RF_CSB_o_s,
      RF_SDI_o => RF_SDI_o_s,
      RF_CE_o => RF_CE_o_s,
      
      LO_MUXout_i => LO_MUXout_i_s,
      LO_SCK_o => LO_SCK_o_s,
      LO_CSB_o => LO_CSB_o_s,
      LO_SDI_o => LO_SDI_o_s,
      LO_CE_o => LO_CE_o_s,
      
      output_tilt_o => output_tilt_o_s,
      input_tilt_1 => input_tilt_1_s,
      input_tilt_2 => input_tilt_2_s,
      input_tilt_3 => input_tilt_3_s,
      
      SPM_data_o => SPM_data_o_s,
      SPM_MISO_i => SPM_MISO_i_s,
      SPM_SCLK_o => SPM_SCLK_o_s,
      SPM_CSB_o => SPM_CSB_o_s,

      RF_ON_o => RF_ON_o_s,
      
      ---TX SIGNALS----
      SWR_TX_SER_o => SWR_TX_SER_o_s, --named this based on 8 bit shift register datasheet
      SWR_TX_SRCLK_o => SWR_TX_SRCLK_o_s,
      
      SWR_TX_SRCLR_o => SWR_TX_SRCLR_o_s,
      SWR_TX_RCLK_o => SWR_TX_RCLK_o_s,
      --SWR_TX_RCLR_o => SWR_TX_RCLR_o_s,

      SWR_TX_SER_BACK_i => SWR_TX_SER_BACK_i_s,
      
      ---RX SIGNALS----
      SWR_RX_SER_o => SWR_RX_SER_o_s, --named this based on 8 bit shift register datasheet
      SWR_RX_SRCLK_o => SWR_RX_SRCLK_o_s,
      
      SWR_RX_SRCLR_o => SWR_RX_SRCLR_o_s,
      SWR_RX_RCLK_o => SWR_RX_RCLK_o_s,
      --SWR_RX_RCLR_o => SWR_RX_RCLR_o_s,

      SWR_RX_SER_BACK_i => SWR_RX_SER_BACK_i_s,

      --Filter bank signals
      V_o => V_o_s,

      --Attenuators signals
      PAR_SER1_o => PAR_SER1_o_s,
      SERIAL1_o => SERIAL1_o_s,
      CLK1_o => CLK1_o_s,
      LATCH_ENABLE1_o => LATCH_ENABLE1_o_s,

      CTRL2_o => CTRL2_o_s,

      --VGAs signals
      RX_VGA_SCLK_o => RX_VGA_SCLK_o_s,
      RX_VGA_CS_o => RX_VGA_CS_o_s,
      RX_VGA_SDI_o => RX_VGA_SDI_o_s,

      TX_VGA_SCLK_o => TX_VGA_SCLK_o_s,
      TX_VGA_CS_o => TX_VGA_CS_o_s,
      TX_VGA_SDI_o => TX_VGA_SDI_o_s,

      --Testing signals
      sine_0_o => sine_0_o_s,
      sine_90_o => sine_90_o_s,

      VGA_val_o => VGA_val_o_s

  );
   
  
   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i_s <= '0';
		wait for clk_i_period/2;
		clk_i_s <= '1';
		wait for clk_i_period/2;
   end process;

 

-- Reset process
   reset_proc: process
   begin		
      -- hold reset state for 50 ns.
        reset_i_s <= '1';
        wait for 50 us;
        reset_i_s <= '0';
      wait;
   end process;
   
   
-- Signal process
signal_proc: process
begin
        
    start_PL_i_s        <= '0';
    init_meas_i_s       <= '0';
    freq_done_i_s       <= '0';
    path_done_i_s       <= '0';
    start_cw_i_s        <= '0';
    
    -- Define values for other input signals here
    freq_val_i_s        <= "00111111"; -- Example for a vector signal
    ifbw_val_i_s        <= "11010"; -- Example for a vector signal with different default value
    path_tx_val_i_s     <= (others => '1'); -- Another vector signal
    path_rx_val_i_s     <= (others => '1'); -- Another vector signal
    RF_power_i_s        <= "010101"; -- Yet another vector signal
    LO_power_i_s        <= "010101"; -- Yet another vector signal
    ATT_power_i_s       <= "10101010"; -- And another one
    calFact_freqPath_i_s<= (others => '0'); -- Default initialization
    RX_VGA_gain_i_s     <= "01111"; -- Example value for VGA gain
    TX_VGA_gain_i_s     <= "10000"; -- Example value for VGA gain
    input_tilt_1_s      <= '1'; -- Another single bit signal
    input_tilt_2_s      <= '1'; -- Another single bit signal
    input_tilt_3_s      <= '0'; -- Another single bit signal
    BTN_i_s             <= '0'; -- Example for a button input signal
    ADC_TX_i_s          <= (others => '0'); -- Default initialization
    ADC_RX_i_s          <= (others => '0'); -- Example for another vector signal
    RF_MUXout_i_s       <= '1'; -- Example for a signal connected to a multiplexer
    LO_MUXout_i_s       <= '1'; -- Example for another signal connected to a multiplexer
    SPM_MISO_i_s        <= '1'; -- Example for a signal coming from a SPI interface
    SWR_TX_SER_BACK_i_s <= '1'; -- Example value for back signal from TX shift register
    SWR_RX_SER_BACK_i_s <= '1'; -- Example value for back signal from RX
        
    wait for 100 us;
    wait until VNA_rdy_PL_o_s = '1';
    wait for 100 us;
    
    init_meas_i_s      <= '1'; -- Example of starting a process
    wait for 100 us;
    freq_done_i_s  <= '1';
    wait for 100 us;
    freq_val_i_s        <= "01110000"; -- Example for a vector signal
    freq_done_i_s  <= '0';
    wait for 100 us;
    path_done_i_s  <= '1';
    wait for 100 us;
    path_tx_val_i_s   <= (others => '1'); -- Another vector signal
    path_rx_val_i_s   <= (others => '1'); -- Another vector signal
    path_done_i_s  <= '0';
    wait for 100 us;
    init_meas_i_s      <= '0';
    wait until VNA_rdy_PL_o_s = '1';
    wait for 1 ms;

    start_PL_i_s      <= '1';
    wait for 100 ns;
    for i in 0 to N_POINTS_MEASURE - 1 loop
      start_PL_i_s      <= '0';
      wait until IQ_rdy_PL_o_s = '1';
      wait for 100 us;
      freq_done_i_s <= not freq_done_i_s;
      wait until IQ_rdy_PL_o_s = '0';
    end loop;

    wait for 1 ms;
    start_cw_i_s <= '1';
    wait for 1 ms;
    start_cw_i_s <= '0';

    wait;
        
  end process;
   

end Behavioral;
