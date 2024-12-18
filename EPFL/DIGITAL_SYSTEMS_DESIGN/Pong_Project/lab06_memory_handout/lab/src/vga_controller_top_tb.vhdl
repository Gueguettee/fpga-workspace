--=============================================================================
-- @file vga_controller_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller_tb
--
-- @brief This file specifies the testbench of the VGA controller
--
-- We verify the following:
--  * The width of the sync pulses
--  * The length of the horizontal line
--  * The duration of a frame
--
-- Note that until the first verticalical sync is observed, the measured length is
-- most likely not correct (but this is okay!).
--
-- We verify based on the number of clock cycles, but we also print the expected
-- and observed time in nanoseconds.
--
-- The testbench contains golden values.
--
-- For the timing parameters, see http://tinyvga.com/vga-timing/1024x768@70Hz
-- As these parameters use a negative polarity for the sync signals, we count the
-- duration from the falling-edge of the sync signals to their rising-edge
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR vga_controller_top_tb
--=============================================================================
entity vga_controller_top_tb is
end entity vga_controller_top_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of vga_controller_top_tb is

--=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================
  constant CLK_HIGH : time := 6.667 ns; -- Clock is 75 MHz, approximate with 6.667 ns, 74.996 MHz
  constant CLK_LOW  : time := 6.667 ns;
  constant CLK_PER  : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM : time := 1 ns;

  constant FRAME_WIDTH  : integer := HS_DISPLAY + HS_FRONT_PORCH + HS_PULSE + HS_BACK_PORCH; -- See http://tinyvga.com/vga-timing/1024x768@70Hz
  constant FRAME_HEIGHT : integer := (VS_DISPLAY + VS_FRONT_PORCH + VS_PULSE + VS_BACK_PORCH)*FRAME_WIDTH;

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================

  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal HSxSO : std_logic;
  signal VSxSO : std_logic;

  signal RedxSO   : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal GreenxSO : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal BluexSO  : std_logic_VECTOR(COLOR_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component vga_controller_top is
    port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
  end component vga_controller_top;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
-------------------------------------------------------------------------------
-- The design under test
-------------------------------------------------------------------------------
  dut: vga_controller_top
    port map (
      CLK125xCI => CLKxCI,
      RSTxRI => RSTxRI,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

--=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_clock: process is
  begin
    CLKxCI <= '0';
    wait for CLK_LOW;
    CLKxCI <= '1';
    wait for CLK_HIGH;
  end process p_clock;

--=============================================================================
-- RESET PROCESS
-- Process for generating initial reset
--=============================================================================
  p_reset: process is
  begin
    RSTxRI <= '1';
    wait until CLKxCI'event and CLKxCI = '1'; -- Align to clock
    wait for (2*CLK_PER + CLK_STIM);
    RSTxRI <= '0';
    wait;
  end process p_reset;

end architecture tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
