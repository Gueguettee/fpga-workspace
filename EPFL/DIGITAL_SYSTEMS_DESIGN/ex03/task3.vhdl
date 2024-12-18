--=============================================================================
-- @file task3.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task3 is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    Sel0xSI : in std_logic;
    Sel1xSI : in std_logic;

    AxDI : in unsigned(8-1 downto 0);
    BxDI : in unsigned(8-1 downto 0);
    CxDI : in unsigned(8-1 downto 0);
    DxDI : in unsigned(8-1 downto 0);

    OutxDO : out unsigned(8-1 downto 0)
  );
end task3;


architecture rtl of task3 is

  signal ResxDN, ResxDP : unsigned(8-1 downto 0);

begin

  process(CLKxCI)
  begin
    if (RSTxRI = '1') then
      ResxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      ResxDP <= ResxDN;
    end if;
  end process;

  process()
  begin
    if Sel0xSI = '1'
      ResxDN <= AxDI + BxDI;
    elsif Sel1xSI = '1'
      ResxDN <= AxDI + CxDI;
    else
      ResxDN <= DxDI + 1;
    end if;
  end process;

  OutxDO <= ResxDP;
end rtl;
