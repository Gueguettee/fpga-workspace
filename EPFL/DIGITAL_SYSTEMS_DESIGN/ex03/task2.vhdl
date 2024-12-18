--=============================================================================
-- @file task2.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task2 is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    AxDI : in unsigned(8-1 downto 0);
    BxDI : in unsigned(8-1 downto 0);
    CxDI : in unsigned(8-1 downto 0);
    DxDI : in unsigned(8-1 downto 0);

    OutxDO : out unsigned(8-1 downto 0)
  );
end task2;


architecture rtl of task2 is

  signal ResxDN, ResxDP : unsigned(8-1 downto 0);

begin

  process(CLKxCI, RSTxRI)
  begin
    if (RSTxRI = '1') then
      ResxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      ResxDN <= ResxDP;
    end if;
  end process;
  ResxDN <= AxDI + BxDI     when CxDI + DxDI > 1 else
            AxDI - BxDI - 1 when CxDI > DxDI and DxDI /= 0
            AxDI + 1

  OutxDO <= ResxDP;
end rtl;
