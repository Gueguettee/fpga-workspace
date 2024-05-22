----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    ir - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity ir is
	port (
        clk_i : in std_logic;
        reset_i : in std_logic;

        ldir_i : in std_logic;
        ir_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
        ir_o : out std_logic_vector(cINSTR_SIZE-1 downto 0)
	);
end ir;

architecture Behavioral of ir is

    signal ir_s : std_logic_vector(cINSTR_SIZE-1 downto 0) := (others => '0');

    begin
        ir_o <= ir_s;

        ir_process: process(clk_i, reset_i)
        begin
            if reset_i = cRESET_ON then
                ir_s <= (others => '0');
            elsif rising_edge(clk_i) then
                if ldir_i = '1' then
                    ir_s <= ir_i;
                end if;
            end if;
        end process;
        
end Behavioral;

