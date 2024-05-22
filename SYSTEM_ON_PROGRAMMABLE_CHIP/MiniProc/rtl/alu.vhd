----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    alu - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.miniproc_pkg.all;

entity alu is
	port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        inalu_i  : in std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
        opcode_alu_i : in std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
        ldres_i  : in std_logic;
        ldflg_i  : in std_logic;
        
        a_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
        b_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
        c_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
        
        flag_o   : out std_logic;
        result_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
	);
end alu;

architecture Behavioral of alu is

    signal a_s, b_s, c_s : std_logic_vector(cDATA_SIZE-1 downto 0);

    signal result_s : std_logic_vector(cDATA_SIZE-1 downto 0);
    signal result_part_2_s : std_logic_vector(2*cDATA_SIZE-1 downto 0);

    signal flag_s : std_logic;
    signal ldflg_s, ldres_s : std_logic;

begin
    a_s <= a_i;

    selInput: for i in cDATA_SIZE-1 downto 0 generate
    begin
        selInputB: mux port map(
            a_i => '0',
            b_i => b_i(i),
            sel_i => inalu_i(0),
            z_o => b_s(i)
        );
        selInputC: mux port map(
            a_i => '0',
            b_i => c_i(i),
            sel_i => inalu_i(1),
            z_o => c_s(i)
        );
    end generate;

    second_alu: process(b_s, c_s)
    begin
        result_part_2_s <= std_logic_vector(signed(b_s) * signed(c_s));
    end process;

    main_alu: process(opcode_alu_i, a_s, result_part_2_s)
    begin
        flag_s <= '0';
        result_s <= a_s;

        case opcode_alu_i is
            when cMAC_OP =>
                result_s <= std_logic_vector(signed(a_s) + signed(result_part_2_s(cDATA_SIZE-1 downto 0)));
            when cDEC_OP =>
                result_s <= std_logic_vector(signed(a_s) - 1);
            when cEQL0_OP =>
                if signed(a_s) = 0 then
                        flag_s <= '1';
                end if;
            when others =>
                null;
        end case;
    end process;

    process(ldres_i, ldflg_i)
    begin
        ldres_s <= ldres_i;
        ldflg_s <= ldflg_i;
    end process;

    process(clk_i, reset_i)
    begin
        if reset_i = cRESET_ON then
            result_o <= (others => '0');
            flag_o <= '0';
        elsif rising_edge(clk_i) then
            if ldres_s = '1' then
                result_o <= result_s;
            end if;
            if ldflg_s = '1' then
                flag_o <= flag_s;
            end if;
        end if;
    end process;

end Behavioral;

