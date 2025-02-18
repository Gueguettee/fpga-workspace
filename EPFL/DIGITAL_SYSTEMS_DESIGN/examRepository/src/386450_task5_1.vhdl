--=============================================================================
-- @file task5_1.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity task5_1 is
    port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;
        BtnReqSI : in std_logic;
        LightSO : out std_logic_vector(2-1 downto 0)
    );
end task5_1;

architecture rtl of task5_1 is

    signal cntxdp, cntxdn : unsigned(5-1 downto 0);

    type state_t is
    (
        RedST,
        GreenST,
        PedesST,
        YellST
    );
    signal statexdp, statexdn : state_t := RedST;

begin
        
    process(CLKxCI, RSTxRI)
    begin
        if (RSTxRI = '0') then
            cntxdp <= (others => '0');
            statexdp <= RedST;
        elsif (CLKxCI'event and CLKxCI = '1') then
            cntxdn <= cntxdp;
            statexdn <= statexdp;
        end if;
    end process;

    process(all)
    begin
        cntxdn <= cntxdp + 1;
        
        statexdn <= statexdp;
        case statexdp is
            when RedST =>
                LightSO <= "00";
                if cntxdp = "00001010" then
                    statexdn <= GreenST;
                    cntxdn <= (others => '0');
                end if;
            when GreenST =>
                LightSO <= "01";
                if cntxdp = "00011110" then
                    statexdn <= YellST;
                    cntxdn <= (others => '0');
                elsif BtnReqSI = '1' then
                    if cntxdp < "00010100" then
                        statexdn <= PedesST;
                        cntxdn <= (others => '0');
                    end if;
                end if;
            when PedesST =>
                LightSO <= "01";
                if cntxdp = "00001010" then
                    statexdn <= YellST;
                    cntxdn <= (others => '0');
                end if;
            when YellST =>
                LightSO <= "10";
                if cntxdp = "00000101" then
                    statexdn <= RedST;
                    cntxdn <= (others => '0');
                end if;
        end case;
    end process;

end architecture rtl;
