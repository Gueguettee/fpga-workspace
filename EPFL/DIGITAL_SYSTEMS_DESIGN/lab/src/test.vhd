--=============================================================================
-- @file toplevel.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- toplevel
--
-- @brief This file specifies a basic toplevel circuit for the Vivado
-- introduction in the Digital systems design class (EE-334) taught at EPFL.
-- The file is a bit verbose for a file of this size but the comments serve to
-- illustrate the different parts of a VHDL file.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR TOPLEVEL
--=============================================================================
entity toplevel is
  port (
    clk_i : in std_logic;
    reset_i : in std_logic;

    pulse_o : out std_logic
  );
end toplevel;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of toplevel is

    signal cnt_s : std_logic_vector(3 downto 0);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

    process(clk_i, reset_i)
    begin
        if (rising_edge(clk_i)) then
            if (reset_i = '1') then
                cnt_s <= "0000";
                pulse_o <= '0';
            else
                cnt_s <= std_logic_vector(unsigned(cnt_s) + "0001");
                if (cnt_s = "1111") then
                    pulse_o <= '1';
                else
                    pulse_o <= '0';
                end if;
            end if;
        end if;
    end process;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
