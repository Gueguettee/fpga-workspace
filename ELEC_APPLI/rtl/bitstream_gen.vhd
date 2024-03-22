----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: Eric Fragni�re
-- 
-- Create Date: 21.03.2022 15:25:28
-- Design Name: 
-- Module Name: bitstream_gen - Behavioral
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
use std.textio.all;

entity bitstream_gen is
    Port ( clock : in STD_LOGIC;
           bitstream : out STD_LOGIC);
end bitstream_gen;

architecture Behavioral of bitstream_gen is

    constant FILE_PATH: string:= "C:\git\fpga-workspace\ELEC_APPLI";
    --constant FILE_PATH: string:= "C:\Users\eric.fragnier\TP_ELAP\";
    signal eof: std_logic := '0';
    
    begin
       process (clock)
       file bitstream_file: text open READ_MODE is FILE_PATH&"\output.txt";
       variable bit_line: line;
       variable current_bit: integer;
       begin
          if falling_edge(clock) then
             if eof = '0' then
                readline(bitstream_file, bit_line);
                read(bit_line, current_bit);
                if current_bit = 1 then bitstream <= '1'; else bitstream <= '0'; end if;
                if endfile(bitstream_file) then eof <= '1'; end if;
             end if;
          end if; 
       end process;
end Behavioral;