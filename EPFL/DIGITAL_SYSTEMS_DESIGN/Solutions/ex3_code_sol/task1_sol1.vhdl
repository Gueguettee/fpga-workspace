--=============================================================================
-- @file task1_sol1.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task1_sol1 is
  port (
    SelxSI : in std_logic;
    In0xDI : in std_logic;
    In1xDI : in std_logic;

    OutxDO : out std_logic
  );
end task1_sol1;


architecture rtl of task1_sol1 is
begin

  process(all)
  begin
    if SelxSI = '1' then
      OutxDO <= In1xDI;
    else
      OutxDO <= In0xDI;
    end if;
  end process;

end rtl;
