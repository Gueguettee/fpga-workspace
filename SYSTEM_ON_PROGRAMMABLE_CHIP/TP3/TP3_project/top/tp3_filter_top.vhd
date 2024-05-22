----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:45:48 02/12/2016 
-- Design Name: 
-- Module Name:    tp3_filter_top - Behavioral 
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

library work;
use work.myfilter_pkg.all;

entity tp3_filter_top is
	Port ( 
		clk_i   : in  std_logic;
		reset_i : in  std_logic;
		
		signal_o : out std_logic_vector(15 downto 0);
		signal_i : in std_logic_vector (15 downto 0);
		
		start_i : in std_logic;
		rdy_o : out std_logic
	);
end tp3_filter_top;

architecture Behavioral of tp3_filter_top is

	--Signal
  signal b_coeff_s : FILTER_COEFFICIENT_t;
  
begin

	cmp_myFIR : myFIR 
		Generic map(
			gFILTER_DATA_LENGTH => cFILTER_DATA_LENGTH,
			gFILTER_ORDER => cFILTER_ORDER
			)
		Port map( 
			clk_i   => clk_i,
			reset_i => reset_i,
			
			b_coeff_i => b_coeff_s,
			signal_i  => signal_i,
			start_i   => start_i,

			signal_o => signal_o,
			rdy_o => rdy_o
		);

end Behavioral;

