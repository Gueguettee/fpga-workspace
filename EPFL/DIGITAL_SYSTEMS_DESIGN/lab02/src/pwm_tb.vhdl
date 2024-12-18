--=============================================================================
-- @file pwm_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;

--=============================================================================
--
-- pwm_tb
--
-- @brief This file specifies the testbench for the RGB LED lab (lab 2).
--
-- This test will
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR pwm_tb
--=============================================================================
entity pwm_tb is
end pwm_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of pwm_tb is

  -- Constants
  constant CLK_HIGH : time := 4ns;      -- 125 MHz clk freq
  constant CLK_LOW  : time := 4ns;
  constant CLK_PER  : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM : time := 1ns;      -- Used to push us a little bit after the clock edge
  constant CLK_LIM  : integer := 2**22; -- Stops simulation from running forever if circuit is not correct

  constant CNT_ADD : integer := 2**17;      -- Value to add to counter for each button press
  constant CNT_LIM : integer := 2**20 - 1;  -- Max value of counter

  -- DUT signals
  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal PushxSI : std_logic := '0';
  signal LedxSO  : std_logic;


--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component pwm is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      PushxSI : in std_logic;
      LedxSO  : out std_logic
    );
  end component;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  dut: pwm
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      PushxSI => PushxSI,
      LedxSO  => LedxSO
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
-- Process for generating the reset signal
--=============================================================================
  p_reset: process is
  begin
    RSTxRI <= '1';
    wait until rising_edge(CLKxCI);   -- Align to clock rising edge
    wait for (2*CLK_PER + CLK_STIM);  -- Align to CLK_STIM ns after rising edge
    RSTxRI <= '0';
    wait;
  end process p_reset;

--=============================================================================
-- TEST PROCESSS
--=============================================================================
  p_stim: process

    variable CCLedHigh    : integer := 0; -- Cycle where LedxSO was set high
    variable CCLedLow     : integer := 0; -- Cycle where LedxSO was set low
    variable LedRisingDetected  : integer := 0;
    variable LedFallingDetected : integer := 0;

    variable ClkCnt : integer := 0; -- Free-running clock-cycle counter

    variable LEDPrev : std_logic := '0';

    variable PulseW     : integer := 0; -- Pulse width in clock cycles
    variable PulseWGold : integer := 0;

  begin
    wait until RSTxRI = '0';

    for PushIdx in 1 to 7 loop -- The module will reset after 8 button presses (need initial push to turn on)
                               -- This means that the 7th button press is the last one
      PushxSI <= '1';
      wait for CLK_PER;
      PushxSI <= '0';
      wait for CNT_ADD*CLK_PER; -- When pushing, the free-running counter may give a pulse
                                -- which is too short depending on the current counter value.
                                -- We wait until this pulse dies out before measuring the first pulse

      -- Detect rising- and falling-edges of LedxSO and verify pulse width between these
      for ClkIdx in 1 to CLK_LIM loop
        LEDPrev := LedxSO;
        ClkCnt  := ClkCnt + 1;
        wait for CLK_PER;

        -- Detect rising edge of LedxSO (assuming neither rising nor falling edge has been detected yet)
        if (LEDPrev = '0') and (LedxSO = '1') and (LedRisingDetected = 0 and LedFallingDetected = 0) then
          CCLedHigh         := ClkCnt;
          LedRisingDetected := 1;
        end if;

        -- Detect falling edge of LedxSO (only after rising edge has been observed first)
        if (LEDPrev = '1') and (LedxSO = '0') and (LedRisingDetected = 1 and LedFallingDetected = 0) then
          CCLedLow           := ClkCNT;
          LedFallingDetected := 1;
        end if;

        -- If both rising and falling edges have been observed, verify the pulse width
        if (LedRisingDetected = 1 and LedFallingDetected = 1) then
          PulseW     := CCLedLow - CCLedHigh;
          PulseWGold := PushIdx * CNT_ADD;

          if PulseW = PulseWGold then
            report "Pulse width " & integer'image(PulseW) & " cycles, expected " & integer'image(PulseWGold) & " good work!";
            LedRisingDetected  := 0;
            LedFallingDetected := 0;
            exit;
          else
            report "Pulse width " & integer'image(PulseW) & " cycles, expected " & integer'image(PulseWGold) & " try again!" severity warning;
            LedRisingDetected  := 0;
            LedFallingDetected := 0;
          end if;
        end if;
      end loop;
    end loop;

    PushxSI <= '1';
    wait for CLK_PER;
    PushxSI <= '0';

    wait for CLK_PER;
    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
