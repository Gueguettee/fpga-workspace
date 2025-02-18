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
-- toplevel
--
-- @brief This file specifies a basic toplevel circuit for lab3
--
--=============================================================================

entity toplevel is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    Push0xSI : in std_logic;
    Push1xSI : in std_logic;
    Push2xSI : in std_logic;
    Push3xSI : in std_logic;

    RLEDxSO : out std_logic;
    GLEDxSO : out std_logic
  );
end toplevel;

architecture rtl of toplevel is

  -- Component declaration
  component key_lock_timed is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      KeyValidxSI : in std_logic;
      KeyxDI      : in unsigned(2-1 downto 0);

      RLEDxSO : out std_logic;
      GLEDxSO : out std_logic
    );
  end component key_lock_timed;

  -- Signals
  signal KeyValidxS : std_logic;
  signal KeyxD      : unsigned(2-1 downto 0);

begin

  -- Translate one-hot keys into a Key code (0-3)
  -- With valid, it does not matter what value the key takes when none of the buttons are pressed
  KeyxD <= to_unsigned(0, 2) when Push0xSI = '1' else
           to_unsigned(1, 2) when Push1xSI = '1' else
           to_unsigned(2, 2) when Push2xSI = '1' else
           to_unsigned(3, 2) when Push3xSI = '1' else
           "--";

  -- KeyValidxS should only be asserted if one key is pressed
  KeyValidxS <= '1' when Push0xSI = '1' and Push1xSI = '0' and Push2xSI = '0' and Push3xSI = '0' else
                '1' when Push0xSI = '0' and Push1xSI = '1' and Push2xSI = '0' and Push3xSI = '0' else
                '1' when Push0xSI = '0' and Push1xSI = '0' and Push2xSI = '1' and Push3xSI = '0' else
                '1' when Push0xSI = '0' and Push1xSI = '0' and Push2xSI = '0' and Push3xSI = '1' else
                '0';

  -- KeyValidxS can also be checked by adding the push-button logic values together, only if it is 1
  -- can we raise KeyValidxS. The notation ("" & Push0xSI) converts a std_logic to unsigned.
  -- KeyValidxS <= '1' when (("" & Push0xSI) + ("" & Push1xSI) + ("" & Push2xSI) + ("" & Push3xSI)) = 1 else
                -- '0';

  -- Instantiate FSM
  i_key_lock_timed: key_lock_timed
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      KeyValidxSI => KeyValidxS,
      KeyxDI      => KeyxD,
      RLEDxSO     => RLEDxSO,
      GLEDxSO     => GLEDxSO
    );
end rtl;
