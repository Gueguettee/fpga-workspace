----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    registers - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity registers is
	port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        input_bus_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
        
        a_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
        b_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
        c_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
        
        w_reg_i : in std_logic_vector(cREG_SEL_SIZE-1 downto 0);
        reg2_i : in std_logic_vector(cREG_SEL_SIZE-1 downto 0);
        reg3_i : in std_logic_vector(cREG_SEL_SIZE-1 downto 0); 
        
        rw_i  : in std_logic;
        sela_i : in std_logic          
	);
end registers;

architecture Behavioral of registers is

    signal registers_s : tRegister := (others => (others => '0'));
	
	signal outA_s, outB_s, outC_s : std_logic_vector(cREG_SEL_SIZE-1 downto 0);
	
begin
    selOut: for i in cREG_SEL_SIZE-1 downto 0 generate
    begin
            selOutA: mux port map(
                    a_i => w_reg_i(i),
                    b_i => reg2_i(i),
                    sel_i => sela_i,
                    z_o => outA_s(i)
            );
            --selOutB: mux port map(
            --        a_i => reg2_i(i),
            --        b_i => reg3_i(i),
            --        sel_i => sela_i,
            --        z_o => outB_s(i)
            --);
    end generate;
    
    outB_s <= reg2_i;
    outC_s <= reg3_i;

	registers_process: process(clk_i, reset_i)
    begin
        if reset_i = cRESET_ON then
            registers_s <= (others => (others => '0'));
            a_o <= (others => '0');
            b_o <= (others => '0');
            c_o <= (others => '0');
        elsif rising_edge(clk_i) then
            if rw_i = cREAD then
                a_o <= registers_s(to_integer(unsigned(outA_s)));
                b_o <= registers_s(to_integer(unsigned(outB_s)));
                c_o <= registers_s(to_integer(unsigned(outC_s)));
            elsif rw_i = cWRITE then
                registers_s(to_integer(unsigned(w_reg_i))) <= input_bus_i;
            end if;
        end if;
    end process;

end Behavioral;

