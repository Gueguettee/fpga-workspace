LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

use work.TL_VNAMI_MAIN_pkg.all;
use work.main_control_pkg.all;


ENTITY tb_att_power_controller IS
END tb_att_power_controller;

ARCHITECTURE behavior OF tb_att_power_controller IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT att_power_controller
        GENERIC(
            CLK_DIVIDER : integer := 10
        );
        PORT(
            clk_i               : in std_logic;
            reset_i             : in std_logic;
            start_i             : in std_logic;
            power_i             : in std_logic_vector(att_power_data_length_c-1 downto 0);
            rdy_o               : out std_logic;
            PAR_SER1_o          : out std_logic;
            SERIAL1_o           : out std_logic;
            CLK1_o              : out std_logic;
            LATCH_ENABLE1_o     : out std_logic;
            CTRL2_o             : out std_logic
        );
    END COMPONENT;

    -- Constants and signals for simulation
    constant clk_period : time := 10 ns;
    signal clk_i       : std_logic := '0';
    signal reset_i     : std_logic := '1';
    signal start_i     : std_logic := '0';
    signal power_i     : std_logic_vector(att_power_data_length_c-1 downto 0) := (others => '0');
    signal rdy_o       : std_logic;
    signal PAR_SER1_o  : std_logic;
    signal SERIAL1_o   : std_logic;
    signal CLK1_o      : std_logic;
    signal LATCH_ENABLE1_o : std_logic;
    signal CTRL2_o     : std_logic;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: att_power_controller
        GENERIC MAP(
            CLK_DIVIDER => 10
        )
        PORT MAP (
            clk_i           => clk_i,
            reset_i         => reset_i,
            start_i         => start_i,
            power_i         => power_i,
            rdy_o           => rdy_o,
            PAR_SER1_o      => PAR_SER1_o,
            SERIAL1_o       => SERIAL1_o,
            CLK1_o          => CLK1_o,
            LATCH_ENABLE1_o => LATCH_ENABLE1_o,
            CTRL2_o         => CTRL2_o
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
        -- hold reset state for 20 ns.
        wait for 20 ns;
        reset_i <= '0';

        wait for 20 ns;
        start_i <= '1';
        power_i <= "01010101"; -- example power value

        wait for 200 ns;
        start_i <= '0';

        -- Add more stimulus here if needed

        wait;
    end process;

END;
