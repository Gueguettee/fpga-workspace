LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY tb_SPI_switch_driver IS
END tb_SPI_switch_driver;

ARCHITECTURE behavior OF tb_SPI_switch_driver IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT SPI_switch_driver
    GENERIC(
        SPI_CLK_DIVIDER : integer := 10;
        PATH_DATA_LENGTH : integer := 8
    );
    PORT(
        clk_i           : IN  std_logic;
        reset_i         : IN  std_logic;
        start_seq_i     : IN  std_logic;
        latch_before_i  : IN  std_logic;
        latch_after_i   : IN  std_logic;
        path_data_i     : IN  std_logic_vector(PATH_DATA_LENGTH-1 downto 0);
        rdy_o           : OUT std_logic;
        path_data_o     : OUT std_logic_vector(PATH_DATA_LENGTH-1 downto 0);
        pico_o          : OUT std_logic;
        poci_i          : IN  std_logic;
        sck_o           : OUT std_logic;
        srclr_n_o       : OUT std_logic;
        rclr_n_o        : OUT std_logic;
        cs_o            : OUT std_logic
    );
    END COMPONENT;
   
   --Inputs
   signal clk_i : std_logic := '0';
   signal reset_i : std_logic := '0';
   signal start_seq_i : std_logic := '0';
   signal latch_before_i : std_logic := '1';
   signal latch_after_i : std_logic := '0';
   signal path_data_i : std_logic_vector(7 downto 0) := (others => '0');
   signal poci_i : std_logic := '0';

  --Outputs
   signal rdy_o : std_logic;
   signal path_data_o : std_logic_vector(7 downto 0);
   signal pico_o : std_logic;
   signal sck_o : std_logic;
   signal srclr_n_o : std_logic;
   signal rclr_n_o : std_logic;
   signal cs_o : std_logic;

   -- Clock period definition
   constant clk_period : time := 10 ns;

BEGIN

   -- Instantiate the Unit Under Test (UUT)
   uut: SPI_switch_driver
   GENERIC MAP(
        SPI_CLK_DIVIDER => 10,
        PATH_DATA_LENGTH => 8
    )
   PORT MAP (
        clk_i => clk_i,
        reset_i => reset_i,
        start_seq_i => start_seq_i,
        latch_before_i => latch_before_i,
        latch_after_i => latch_after_i,
        path_data_i => path_data_i,
        rdy_o => rdy_o,
        path_data_o => path_data_o,
        pico_o => pico_o,
        poci_i => poci_i,
        sck_o => sck_o,
        srclr_n_o => srclr_n_o,
        rclr_n_o => rclr_n_o,
        cs_o => cs_o
    );

   -- Clock process definitions
   clk_process :process
   begin
        clk_i <= '0';
        wait for clk_period/2;
        clk_i <= '1';
        wait for clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      reset_i <= '1';
      wait for 100 ns;	
      reset_i <= '0';
      
      wait for 100 ns;

      -- Add stimulus here
      path_data_i <= "10101010";
      start_seq_i <= '1';
      wait for clk_period*2;
      start_seq_i <= '0';
      
      wait for 500 ns;

      latch_before_i <= '1';
      wait for clk_period*2;
      latch_before_i <= '0';
      
      wait for 500 ns;

      latch_after_i <= '1';
      wait for clk_period*2;
      latch_after_i <= '0';

      wait for 1000 ns; -- wait for a while before ending simulation
      
      -- Stop the simulation
      wait;
   end process;

END;
