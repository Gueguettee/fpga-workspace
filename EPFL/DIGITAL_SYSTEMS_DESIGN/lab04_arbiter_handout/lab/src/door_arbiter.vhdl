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

entity door_arbiter is
    Port ( 
        clk_i : in STD_LOGIC;
        rst_i : in STD_LOGIC;

        KeyValid_i : in STD_LOGIC;
        Key_i : in STD_LOGIC_VECTOR (1 downto 0);

        GLED_o : out STD_LOGIC;
        RLED_o : out STD_LOGIC
    );
end door_arbiter;

architecture Behavioral of door_arbiter is

    type state_t is
    (
        P0,
        P1,

        A0,
        A1,

        D0,
        D1
    );

    signal state_s, next_state_s : state_t := P0;

    signal counter_s : integer range 0 to 200000000 := 0;
    signal counter_clear_s : std_logic := '0';
    signal counter_enable_s : std_logic := '0';

begin

    process(all)
    begin
        counter_clear_s <= '0';
        counter_enable_s <= '0';

        next_state_s <= state_s;

        GLED0_o <= '0';
        RLED0_o <= '0';
        GLED1_o <= '0';
        RLED1_o <= '0';

        case state_s is
            when P0 =>
                counter_clear_s <= '1';

                if Key0_i = '1' then
                    next_state_s <= A1;
                elsif Key1_i = '1' then
                    next_state_s <= A0;
                end if;

            when P1 =>
                counter_clear_s <= '1';

                if Key1_i = '1' then
                    next_state_s <= A0;
                elsif Key0_i = '1' then
                    next_state_s <= A1;
                end if;

            when A0 =>
                GLED0_o <= '1';

                counter_enable_s <= '1';
                
                if Key0_i = '0' then
                    next_state_s <= P0;
                elsif counter_s < 200000000 and Key1_i = '1' then
                    next_state_s <= D0;
                end if;

            when A1 =>
                GLED_o <= '1';

                counter_enable_s <= '1';

                if Key1_i = '0' then
                    next_state_s <= P1;
                elsif counter_s < 200000000 and Key0_i = '1' then
                    next_state_s <= D1;
                end if;

            when D0 =>
                GLED0_o <= '1';
                RLED1_o <= '1';

                counter_enable_s <= '1';

                if Key0_i = '0' and next_state_s = D0 then
                    next_state_s <= P0;
                elsif counter_s = 200000000 and Key1_i = '1' then
                    counter_clear_s <= '1';
                    next_state_s <= A1;
                end if;

            when D1 =>
                GLED0_o <= '1';
                RLED1_o <= '1';

                counter_enable_s <= '1';

                if Key1_i = '0' and next_state_s = D1 then
                    next_state_s <= P1;
                elsif counter_s = 200000000 and Key0_i = '1' then
                    counter_clear_s <= '1';
                    next_state_s <= A0;
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

    next_counter_s <=   0 when counter_clear_s = '1' else
                        counter_s + 1 when counter_enable_s = '1' and counter_s /= 200000000 else
                        counter_s;

    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            counter_s <= 0;
        elsif rising_edge(clk_i) then
            counter_s <= next_counter_s;
        end if;
    end process;

end Behavioral;
