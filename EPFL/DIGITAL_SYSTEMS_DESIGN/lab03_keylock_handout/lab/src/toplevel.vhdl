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

    component key_lock_timed is
        port (
            clk_i : in STD_LOGIC;
            rst_i : in STD_LOGIC;
            KeyValid_i : in STD_LOGIC;
            Key_i : in STD_LOGIC_VECTOR (1 downto 0);
            GLED_o : out STD_LOGIC;
            RLED_o : out STD_LOGIC
        );
    end component key_lock_timed;

    signal Key_s : STD_LOGIC_VECTOR (3 downto 0);
    signal Key2_s : STD_LOGIC_VECTOR (1 downto 0);
    signal KeyValid_s : std_logic;

begin

    Key_s(0) <= Push0xSI;
    Key_s(1) <= Push1xSI;
    Key_s(2) <= Push2xSI;
    Key_s(3) <= Push3xSI;
    
    Key2_s <= "00"  when Push0xSI = '1' else
              "01"  when Push1xSI = '1' else
              "10"  when Push2xSI = '1' else
              "11"  when Push3xSI = '1' else
              "00";     

    KeyValid_s <= '1' when Key_s = "0001" or Key_s = "0010" or Key_s = "0100" or Key_s = "1000" else '0';

    key_lock_timed_inst : key_lock_timed
    port map (
        clk_i => CLKxCI,
        rst_i => RSTxRI,
        KeyValid_i => KeyValid_s,
        Key_i => Key2_s,
        GLED_o => GLEDxSO,
        RLED_o => RLEDxSO
    );

end rtl;
