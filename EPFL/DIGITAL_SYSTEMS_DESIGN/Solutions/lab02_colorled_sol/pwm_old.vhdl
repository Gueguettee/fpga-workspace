--=============================================================================
-- @file toplevel.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- pwm
--
-- @brief PWM circuit for the RGB LED lab (lab 2)
--
--=============================================================================
entity pwm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    PushxSI : in std_logic;
    LedxSO  : out std_logic
  );
end pwm;


architecture rtl of pwm is

  constant CNT_ADD : natural := 131072; -- 131072 = 2^17 since 2^(17+log2(8))=2^20, leading to overflow
                                        -- after 8 button presses (in principle, you only need a 3 bit adder)

  signal EdgexS               : std_logic;                -- Edge signal
  signal PushxSN, PushxSP     : std_logic;                -- Push button signals (registered)
  signal ThrCntxDN, ThrCntxDP : unsigned(20-1 downto 0);  -- Threshold signals (registered)
  signal PWMCntxDN, PWMCntxDP : unsigned(20-1 downto 0);  -- PWM signals (registered)
  signal PWMxS                : std_logic;                -- PWM Pulse signal

begin

-------------------------------------------------------------------------------
-- Edge detection
-------------------------------------------------------------------------------
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      PushxSP <= '0';
    elsif (CLKxCI'event and CLKxCI = '1') then
      PushxSP <= PushxSN;
    end if;
  end process;

  PushxSN <= PushxSI;
  EdgexS  <= PushxSN and (not PushxSP);

-------------------------------------------------------------------------------
-- Threshold generation
-------------------------------------------------------------------------------
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      ThrCntxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      ThrCntxDP <= ThrCntxDN;
    end if;
  end process;

  ThrCntxDN <= ThrCntxDP + CNT_ADD when EdgexS = '1' else ThrCntxDP;

-------------------------------------------------------------------------------
-- PWM pulse
-------------------------------------------------------------------------------
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      PWMCntxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      PWMCntxDP <= PWMCntxDN;
    end if;
  end process;

  PWMCntxDN <= PWMCntxDP + 1;
  PWMxS     <= '1' when (PWMCntxDP < ThrCntxDP) else '0';

  LedxSO <= PWMxS;

end rtl;
