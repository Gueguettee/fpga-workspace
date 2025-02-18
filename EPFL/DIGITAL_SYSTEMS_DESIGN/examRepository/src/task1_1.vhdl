--=====================================================================
-- @file task1_1.vhdl
--=====================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=====================================================================
entity task1_1 is
    port (
    CLKxCI, RSTxRI : in std_logic;
    In1xDI : in unsigned(8-1 downto 0);
    In2xDI : in unsigned(8-1 downto 0);
    In3xDI : in unsigned(8-1 downto 0);
    In4xDI : in unsigned(8-1 downto 0);
    OutputxDO : out unsigned(8-1 downto 0)
    );
end task1_1;
    
architecture rtl of task1_1 is
    signal In1_delayedxDN, In2_delayedxDN, In1_delayedxDP, In2_delayedxDP : unsigned(8-1 downto 0);
begin
    
    process(CLKxCI, RSTxRI)
    begin
        if (RSTxRI = '1') then
            In1_delayedxDP <= (others => '0');
            In2_delayedxDP <= (others => '0');
        elsif (CLKxCI'event and CLKxCI = '1') then
            In1_delayedxDP <= In1_delayedxDN;
            In2_delayedxDP <= In2_delayedxDN;
        end if;
    end process;

    In1_delayedxDN <= In1xDI;
    In2_delayedxDN <= In2xDI;

    OutputxDO <= resize(In1xDI + In2_delayedxDP, 9) when In1xDI > In2xDI  else
                 resize(In1_delayedxDP + In2xDI, 9) when In1xDI <= In3xDI  else
                 resize(In1_delayedxDP * In2xDI, 16) when In4xDI > In2xDI  else
                 (others => '0');

end rtl;