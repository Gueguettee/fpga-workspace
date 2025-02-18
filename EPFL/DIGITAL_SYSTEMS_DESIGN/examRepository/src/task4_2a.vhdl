--=============================================================================
-- @file task4_2a.vhdl
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

architecture unoptimized of MULTSEL is
begin
with SELYxSI select
  YxDO <= AxDI * BxDI when "00",
          BxDI * CxDI when "01",
          CxDI * DxDI when "10",
          AxDI * BxDI when others;
end unoptimized;