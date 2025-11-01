LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_VGA_ADL5206_driver IS
END tb_VGA_ADL5206_driver;

ARCHITECTURE behavior OF tb_VGA_ADL5206_driver IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT VGA_ADL5206_driver
        GENERIC(
            CLK_DIVIDER : integer := 100    --minimum 2, only even numbers allowed
        );
        PORT(
            clk_i       : in std_logic;
            reset_i     : in std_logic;
            start_i     : in std_logic;
            gain_i      : in std_logic_vector(4 downto 0);
            rdy_o       : out std_logic;
            SCLK_o      : out std_logic;
            CS_o        : out std_logic;
            SDI_o       : out std_logic;
            FA_o        : out std_logic
        );
    END COMPONENT;

    -- Signals for simulation
    signal clk_i      : std_logic := '0';
    signal reset_i    : std_logic := '1';
    signal start_i    : std_logic := '0';
    signal gain_i     : std_logic_vector(4 downto 0) := (others => '0');
    signal rdy_o      : std_logic;
    signal SCLK_o     : std_logic;
    signal CS_o       : std_logic;
    signal SDI_o      : std_logic;
    signal FA_o       : std_logic;

    -- Clock period definition
    constant clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: VGA_ADL5206_driver
        GENERIC MAP(
            CLK_DIVIDER => 100
        )
        PORT MAP (
            clk_i       => clk_i,
            reset_i     => reset_i,
            start_i     => start_i,
            gain_i      => gain_i,
            rdy_o       => rdy_o,
            SCLK_o      => SCLK_o,
            CS_o        => CS_o,
            SDI_o       => SDI_o,
            FA_o        => FA_o
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
        wait for 20 us;
        reset_i <= '0';

        wait for 20 us;
        start_i <= '1';
        gain_i <= "10101"; -- example gain value

        wait for 2000 ns;
        start_i <= '0';

        wait;
    end process;

END;
