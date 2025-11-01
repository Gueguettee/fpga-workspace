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
use work.TL_VNAMI_MAIN_pkg.all;
use work.SPI_synth_pkg.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_SPI_synthesizer is
--  Port ( );
end TB_SPI_synthesizer;

architecture Behavioral of TB_SPI_synthesizer is

    --Inputs
    signal clk_i : std_logic;
    signal reset_i : std_logic;
    signal seq_id_i : seq_id_t;
    signal start_seq_i : std_logic;
    signal freq_i : std_logic_vector(freq_data_length_c-1 downto 0);
    signal RF_power_i : power_t;
    signal LO_power_i : power_t;
    signal pll_locked_o : std_logic;
    signal seq_done_o : std_logic;
    signal RF_MUXout_i : std_logic;
    signal RF_SCK_o : std_logic;
    signal RF_SDI_o : std_logic;
    signal RF_CSB_o : std_logic;
    signal LO_MUXout_i : std_logic;
    signal LO_SCK_o : std_logic;
    signal LO_SDI_o : std_logic;
    signal LO_CSB_o : std_logic;

    -- Clock period definitions
    constant clk_i_period : time := 12.5 ns;
   
begin

    controler : SPI_synth_controller
    generic map(
        SPI_CLK_DIVIDER => 10
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        
        seq_id_i        => seq_id_i,
        start_seq_i     => start_seq_i,
        freq_i          => freq_i,
        RF_power_i      => RF_power_i,
        LO_power_i      => LO_power_i,

        pll_locked_o    => pll_locked_o,
        seq_done_o      => seq_done_o,

        RF_MUXout_i     => RF_MUXout_i,
        RF_SCK_o        => RF_SCK_o,
        RF_SDI_o        => RF_SDI_o,
        RF_CSB_o        => RF_CSB_o,

        LO_MUXout_i     => LO_MUXout_i,
        LO_SCK_o        => LO_SCK_o,
        LO_SDI_o        => LO_SDI_o,
        LO_CSB_o        => LO_CSB_o
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
        wait for 100 ns;
        reset_i <= '0';
        wait;
   end process;
   
-- Signal process
    signal_proc: process
    begin
        start_seq_i <= '0';
        LO_MUXout_i <= '0';
        RF_MUXout_i <= '1';
        seq_id_i <= SEQ_ID_INIT;
        freq_i <= "1010101";
        RF_power_i <= (others => '0');
        LO_power_i <= (others => '0');

        wait for 1000 ns;

        start_seq_i <= '1';

        wait for 100 ns;

        start_seq_i <= '0';

        wait for 20 us;

        seq_id_i <= SEQ_ID_SET_FREQ_VCO;

        start_seq_i <= '1';

        wait for 100 ns;

        start_seq_i <= '0';

        wait;
        
    end process;

end Behavioral;
