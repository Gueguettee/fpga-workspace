---=============================================================================
-- @file task2_2.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task2_2 is
  port ( 
    CLKxCI    : in std_logic;
    RSTxRI    : in std_logic;
    ENxSI     : in std_logic;
    CLRxSI    : in std_logic;
    DATAxDI   : in std_logic_vector(8-1 downto 0);
    READYxSO  : out std_logic;
    DATAxDO   : out std_logic_vector(8-1 downto 0)
    );
end task2_2;

architecture rtl of task2_2 is
  signal SumxDN, SumxDP : unsigned(10-1 downto 0);
  signal CntxDN, CntxDP : unsigned(3-1 downto 0);
begin

process (CLKxCI, RSTxRI)
begin
  if (RSTxRI ='1') then
    SumxDP <= to_unsigned(0, 10);
    CntxDP <= to_unsigned(4, 3);
  elsif (CLKxCI'event and CLKxCI = '1') then
    SumxDP <= SumxDN;
    CntxDP <= CntxDN;
  end if;
end process;

SumxDN <= to_unsigned(0, 10) when (CLRxSI = '1') else
          resize(unsigned(DATAxDI), 10) + SumxDP when (ENxSI = '1') else
          SumxDP;

CntxDN <= to_unsigned(4, 3) when (CLRxSI = '1') else
          CntxDP - to_unsigned(1, 3) when (ENxSI = '1') else
          CntxDP;

-- Outputs
READYxSO <= '1' when (CntxDP = to_unsigned(0, 3)) else
            '0';
DATAxDO <= SumxDP (9 downto 2);

end rtl;