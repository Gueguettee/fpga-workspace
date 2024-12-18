--=============================================================================
-- @file toplevel.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;

--=============================================================================
--
-- toplevel
--
-- @brief This file specifies the toplevel for the RGB LED lab (lab 2)
--
--=============================================================================
entity toplevel is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    PushRedxSI   : in std_logic;
    PushGreenxSI : in std_logic;
    PushBluexSI  : in std_logic;

    LedRedxSO   : out std_logic;
    LedGreenxSO : out std_logic;
    LedBluexSO  : out std_logic
  );
end toplevel;


architecture rtl of toplevel is

  component pwm
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      PushxSI : in std_logic;
      LedxSO  : out std_logic
    );
  end component;

begin

  -- TODO: instantiate the pwm module for each color
  pwm_red : pwm
  port map (
    CLKxCI => CLKxCI,
    RSTxRI => RSTxRI,
    PushxSI => PushRedxSI,
    LedxSO => LedRedxSO
  );

  pwm_green : pwm
  port map (
    CLKxCI => CLKxCI,
    RSTxRI => RSTxRI,
    PushxSI => PushGreenxSI,
    LedxSO => LedGreenxSO
  );

  pwm_blue : pwm
  port map (
    CLKxCI => CLKxCI,
    RSTxRI => RSTxRI,
    PushxSI => PushBluexSI,
    LedxSO => LedBluexSO
  );

end rtl;
