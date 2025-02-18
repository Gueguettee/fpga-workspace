--=============================================================================
-- @file task3_1b.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=============================================================================
--
-- task3_1b
--
-- @brief Code for DSD 2023 exam. Task 3.1b.
--
--=============================================================================

entity task3_1b is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    AxDI : in signed(8 - 1 downto 0);
    BxDI : in signed(8 - 1 downto 0);
    CxDI : in signed(8 - 1 downto 0);
    DxDI : in signed(8 - 1 downto 0);

    ZxDO : out signed(8 - 1 downto 0)
  );
end task3_1b;


architecture rtl of task3_1b is

  signal absAxDS, absBxDS, absCxDS : signed(8 - 1 downto 0);
  signal ZxDN : signed(8 - 1 downto 0);

begin

  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      ZxDO <= (others => '0');
    elsif rising_edge(CLKxCI) then
      ZxDO <= ZxDN;
    end if;
  end process;

  process(AxDI)
  begin
    absAxDS <= AxDI;
    if AxDI(7) = '1' then
      absAxDS <= not(AxDI) + "00000001";
    end if;
  end process;

  process(BxDI)
  begin
    absBxDS <= BxDI;
    if BxDI(7) = '1' then
      absBxDS <= not(BxDI) + "00000001";
    end if;
  end process;

  process(CxDI)
  begin
    absCxDS <= CxDI;
    if CxDI(7) = '1' then
      absCxDS <= not(CxDI) + "00000001";
    end if;
  end process;

  process(all)
  begin
    if absCxDS > "01000000" then
      ZxDN <= DxDI and absBxDS;
    else
      ZxDN <= DxDI and absAxDS;
    end if;
  end process;
  
end rtl;

