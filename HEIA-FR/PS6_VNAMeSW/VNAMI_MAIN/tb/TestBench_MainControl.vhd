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

entity TestBench_MAIN_CONTROL is
--  Port ( );
end TestBench_MAIN_CONTROL;

architecture Behavioral of TestBench_MAIN_CONTROL is

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
end component main_control;


    --Inputs
    signal clk_i            : std_logic := '0';
    signal reset_i          : std_logic := '0';

    signal start_i          : std_logic := '0';
    
    signal init_meas_i      : std_logic := '0';
    signal freq_done_i      : std_logic := '0';
    signal path_done_i      : std_logic := '0';

    signal freq_val_i       : std_logic_vector(freq_data_length_c - 1 downto 0) := (others => '0');
    signal ifbw_val_i       : std_logic_vector(ifbw_data_length_c - 1 downto 0) := (others => '0');
    signal path_val_i       : std_logic_vector(path_data_length_c - 1 downto 0) := (others => '0');

    signal sample_done_i    : std_logic := '0';
    signal pll_locked_i     : std_logic := '1';
    signal switch_set_i     : std_logic := '1';

    --Outputs
    signal freq_val_o      : std_logic_vector(freq_data_length_c - 1 downto 0) := (others => '0');
    signal ifbw_val_o      : std_logic_vector(ifbw_data_length_c - 1 downto 0) := (others => '0');
    signal path_val_o      : std_logic_vector(path_data_length_c - 1 downto 0) := (others => '0');

    signal IQ_rdy_PL_o     : std_logic := '0';
    signal write_IQ_o      : std_logic := '0';
    signal start_sample_o  : std_logic := '0';

    signal state_o         : std_logic_vector(3 downto 0) := (others => '0');

    -- Clock period definitions
    constant clk_i_period : time := 12.5 ns;
   
begin

    MAIN_CONTROL_uut : main_control
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
    
        start_i         => start_i,
    
        init_meas_i     => init_meas_i,
        freq_done_i     => freq_done_i,
        path_done_i     => path_done_i,
    
        freq_val_i      => freq_val_i,
        ifbw_val_i      => ifbw_val_i,
        path_tx_val_i   => path_val_i,
        path_rx_val_i   => path_val_i,
    
        sample_done_i   => sample_done_i,
        pll_locked_i    => pll_locked_i,
        switch_set_i    => switch_set_i,
    
        state_o         => state_o,
    
        synth_seq_id_o  => open,
        en_set_sw_o     => open,
        en_set_freq_o   => open,
        en_rf_o         => open,
    
        start_sample_o  => start_sample_o,
    
        IQ_rdy_PL_o     => IQ_rdy_PL_o,
        write_IQ_o      => write_IQ_o,
    
        freq_val_o      => freq_val_o,
        ifbw_val_o      => ifbw_val_o,
        path_tx_val_o   => path_val_o,
        path_rx_val_o   => path_val_o
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
        wait for 1000 us;
        --init measure
        wait for 100 ns;
        init_meas_i <= '1';
        
        -- load freq
        wait for 200 ns;
        freq_val_i <= "000001";
        wait for 200 ns;
        ifbw_val_i <= "00001";
        wait for 200 ns;
        freq_done_i <= '1';

        -- load freq
        wait for 200 ns;
        freq_val_i <= "000010";
        wait for 200 ns;
        ifbw_val_i <= "00010";
        wait for 200 ns;
        freq_done_i <= '0';

        -- load freq
        wait for 200 ns;
        freq_val_i <= "000011";
        wait for 200 ns;
        ifbw_val_i <= "00011";
        wait for 200 ns;
        freq_done_i <= '1';

        -- load freq
        wait for 200 ns;
        freq_val_i <= "000100";
        wait for 200 ns;
        ifbw_val_i <= "00100";
        wait for 200 ns;
        freq_done_i <= '0';

        -- load path
        wait for 200 ns;
        path_val_i <= "111111111111111111111111";
        wait for 200 ns;
        path_done_i <= '1';

        -- load path
        wait for 200 ns;
        path_val_i <= "111111101111111111111111";
        wait for 200 ns;
        path_done_i <= '0';

        -- load path
        wait for 200 ns;
        path_val_i <= "111111001111111111111111";
        wait for 200 ns;
        path_done_i <= '1';

        -- end init
        wait for 200 ns;
        init_meas_i <= '0';

        -- start measurement
        wait for 1 us;
        start_i <= '1';
        wait for 200 ns;
        start_i <= '0';

        for i in 0 to 100 loop
            wait for 25 ns;
            sample_done_i <= '1';
            wait for 25 ns;
            sample_done_i <= '0';
            wait for 25 ns;
            freq_done_i <= '1';

            wait for 25 ns;
            sample_done_i <= '1';
            wait for 25 ns;
            sample_done_i <= '0';
            wait for 25 ns;
            freq_done_i <= '0';
        end loop;
        
        wait;
        
    end process;

    meas_proc: process
    begin
        wait for 5 us;

        wait;
    end process;
   

end Behavioral;
