----------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: Eric Fragni�re
-- 
-- Create Date: 23.03.2022 09:23:46
-- Design Name: 
-- Module Name: SD_filter_testbench - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.SD_filter_pkg.all;

entity SD_filter_testbench is
--  Port ( );
end SD_filter_testbench;

architecture Behavioral of SD_filter_testbench is

    constant FILE_PATH: string:= "C:\git\fpga-workspace\ELEC_APPLI";
    constant HEADER: string:= "time/us,fir,iir";
    constant PERIOD: time:= 1 us;
    constant RST_DURATION: time:= 1 us;
    constant MAX_SIM_TIME: time:= 100000 ms;
    
    signal clock: std_logic := '0';
    signal reset: std_logic := '1';
    signal data_fir: std_logic_vector (B-1 downto 0);
    signal data_iir: std_logic_vector (B_IIR-1 downto 0);
    signal bitstream: std_logic;
    
    

begin
   reset <= '0' after RST_DURATION;

   process
      begin 
         while NOW < MAX_SIM_TIME
         loop
            clock <= not clock;
            wait for PERIOD/2;
         end loop;
   end process;
   
   SDMOD: bitstream_gen
   port map (
      clock => clock,
      bitstream => bitstream
   );
   
   FIR: FIR_rect
   port map (
      bitstream_i => bitstream,
      filtered_o => data_fir,
      reset_i => reset,
      clock_i => clock
   );
 
   IIR: IIR_LP1o
   port map (
      bitstream_i => bitstream,
      filtered_o => data_iir,
      reset_i => reset,
      clock_i => clock
   );
   
   process (clock)
       file data_out_file: text open write_MODE is FILE_PATH&"\filtered.csv";
       variable first_line: boolean:= true;
       variable sample_line: line;
       variable current_time: time;
       variable microsecond: real; 
       variable current_fir, current_iir: integer;
       begin
          if rising_edge(clock) then
             if first_line then
                write(sample_line, HEADER);
                writeline(data_out_file, sample_line);
                first_line:=false;
             end if;
             current_time:= NOW;
             microsecond:= real(current_time / 1 us);
             current_fir:= to_integer(unsigned(data_fir));
             current_iir:= to_integer(unsigned(data_iir));
             write(sample_line, microsecond);
             write(sample_line, ',');
             write(sample_line, current_fir);
             write(sample_line, ',');
             write(sample_line, current_iir);
             writeline(data_out_file, sample_line);
          end if; 
       end process;
end Behavioral;
