--=============================================================================
-- @file task3_1c_tb_sol.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=============================================================================
--
-- task3_1c_tb
--
-- @brief Code for DSD 2023 exam. Task 3.1c. This code describes a testbench for Task 3.1b
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR TASK3_1C_TB
--=============================================================================
entity task3_1c_tb is
end task3_1c_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of task3_1c_tb is

--=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================
  constant CLK_HIGH   : time := 4ns;
  constant CLK_LOW    : time := 4ns;
  constant CLK_PERIOD : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM   : time := 1ns; -- Used to push us a little bit after the clock edge

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================
  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal AxD : signed(8 - 1 downto 0) := (others => '0');
  signal BxD : signed(8 - 1 downto 0) := (others => '0');
  signal CxD : signed(8 - 1 downto 0) := (others => '0');
  signal DxD : signed(8 - 1 downto 0) := (others => '0');
  signal ZxD : signed(8 - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component task3_1b is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      AxDI : in signed(8 - 1 downto 0);
      BxDI : in signed(8 - 1 downto 0);
      CxDI : in signed(8 - 1 downto 0);
      DxDI : in signed(8 - 1 downto 0);

      ZxDO : out signed(8 - 1 downto 0)
    );
  end component task3_1b;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  dut: task3_1b
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      AxDI => AxD,
      BxDI => BxD,
      CxDI => CxD,
      DxDI => DxD,

      ZxDO => ZxD
    );

--=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_clk: process is
  begin
  -- TODO: Add your code here
    CLKxCI <= '0';
    wait for CLK_LOW;
    CLKxCI <= '1';
    wait for CLK_HIGH;
  end process p_clk;

--=============================================================================
-- RESET PROCESS
-- Process for generating initial reset
--=============================================================================
  p_reset: process is
  begin
  -- TODO: Add your code here
    RSTxRI <= '1';
    wait for 10ns + CLK_STIM;
    RSTxRI <= '0';
    wait;
  end process p_reset;

--=============================================================================
-- TEST PROCESS
--=============================================================================
  p_stim: process is
  begin
  -- TODO: Add your code here
    wait for 10ns + CLK_STIM;
    AxD <= to_signed(5, 8);
    BxD <= to_signed(10, 8);
    CxD <= to_signed(25, 8);
    DxD <= to_signed(0, 8);

    wait for CLK_PERIOD;
    AxD <= to_signed(30, 8);
    BxD <= to_signed(-40, 8);
    CxD <= to_signed(-95, 8);
    DxD <= to_signed(-1, 8);

    wait for CLK_PERIOD;
    AxD <= to_signed(-65, 8);
    BxD <= to_signed(15, 8);
    CxD <= to_signed(-35, 8);
    DxD <= to_signed(70, 8);

    wait for CLK_PERIOD;
    AxD <= to_signed(-25, 8);
    BxD <= to_signed(-45, 8);
    CxD <= to_signed(-100, 8);
    DxD <= to_signed(10, 8);

    wait for CLK_PERIOD;
    stop(0);

  end process p_stim;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
