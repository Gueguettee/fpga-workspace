--=============================================================================
-- @file tb_task6.vhdl
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
-- tb_task6
--
-- @brief This file specifies the testbench for task 6
--
--=============================================================================

entity tb_task6 is
end tb_task6;


architecture tb of tb_task6 is

  constant DELAY: time := 10 ns;

  signal In0xDI : unsigned(8-1 downto 0) := (others => '0');
  signal In1xDI : unsigned(8-1 downto 0) := (others => '0');
  signal In2xDI : unsigned(8-1 downto 0) := (others => '0');
  signal In3xDI : unsigned(8-1 downto 0) := (others => '0');

  signal OutxDO : unsigned(8-1 downto 0);

  component task6 is
    port (
      In0xDI : in unsigned(8-1 downto 0);
      In1xDI : in unsigned(8-1 downto 0);
      In2xDI : in unsigned(8-1 downto 0);
      In3xDI : in unsigned(8-1 downto 0);

      OutxDO : out unsigned(8-1 downto 0)
    );
  end component;


begin

  dut: task6
    port map (
      In0xDI => In0xDI,
      In1xDI => In1xDI,
      In2xDI => In2xDI,
      In3xDI => In3xDI,

      OutxDO => OutxDO
    );


  p_stim: process
  begin

    wait for DELAY;

    In0xDI <= "00000000";
    In1xDI <= "00000010";
    In2xDI <= "00000100";
    In3xDI <= "00001000";
    wait for DELAY;

    -- TODO: Add your own test-cases here! Remember to wait for DELAY between

    stop(0);

  end process;

end tb;
