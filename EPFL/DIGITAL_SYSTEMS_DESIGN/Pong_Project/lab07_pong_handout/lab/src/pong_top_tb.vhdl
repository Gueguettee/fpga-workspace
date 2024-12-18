--=============================================================================
-- @file pong_top_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pong_pkg.all;
use work.dsd_prj_pkg.all;

--=============================================================================
-- ENTITY DECLARATION FOR TESTBENCH
--=============================================================================
entity pong_top_tb is
end pong_top_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION FOR TESTBENCH
--=============================================================================
architecture tb of pong_top_tb is

  -- Signals for DUT ports
  signal CLK125xCI : std_logic := '0';
  signal RSTxRI    : std_logic := '1';

  -- Button inputs
  signal LeftxSI  : std_logic := '0';
  signal RightxSI : std_logic := '0';

  -- Timing outputs
  signal HSxSO : std_logic;
  signal VSxSO : std_logic;

  -- Data/color outputs
  signal RedxSO   : std_logic_vector(COLOR_BW - 1 downto 0);
  signal GreenxSO : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexSO  : std_logic_vector(COLOR_BW - 1 downto 0);

  -- Constants
  constant CLK_PERIOD : time := 8 ns; -- 125 MHz clock

begin

  --=============================================================================
  -- CLOCK GENERATION
  --=============================================================================
  clk_process : process
  begin
    while true loop
      CLK125xCI <= '0';
      wait for CLK_PERIOD / 2;
      CLK125xCI <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  --=============================================================================
  -- RESET GENERATION
  --=============================================================================
  reset_process : process
  begin
    RSTxRI <= '1';
    wait for 100 ns;
    RSTxRI <= '0';
    wait;
  end process;

  --=============================================================================
  -- DUT INSTANTIATION
  --=============================================================================
  dut : entity work.pong_top
    port map (
      CLK125xCI => CLK125xCI,
      RSTxRI    => RSTxRI,

      LeftxSI  => LeftxSI,
      RightxSI => RightxSI,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

  --=============================================================================
  -- SIMULATION BEHAVIOR
  --=============================================================================
  stimulus_process : process
  begin
    -- Wait for reset to deassert
    wait for 200 ns;

    -- Simulate Left button press
    LeftxSI <= '1';
    wait for 50 ns;
    LeftxSI <= '0';

    -- Simulate Right button press
    RightxSI <= '1';
    wait for 50 ns;
    RightxSI <= '0';

    -- Simulate a longer Left button press
    LeftxSI <= '1';
    wait for 200 ns;
    LeftxSI <= '0';

    -- End simulation
    wait for 500 ns;
    assert false report "Simulation finished" severity note;
    wait;
  end process;

end tb;
