----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:15:34 03/20/2016 
-- Design Name: 
-- Module Name:    myFIR - Behavioral 
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

library work;
use work.myfilter_pkg.all;

entity myFIR is
	Generic (
		gFILTER_DATA_LENGTH : integer := 16;
		gFILTER_ORDER : integer := 25
		);
	Port ( 
		clk_i   : in  std_logic;
		reset_i : in  std_logic;
		
		b_coeff_i : in FILTER_COEFFICIENT_t;
		signal_i : in std_logic_vector (gFILTER_DATA_LENGTH-1 downto 0);
		start_i : in std_logic;

		signal_o : out std_logic_vector(gFILTER_DATA_LENGTH-1 downto 0);
		rdy_o : out std_logic
	);
end myFIR;

architecture Behavioral of myFIR is

	--Signal
	signal filter_record_s : filter_record_t;

begin

	--Input of record for firsrt FIR stage
	filter_record_s.b_coeff <= b_coeff_i;

	--Signal registers
	filter_record_s.signal_in(0)<=signal_i;
	shift_register : for n in 1 to (gFILTER_ORDER-1) generate
		filter_record_s.signal_in(n)<=(others=>'0') when (reset_i='1') else
												filter_record_s.signal_in(n-1) when rising_edge(clk_i);
	end generate;

	--FIR stages	
	mult_gen : for n in 0 to (gFILTER_ORDER-1) generate
		cmp_mult : mult
		Generic map(
			gFILTER_DATA_LENGTH =>gFILTER_DATA_LENGTH
			)
		Port map( 
			clk_i   => clk_i,
			reset_i => reset_i,
			
			b_coeff_i => filter_record_s.b_coeff(n),
			signal_i  => filter_record_s.signal_in(n),
			start_i   => start_i,
			
			signal_o => filter_record_s.signal_out(n)
		);
	end generate;

	--Output
	add_proc : process(filter_record_s.signal_out)
     variable sum_v : signed(gFILTER_DATA_LENGTH-1 downto 0);
	begin
		sum_v := (others => '0');
		for n in 0 to gFILTER_ORDER-1 loop
			sum_v := sum_v + signed(filter_record_s.signal_out(n));                         
		end loop;
		signal_o <= std_logic_vector(sum_v);    
	end process;
  
	process (clk_i)
	begin
		if rising_edge(clk_i) then
			if (reset_i='1') then
				rdy_o <= '0';
			else
				rdy_o <= start_i;
			end if;
		end if;
	end process;

end Behavioral;

