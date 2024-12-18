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
    
--clocks on FMC
    clk_80_o        : out std_logic;
    clk_100_o       : out std_logic;
    
--PL/PS IO
    start_PL_i      : in std_logic;

    init_meas_i     : in std_logic;
    path_done_i     : in std_logic;     
    freq_done_i     : in std_logic;     
    freq_PL_i       : in std_logic_vector(freq_data_length_c - 1 downto 0);

    start_SR_TX_i   : in std_logic;
    start_SR_RX_i   : in std_logic;    
    
    IQ_rdy_PL_o     : out std_logic;
    I_TX_PL_o       : out std_logic_vector(31 downto 0);
    Q_TX_PL_o       : out std_logic_vector(31 downto 0);
    I_RX_PL_o       : out std_logic_vector(31 downto 0);
    Q_RX_PL_o       : out std_logic_vector(31 downto 0);
    
    ADC_TX_o        : out std_logic_vector(31 downto 0);
    ADC_RX_o        : out std_logic_vector(31 downto 0);
    
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
    
    LO_MUXout_i     : in std_logic;
    LO_SCK_o        : out std_logic;
    LO_CSB_o        : out std_logic;
    LO_SDI_o        : out std_logic;
    
    output_tilt_o   : out std_logic_vector(2 downto 0);
    input_tilt_1    : in std_logic;
    input_tilt_2    : in std_logic;
    input_tilt_3    : in std_logic;
    
    SPM_data_o      : out std_logic_vector(27 downto 0);
    SPM_MISO_i      : in std_logic;
    SPM_SCLK_o      : out std_logic;
    SPM_CSB_o       : out std_logic
    
    --        ---TX SIGNALS----
    --        SWR_TX_SER_i              : in std_logic_vector(7 downto 0); -- coming from the PS side
    --        SWR_TX_SER_o              : out std_logic; --named this based on 8 bit shift register datasheet
    --        SWR_TX_SRCLK_o            : out std_logic;
    --        --SDI_o               : out std_logic;
    --        SRCLR_o            : out std_logic;
    --        RCLK_o             : out std_logic;
    --        RCLR_o             : out std_logic;
    --        
    --        ---RX SIGNALS----
    --        SER_RX_i           : in std_logic_vector(7 downto 0); -- coming from the PS side
    --        SER_RX_o              : out std_logic; --named this based on 8 bit shift register datasheet
    --       -- SRCLK_o            : out std_logic; 
    --        --SDI_o               : out std_logic;
    --       -- SRCLR_o            : out std_logic;
    --        RCLK_RX_o             : out std_logic
    --       -- RCLR_o             : out std_logic
    
);
end component TL_VNA_MAIN;


   --Inputs
   signal clk_i         : std_logic := '0';
   signal reset_i       : std_logic := '0';
   signal start_i       : std_logic := '0';
   signal MUX_out_i     : std_logic := '0';
   signal init_meas_i   : std_logic := '0';
   signal path_done_i   : std_logic := '0';
   signal freq_done_i   : std_logic := '0';
   signal freq_PL_i     : std_logic_vector(freq_data_length_c - 1 downto 0) := (others => '0');

 	--Outputs

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
begin

    TL_MAIN_uut : TL_VNA_MAIN
    port map( 
        clk_i               => clk_i,
        reset_i             => reset_i,
        
        clk_80_o            => open,
        clk_100_o           => open,
        
      --PL/PS IO
        start_PL_i          => start_i,
        init_meas_i         => init_meas_i,
        path_done_i         => path_done_i,   
        freq_done_i         => freq_done_i,    
        freq_PL_i           => freq_PL_i,
        
        IQ_rdy_PL_o     => open,
        I_TX_PL_o       => open,
        Q_TX_PL_o       => open,
        I_RX_PL_o       => open,
        Q_RX_PL_o       => open,


        ADC_TX_o        => open,
        ADC_RX_o        => open,

        start_SR_TX_i   => '0',
        start_SR_RX_i   => '0',

        --Debug help
        write_IQ_o      => open,
        
      --Onboard utility 
        sw_i            => (others => '0'),
        led_o           => open,
        btn_u_i         => '0',
        btn_d_i         => '0',
        btn_l_i         => '0',
        btn_r_i         => '0',
        
        RF_MUXout_i     => '1',
        RF_SCK_o        => open,
        RF_CSB_o        => open,
        RF_SDI_o        => open,
        
        LO_MUXout_i     => '1',
        LO_SCK_o        => open,
        LO_CSB_o        => open,
        LO_SDI_o        => open,

        --FMC IO signals
        ADC_TX_i        => (others => '0'),
        ADC_RX_i        => (others => '0'),
        
        output_tilt_o   => open,
        input_tilt_1    => '0',
        input_tilt_2    => '0',
        input_tilt_3    => '0',
        
        SPM_data_o      => open,
        SPM_MISO_i      => '0',
        SPM_SCLK_o      => open,
        SPM_CSB_o       => open
    );
  
   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;

 

-- Reset process
   reset_proc: process
   begin		
      -- hold reset state for 50 ns.
        reset_i <= '1';
        wait for 50 ns;
        reset_i <= '0';
      wait;
   end process;
   
   
-- Signal process
   signal_proc: process
   begin
        init_meas_i <= '1';
        wait for 200 ns;
        freq_PL_i <= "000001";
        wait for 200 ns;
        

        start_i <= '0';
        wait for 2 us;
        
        start_i <= '1';
        wait for 200 ns;
        start_i <= '0';
        
        wait for 110 us;
        
        -- MUX_out_i <= '1';
        -- wait for 200 ns;
        -- MUX_out_i <= '0';
        
        -- wait for 10 us;
        
        -- start_i <= '1';
        -- wait for 200 ns;
        -- start_i <= '0';
      
        -- wait for 80 us;
            
        -- MUX_out_i <= '1';
        -- wait for 200 ns;
        -- MUX_out_i <= '0';
      
      wait;
        
   end process;
   

end Behavioral;
