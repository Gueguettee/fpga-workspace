LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;



entity PLL is
port(
    clk_i       : in std_logic;
    reset_i     : in std_logic;
    
    reset_o     : out std_logic;
    clk_100M_o  : out std_logic;
    clk_80M_o   : out std_logic;
    clk_40M_o   : out std_logic;
    clk_10M_o   : out std_logic
	);
end entity PLL;

architecture mix of PLL is
    
--------------------------- SIGNALS ---------------------------
	signal clk_fb_s        : std_logic;
	signal pll_locked_s    : std_logic;
-------------------------- COMPONENTS -------------------------
	
begin
--------------------------- DESIGN ----------------------------
    
    -- PLLE2_BASE: Base Phase Locked Loop (PLL)
    -- 7 Series
    -- Xilinx HDL Libraries Guide, version 14.7
    PLLE2_BASE_inst : PLLE2_BASE
    generic map (
        BANDWIDTH =>        "OPTIMIZED",    -- OPTIMIZED, HIGH, LOW
        CLKFBOUT_MULT       => 8,           -- Multiply value for all CLKOUT, (2-64)
        CLKFBOUT_PHASE      => 0.0,         -- Phase offset in degrees of CLKFB, (-360.000-360.000).
        CLKIN1_PERIOD       => 10.000,         -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
        CLKOUT0_DIVIDE      => 8,
        CLKOUT1_DIVIDE      => 10,
        CLKOUT2_DIVIDE      => 20,
        CLKOUT3_DIVIDE      => 80,
        CLKOUT4_DIVIDE      => 1,
        CLKOUT5_DIVIDE      => 1,
        -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
        CLKOUT0_DUTY_CYCLE  => 0.5,
        CLKOUT1_DUTY_CYCLE  => 0.5,
        CLKOUT2_DUTY_CYCLE  => 0.5,
        CLKOUT3_DUTY_CYCLE  => 0.5,
        CLKOUT4_DUTY_CYCLE  => 0.5,
        CLKOUT5_DUTY_CYCLE  => 0.5,
        -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        CLKOUT0_PHASE       => 0.0,
        CLKOUT1_PHASE       => 0.0,
        CLKOUT2_PHASE       => 0.0,
        CLKOUT3_PHASE       => 0.0,
        CLKOUT4_PHASE       => 0.0,
        CLKOUT5_PHASE       => 0.0,
        DIVCLK_DIVIDE       => 1,       -- Master division value, (1-56)
        REF_JITTER1         => 0.0,     -- Reference input jitter in UI, (0.000-0.999).
        STARTUP_WAIT        => "FALSE"  -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
    )
    port map (
        -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
        CLKOUT0             => clk_100M_o,    -- 1-bit output: CLKOUT0
        CLKOUT1             => clk_80M_o,     -- 1-bit output: CLKOUT1
        CLKOUT2             => clk_40M_o,     -- 1-bit output: CLKOUT2
        CLKOUT3             => clk_10M_o,     -- 1-bit output: CLKOUT3
        CLKOUT4             => open,     -- 1-bit output: CLKOUT4
        CLKOUT5             => open,     -- 1-bit output: CLKOUT5
        -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
        CLKFBOUT            => clk_fb_s,    -- 1-bit output: Feedback clock
        LOCKED              => pll_locked_s,        -- 1-bit output: LOCK
        CLKIN1              => clk_i,       -- 1-bit input: Input clock
        -- Control Ports: 1-bit (each) input: PLL control ports
        PWRDWN              => '0',         -- 1-bit input: Power-down
        RST                 => reset_i,     -- 1-bit input: Reset
        -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
        CLKFBIN             => clk_fb_s     -- 1-bit input: Feedback clock
    );
    -- End of PLLE2_BASE_inst instantiation

    reset_o <= reset_i or not (pll_locked_s);


end architecture mix;

