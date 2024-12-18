----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2024 09:12:00 AM
-- Design Name: Testbench for key_lock_timed
-- Module Name: tb_toplevel
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Testbench for the "toplevel" module.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_toplevel IS
END tb_toplevel;

ARCHITECTURE behavior OF tb_toplevel IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT toplevel
    PORT(
        CLKxCI : IN  std_logic;
        RSTxRI : IN  std_logic;
        Push0xSI : IN  std_logic;
        Push1xSI : IN  std_logic;
        Push2xSI : IN  std_logic;
        Push3xSI : IN  std_logic;
        RLEDxSO : OUT std_logic;
        GLEDxSO : OUT std_logic
        );
    END COMPONENT;
   
   -- Signal declarations to connect to the UUT
   signal CLKxCI : std_logic := '0';
   signal RSTxRI : std_logic := '0';
   signal Push0xSI : std_logic := '0';
   signal Push1xSI : std_logic := '0';
   signal Push2xSI : std_logic := '0';
   signal Push3xSI : std_logic := '0';
   signal RLEDxSO : std_logic;
   signal GLEDxSO : std_logic;
   
   -- Clock period definition
   constant CLK_PERIOD : time := 10 ns;

BEGIN

   -- Instantiate the Unit Under Test (UUT)
   uut: toplevel PORT MAP (
          CLKxCI => CLKxCI,
          RSTxRI => RSTxRI,
          Push0xSI => Push0xSI,
          Push1xSI => Push1xSI,
          Push2xSI => Push2xSI,
          Push3xSI => Push3xSI,
          RLEDxSO => RLEDxSO,
          GLEDxSO => GLEDxSO
        );

   -- Clock process definitions
   CLK_PROCESS :process
   begin
		CLKxCI <= '0';
		wait for CLK_PERIOD/2;
		CLKxCI <= '1';
		wait for CLK_PERIOD/2;
   end process;

   -- Stimulus process to test the toplevel behavior
   stim_proc: process
   begin		

      -- Reset the system
      RSTxRI <= '1';
      wait for 20 ns;
      RSTxRI <= '0';
      wait for 20 ns;

      -- Test different key press combinations
      Push0xSI <= '1'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 00
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 00
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '1'; Push3xSI <= '0';  -- Key 01
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 00
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '1'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 10
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 00
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '1';  -- Key 11
      wait for 20 ns;
      Push0xSI <= '0'; Push1xSI <= '0'; Push2xSI <= '0'; Push3xSI <= '0';  -- Key 00
      wait for 20 ns;

      -- Add more test cases as required
      wait;
   end process;

END;
