--=============================================================================
-- @file task4_2c.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MULTSEL is
  port ( 
  AxDI     : in signed(32-1 downto 0);
  BxDI     : in signed(32-1 downto 0);
  CxDI     : in signed(32-1 downto 0);
  DxDI     : in signed(32-1 downto 0);
  SELYxSI  : in std_logic_vector(2-1 downto 0);
  YxDO     : out signed(64-1 downto 0)
  );
end MULTSEL;

architecture optimized of MULTSEL is
  signal temp1, temp2 : signed(32-1 downto 0);
begin

  temp1 <= AxDI when SELYxSI = "00" else
           BxDI when SELYxSI = "01" else
           CxDI when SELYxSI = "10" else
           AxDI;

  temp2 <= BxDI when SELYxSI = "00" else
           CxDI when SELYxSI = "01" else
           DxDI when SELYxSI = "10" else
           BxDI;

  YxDO <= temp1 * temp2;

end optimized;