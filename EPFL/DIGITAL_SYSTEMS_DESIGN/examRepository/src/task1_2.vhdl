--=============================================================================
-- @file task1_2.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=============================================================================
--
-- task1_2
--
-- Code for DSD 2024 exam. Task 1.1.
--
--=============================================================================

entity task1_2 is
    port (
    CLKxCI, RSTxRI : in std_logic;
    OFFxSI : in std_logic;
    AxDI : in unsigned(8-1 downto 0);
    BxDI : in unsigned(8-1 downto 0);
    SELxSI : in std_logic_vector(2-1 downto 0); 
    OutxDO : out unsigned(16-1 downto 0)
    );
end task1_2;
    
architecture rtl of task1_2 is
    signal AddxD: unsigned(16-1 downto 0);
    signal MultxD : unsigned(16-1 downto 0); 
begin
    
    process(CLKxCI, RSTxRI)
    begin
        if (RSTxRI = '1') then
            AddxD <= (others => '0');
            MultxD <= (others => '0');
        elsif (CLKxCI'event and CLKxCI = '1') then
            if (OFFxSI = '1') then
                AddxD <= (others => '0');
                MultxD <= (others => '0');
            end if;
            AddxD <= resize(AxDI + BxDI,16);
            MultxD <= resize(AxDI * BxDI,16);
        end if;
    end process;

    process(all)
    begin
        if (SELxSI="01") then
            OutxDO <= AddxD;
        end if;
        if (SELxSI="10") then
            OutxDO <= MultxD;
        end if;
    end process;
end rtl;