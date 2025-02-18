--=============================================================================
-- @file task5_sol.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task5_sol is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    SelxSI : in std_logic_vector(2-1 downto 0);

    AxDI : in unsigned(8-1 downto 0);
    BxDI : in unsigned(8-1 downto 0);

    OutxDO : out unsigned(8-1 downto 0)
  );
end task5_sol;


architecture rtl of task5_sol is

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
    ResxDN <= AxDI + 1        when "00",
              AxDI - BxDI - 1 when "01",
              AxDI + BxDI     when "10" | "11",
              (others => 'X') when others;

  OutxDO <= ResxDP;
end rtl;
