----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:36:11 02/25/2016 
-- Design Name: 
-- Module Name:    statemachine - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

entity statemachine is
	port ( 
		clk_i   : in std_logic;
		reset_i : in std_logic;
		
		start_i : in std_logic;
		
		rdy_o      : out std_logic;
		load_in_o  : out std_logic;
		load_out_o : out std_logic
	);
end statemachine;

architecture Behavioral of statemachine is

	--Type
	type states_t is 
	(	
		IDLE,
		READ_IN,
		WRITE_OUT
	);
	
	--Signal
	signal state_s : states_t;

begin

	--State machine - next state
	process (clk_i) 
	begin
		if rising_edge(clk_i) then 
			if (reset_i='1') then
				state_s  <= IDLE;
			else
				case state_s is
					when IDLE =>
						if (start_i='1') then
							state_s  <= READ_IN;
						end if;
						
					when READ_IN =>
						state_s  <= WRITE_OUT;
						
					when WRITE_OUT =>
						state_s <= IDLE;
						
				end case;
			end if;
		end if;
	end process;

	--Output of state machine
	process (state_s)
	begin
		--Default value
		rdy_o <= '0';
		load_in_o <= '0';
		load_out_o <= '0';
		
		case state_s is
			when IDLE =>
				rdy_o <= '1';
				
			when READ_IN =>
				load_in_o <= '1';

			when WRITE_OUT =>
				load_out_o <= '1';
				
		end case;
	end process;
	
end Behavioral;

