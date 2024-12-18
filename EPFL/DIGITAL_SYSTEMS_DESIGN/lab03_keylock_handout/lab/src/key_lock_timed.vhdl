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

entity key_lock_timed is
    Port ( 
        clk_i : in STD_LOGIC;
        rst_i : in STD_LOGIC;

        KeyValid_i : in STD_LOGIC;
        Key_i : in STD_LOGIC_VECTOR (1 downto 0);

        GLED_o : out STD_LOGIC;
        RLED_o : out STD_LOGIC
    );
end key_lock_timed;

architecture Behavioral of key_lock_timed is

    type state_t is
    (
        Open_state,
        Closed,

        Wrong1P,
        Wrong1R,
        Wrong2P,
        Wrong2R,
        Wrong3P,

        OK0P,
        OK0R,
        OK2P,
        OK2R,
        OKP
    );

    signal state_s, next_state_s : state_t := Closed;

    signal Counter_s : integer range 0 to 200000000 := 0;
    signal CountClear_s : std_logic := '0';
    signal CountEnable_s : std_logic := '0';

begin

    process(all)
    begin
        CountClear_s <= '0';
        CountEnable_s <= '0';

        next_state_s <= state_s;

        case state_s is
            when Open_state =>
                GLED_o <= '1';
                RLED_o <= '0';

                CountEnable_s <= '1';

                if Counter_s = 200000000 then
                    next_state_s <= Closed;
                end if;

            when Closed =>
                GLED_o <= '0';
                RLED_o <= '1';

                if KeyValid_i = '1' then
                    if Key_i /= "00" then
                        next_state_s <= Wrong1P;
                    else
                        next_state_s <= OK0P;
                    end if;
                end if;

            when Wrong1P =>
                GLED_o <= '0';
                RLED_o <= '0';
                
                if KeyValid_i = '0' then
                    next_state_s <= Wrong1R;
                end if;

            when Wrong1R =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '1' then
                    next_state_s <= Wrong2P;
                end if;

            when Wrong2P =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '0' then
                    next_state_s <= Wrong2R;
                end if;

            when Wrong2R =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '1' then
                    next_state_s <= Wrong3P;
                end if;

            when Wrong3P =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '0' then
                    next_state_s <= Closed;
                end if;

            when OK0P =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '0' then
                    next_state_s <= OK0R;
                end if;

            when OK0R =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '1' then
                    if Key_i /= "10" then
                        next_state_s <= Wrong2P;
                    else
                        next_state_s <= OK2P;
                    end if;
                end if;
                
            when OK2P =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '0' then
                    next_state_s <= OK2R;
                end if;

            when OK2R =>
                GLED_o <= '0';
                RLED_o <= '0';

                if KeyValid_i = '1' then
                    if Key_i /= "01" then
                        next_state_s <= Wrong3P;
                    else
                        next_state_s <= OKP;
                    end if;
                end if;

            when OKP =>
                GLED_o <= '0';
                RLED_o <= '0';

                CountClear_s <= '1';
                CountEnable_s <= '1';

                if KeyValid_i = '0' then
                    next_state_s <= Open_state;
                end if;

            when others =>
                GLED_o <= '0';
                RLED_o <= '0';
        end case;
    end process;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            state_s <= Closed;
        elsif rising_edge(clk_i) then
            state_s <= next_state_s;
        end if;
    end process;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            Counter_s <= 0;
        elsif rising_edge(clk_i) then
            if CountClear_s = '1' then
                Counter_s <= 0;
            elsif CountEnable_s = '1' then
                if Counter_s /= 200000000 then
                    Counter_s <= Counter_s + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
