--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package myfilter_pkg is

	-- Declare constants
	constant cFILTER_DATA_LENGTH : integer := 16;
	constant cFILTER_ORDER : integer := 25;

	--Type
	type FILTER_COEFFICIENT_t is array (cFILTER_ORDER-1 downto 0) of std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
	type FILTER_SIGNAL_t is array (cFILTER_ORDER-1 downto 0) of std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
	type FILTER_SIGNAL_OUT_t is array (cFILTER_ORDER-1 downto 0) of std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
	
	type filter_record_t is
	record
		b_coeff    : FILTER_COEFFICIENT_t;
		signal_in  : FILTER_SIGNAL_t;
		signal_out : FILTER_SIGNAL_OUT_t;
	end record;
  
	--Component
	component mult 
		Generic (
			gFILTER_DATA_LENGTH : integer := 16
			);
		Port ( 
			clk_i   : in  std_logic;
			reset_i : in  std_logic;
			
			b_coeff_i : in std_logic_vector (gFILTER_DATA_LENGTH-1 downto 0);
			signal_i : in std_logic_vector (gFILTER_DATA_LENGTH-1 downto 0);
			start_i : in std_logic;

			signal_o : out std_logic_vector(gFILTER_DATA_LENGTH-1 downto 0)
		);
	end component;

	component myFIR 
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
	end component;

end myfilter_pkg;

package body myfilter_pkg is

	--function
 
end myfilter_pkg;
