--=============================================================================
-- @file task6_sol.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task6_sol is
  port (
    In0xDI : in unsigned(8-1 downto 0);
    In1xDI : in unsigned(8-1 downto 0);
    In2xDI : in unsigned(8-1 downto 0);
    In3xDI : in unsigned(8-1 downto 0);

    OutxDO : out unsigned(8-1 downto 0)
  );
end task6_sol;

architecture rtl of task6_sol is

  signal Res0xD, Res1xD, Res2xD : unsigned(8-1 downto 0);
  signal Comp0xS, Comp1xS, Comp2xS : std_logic;

begin
  Comp0xS <= '1' when In0xDI < In1xDI else '0'; -- Comparators
  Comp1xS <= '1' when In2xDI < In3xDI else '0';
  Comp2xS <= '1' when Res0xD < Res1xD else '0';

  Res0xD <= In0xDI when Comp0xS = '1' else In1xDI; -- Mux
  Res1xD <= In2xDI when Comp1xS = '1' else In3xDI;
  Res2xD <= Res0xD when Comp2xS = '1' else Res1xD;

  OutxDO <= Res2xD;


  -- While the above seems more compact, it does not allow x-propagation! The 2 pieces of code synthesize
  -- to the same, only 1 comparator
  -- Comparators
  -- Comp0xS <= '1' when In0xDI <  In1xDI else
  --            '0' when In0xDI >= In1xDI else
  --            'X';

  -- Comp1xS <= '1' when In2xDI <  In3xDI else
  --            '0' when In2xDI >= In3xDI else
  --            'X';

  -- Comp2xS <= '1' when Res0xD <  Res1xD else
  --            '0' when Res0xD >= Res1xD else
  --            'X';

  -- -- Mux selection
  -- Res0xD <= In0xDI when Comp0xS = '1' else
  --           In1xDI when Comp0xS = '0' else
  --           (others => 'X');

  -- Res1xD <= In2xDI when Comp1xS = '1' else
  --           In3xDI when Comp1xS = '0' else
  --           (others => 'X');

  -- Res2xD <= Res0xD when Comp2xS = '1' else
  --           Res1xD when Comp2xS = '0' else
  --           (others => 'X');

end rtl;
