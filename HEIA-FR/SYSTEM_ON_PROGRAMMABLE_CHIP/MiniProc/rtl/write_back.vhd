----------------------------------------------------------------------------------
-- Company: HEIA-FR 
-- Engineer: 
-- 
-- Create Date:    08:46:40 26/02/2024 
-- Design Name: 
-- Module Name:    write_back - Behavioral 
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

use work.miniproc_pkg.all;

entity write_back is
	port (
        data_mem_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
        data_from_alu_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
            
        inreg_i : in std_logic;
        
        data2reg_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
	);
end write_back;

architecture Behavioral of write_back is
    
begin

    selReg: for i in cDATA_SIZE-1 downto 0 generate
    begin
        selReg: mux port map(
            a_i => data_mem_i(i),
            b_i => data_from_alu_i(i),
            sel_i => inreg_i,
            z_o => data2reg_o(i)
        );
    end generate;
	
end Behavioral;

