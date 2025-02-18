--=============================================================================
-- @file task4_sol.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task4_sol is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    MaxPulsexSO : out std_logic
  );
end task4_sol;


architecture rtl of task4_sol is

  signal CNTxDN, CNTxDP : unsigned(4-1 downto 0);

begin

  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      CNTxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      CNTxDP <= CNTxDN;
    end if;
  end process;

  CNTxDN      <= CNTxDP + 1;
  MaxPulsexSO <= '1' when CNTxDP = "1111" else
                 '0';

end rtl;
