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

  -- TODO: define the needed signals
  constant NBitsxC : integer := 20;
  signal PushxSN : std_logic;
  signal PushEdgexSN : std_logic;
  signal PWMxS  : std_logic;
  signal CounterxS : unsigned(NBitsxC-1 downto 0);
  signal CounterPWMxS : unsigned(NBitsxC-1 downto 0);
  signal OverflowxS : std_logic;
  signal GreaterS : std_logic;

begin

  -- TODO: Edge detection
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      PushxSN <= '0';
    elsif rising_edge(CLKxCI) then
      PushxSN <= not PushxSI;
    end if;
  end process;

  PushEdgexSN <= PushxSN and PushxSI;

  -- TODO: Threshold generation
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      CounterxS <= (others => '0');
      OverflowxS <= '0';
    elsif rising_edge(CLKxCI) then
      OverflowxS <= OverflowxS and GreaterS;
      if GreaterS = '1' then
        CounterxS <= (others => '0');
      else
        if (PushEdgexSN = '1') then
          -- add 2^17 to counter
          CounterxS <= CounterxS + "00100000000000000000";
        else 
          CounterxS <= CounterxS;
        end if;
      end if;
    end if;
  end process;

  GreaterS <= '1' when (CounterxS > "11011111111111111111") else '0';

  -- TODO: PWM pulse
  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      CounterPWMxS <= (others => '0');
    elsif rising_edge(CLKxCI) then
      if (CounterPWMxS >= "11111111111111111111") then
        CounterPWMxS <= (others => '0');
      else
        CounterPWMxS <= CounterPWMxS + 1;
      end if;
      if (CounterPWMxS < CounterxS) then
        PWMxS <= '1';
      else 
        PWMxS <= '0';
      end if;
    end if;
  end process;

  LedxSO <= PWMxS; -- assign to output

end rtl;
