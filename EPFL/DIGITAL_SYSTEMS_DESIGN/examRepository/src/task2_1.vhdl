--=============================================================================
-- @file task2_1.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task2_1 is
  port ( 
    CLKxCI    : in std_logic;
    RSTxRI    : in std_logic;
    SELxSI    : in std_logic_vector(2-1 downto 0);
    DATAxDI   : in std_logic_vector(8-1 downto 0);
    DATAxDO   : out std_logic_vector(8-1 downto 0)
  );
end task2_1;

architecture rtl of task2_1 is
  signal ResxDN, ResxDP     : std_logic_vector(8-1 downto 0);
  signal ReLUxD             : std_logic_vector(8-1 downto 0);
  signal AbsValxD           : std_logic_vector(8-1 downto 0);
begin

process (CLKxCI, RSTxRI)
  begin
    if (RSTxRI ='1') then
      ResxDP <= to_signed(0, 8);
    elsif (CLKxCI'event and CLKxCI = '1') then
      ResxDP <= ResxDN;
    end if;
  end process;

ReLU <= "00000001" when (signed(DATAxDI) > 0) else
        "00000000";
AbsValxD  <= DATAxDI when (signed(DATAxDI) > 0) else
             std_logic_vector(signed(not(DATAxDI)) + to_signed(1, 8));
ResxDN <= ReLU when (SELxSI = "00") else
          AbsValxD when (SELxSI = "01") else
          std_logic_vector(resize(DATAxDI(7 downto 2), 8)) when (SELxSI = "10") else
          DATAxDI(7) & DATAxDI(3 downto 0) & "000";

-- Output
DATAxDO <= ResxDP;

end rtl;