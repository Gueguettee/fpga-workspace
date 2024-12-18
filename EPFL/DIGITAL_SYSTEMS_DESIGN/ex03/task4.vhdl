--=============================================================================
-- @file task4.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task4 is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    MaxPulsexSO : out std_logic
  );
end task4;


architecture rtl of task4 is

  signal CNTxDP : unsigned(4-1 downto 0);

begin

  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      CNTxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      CNTxDP <= CNTxDP + 1;
    end if;
  end process;

  process(CNTxDP)
  begin
    if CNTxDP = "1111" then
      MaxPulsexSO <= '1';
    else
      MaxPulsexSO <= '0';
    end if;¨
  end process;

end rtl;
