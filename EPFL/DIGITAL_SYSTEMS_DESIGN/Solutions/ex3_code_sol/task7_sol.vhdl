--=============================================================================
-- @file task7_sol.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task7_sol is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    SelxSI : in std_logic_vector(2-1 downto 0);

    AxDI : in unsigned(8-1 downto 0);
    BxDI : in unsigned(8-1 downto 0);
    CxDI : in unsigned(8-1 downto 0);
    DxDI : in unsigned(8-1 downto 0);

    OutxDO : out unsigned(8-1 downto 0)
  );
end task7_sol;


architecture rtl of task7_sol is

  signal Src0xD, Src1xD : unsigned(8-1 downto 0);
  signal ResxDN, ResxDP : unsigned(8-1 downto 0);

begin

  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      ResxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      ResxDP <= ResxDN;
    end if;
  end process;

  with SelxSI select
    Src0xD <= AxDI            when "00"|"01",
              DxDI            when "10"|"11",
              (others => 'X') when others;

  with SelxSI select
    Src1xD <= BxDI            when "00",
              CxDI            when "01",
              "00000001"      when "10"|"11",
              (others => 'X') when others;

  ResxDN <= Src0xD + Src1xD;
  OutxDO <= ResxDP;
end rtl;
