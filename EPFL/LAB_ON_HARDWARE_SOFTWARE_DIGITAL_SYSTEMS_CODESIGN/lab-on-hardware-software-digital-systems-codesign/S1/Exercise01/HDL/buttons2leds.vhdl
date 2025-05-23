library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Buttons2Leds is
    port (
        btns : in std_logic_vector(3 downto 0);
        leds : out std_logic_vector(3 downto 0)
    );
end Buttons2Leds;
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
architecture rtl of Buttons2Leds is
begin
leds <= btns;
end rtl;