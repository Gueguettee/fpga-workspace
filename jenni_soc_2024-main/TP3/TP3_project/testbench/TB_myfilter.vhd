--------------------------------------------------------------------------------
-- Company: HEIA-FR
-- Engineer: Daniel Oberson
--
-- Create Date:   13:20:07 03/20/2016
-- Design Name:   
-- Module Name:   C:/Work/HEIA-FR/SOC/TP/tp3/testbench/TB_myfilter.vhd
-- Project Name:  tp3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: myFIR
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use std.textio.all;

LIBRARY work;
USE work.myfilter_pkg.ALL;

ENTITY TB_myfilter IS
END TB_myfilter;
 
ARCHITECTURE behavior OF TB_myfilter IS 

	-- Component Declaration for the Unit Under Test (UUT)
 
	component myFIR
		Generic (
			gFILTER_DATA_LENGTH : integer := 16;
			gFILTER_ORDER : integer := 25
		);
		Port(
			clk_i   : IN  std_logic;
			reset_i : IN  std_logic;
			
			b_coeff_i : IN  FILTER_COEFFICIENT_t;
			signal_i  : IN  std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
			start_i   : IN  std_logic;
			
			signal_o : OUT  std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
			rdy_o    : OUT  std_logic
		);
	end component;
    
   --Inputs
   signal clk_i : std_logic;
   signal reset_i : std_logic;
   signal b_coeff_i : FILTER_COEFFICIENT_t;
   signal signal_i : std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
   signal start_i : std_logic;

 	--Outputs
   signal signal_o : std_logic_vector(cFILTER_DATA_LENGTH-1 downto 0);
   signal rdy_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;

   constant file_repertory : string := "../../../../../Matlab/";
 
BEGIN
 
	-- Instantiate myFIR (UUT)

	uut: myFIR
	generic map (
		gFILTER_DATA_LENGTH => cFILTER_DATA_LENGTH,
		gFILTER_ORDER => cFILTER_ORDER
	)
	port map (
		clk_i   => clk_i,
		reset_i => reset_i,

		b_coeff_i => b_coeff_i,
		signal_i  => signal_i,
		start_i   => start_i,

		signal_o => signal_o,
		rdy_o    => rdy_o
	);

	-- Clock process definitions

	clk_process :process
	begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
	end process;

	-- Stimulus process
	stim_proc: process
		file coeff_file : text open read_mode is file_repertory & "coeff.dat";
		file stimuli_file : text open read_mode is file_repertory & "stimuli.dat";
	--Variables to read coeff values in file 'coeff.dat'
		variable coeff_line : line;
		variable coeff_val_v : integer;
	--Variables to read input signal values in file 'stimuli.dat'
		variable stimuli_line : line;
		variable stimuli_val_v : integer;
	begin		
		-- Start
			report ">>>>>> Init and start simulation";
			--Initialization of myFIR's inputs, especially b coefficients
			reset_i <= '0';
			readline(coeff_file, coeff_line);
			read(coeff_line, coeff_val_v);
			for n in 0 to coeff_val_v-1 loop
				readline(coeff_file, coeff_line);
				read(coeff_line, coeff_val_v);
				b_coeff_i(n) <= std_logic_vector(to_signed(coeff_val_v, cFILTER_DATA_LENGTH));
			end loop;
			signal_i <= (others=>'0');
			start_i <= '0';
		wait for 50 ns;	
		-- Power on reset
			report ">>>>>>    Reset";
			reset_i <= '1';
			wait for 100 ns;
			reset_i <= '0';
			-- insert stimulus here:
			--  read the first line of the stimuli.dat file to have the number of input signal samples
			--  loop  to read, line by line, each sample, put it on input signal and set the start command
			--     ('for loop' and 'wait until' to synchronize the loop on the clk 
			readline(stimuli_file, stimuli_line);
			read(stimuli_line, stimuli_val_v);
			wait until clk_i = '1';
			for n in 0 to stimuli_val_v-1 loop
				readline(stimuli_file, stimuli_line);
				read(stimuli_line, stimuli_val_v);
				signal_i <= std_logic_vector(to_signed(stimuli_val_v, cFILTER_DATA_LENGTH));
				start_i <= '1';
				wait until clk_i = '1';
			end loop;
		--  reset the start command
		start_i <= '0';
		wait;
	end process;
	
   	result_proc: process (clk_i)
	   file result_file : text open write_mode is file_repertory & "ref2.dat";
	--Variables to write result values in file 'result.dat'
		variable result_line : line;
		variable result_val_v : integer;
	begin
		-- process to read the output signal of the filter and write them in 'result.dat'
		if rising_edge(clk_i) then
			if reset_i = '1' then
				null;
			else
				if rdy_o = '1' then
					-- write the result on the file
					result_val_v := to_integer(signed(signal_o));
					write(result_line, result_val_v);
					writeline(result_file, result_line);
				end if;
			end if;
		end if;
	end process;

END;
