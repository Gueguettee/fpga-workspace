----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2024 08:34:14 AM
-- Design Name: 
-- Module Name: key_lock_timed - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity toplevel is
    port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;

        Push0xSI : in std_logic;
        Push1xSI : in std_logic;
        Push2xSI : in std_logic;
        Push3xSI : in std_logic;

        RLEDxSO : out std_logic;
        GLEDxSO : out std_logic
    );
end toplevel;

architecture rtl of toplevel is

    component door_arbiter is
        port (
            clk_i : in STD_LOGIC;
            rst_i : in STD_LOGIC;

            KeyValid_i : in STD_LOGIC;
            Key_i : in STD_LOGIC_VECTOR (1 downto 0);

            GLED_o : out STD_LOGIC;
            RLED_o : out STD_LOGIC
        );
    end component door_arbiter;

begin

    door_arbiter : door_arbiter
    port map (
        clk_i => CLKxCI,
        rst_i => RSTxRI,
        KeyValid_i => KeyValid_s,
        Key_i => Key2_s,
        GLED_o => GLEDxSO,
        RLED_o => RLEDxSO
    );

end rtl;
