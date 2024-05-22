LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;



entity NCO_shift_0_90 is
generic (
    BIT_WIDTH   : integer := 14;
    TABLE_SIZE  : integer := 3;
    TABLE_WIDTH : integer := 3
    );
port (
    clk_i       : in std_logic;
    reset_i     : in std_logic;
    
    sine_0_o    : out std_logic_vector(BIT_WIDTH-1 downto 0);
    sine_90_o   : out std_logic_vector(BIT_WIDTH-1 downto 0)
	);
end entity NCO_shift_0_90;

architecture mix of NCO_shift_0_90 is
    
    
--------------------------- SIGNALS ---------------------------
	
	
	
-------------------------- COMPONENTS -------------------------

	component sine_wave_gen
    generic(
        BIT_WIDTH   : integer := 14;
        TABLE_SIZE  : integer := 3;
        TABLE_WIDTH : integer := 3;
        SHIFT_90    : boolean := false
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        sine_o      : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
    end component;	
	
	begin
    
--------------------------- DESIGN ----------------------------

    sine0_gen : sine_wave_gen
    generic map(
        BIT_WIDTH       => BIT_WIDTH,
        TABLE_SIZE      => TABLE_SIZE,
        TABLE_WIDTH     => TABLE_WIDTH,
        SHIFT_90        => false
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        sine_o          => sine_0_o
    );
            
    sine90_gen : sine_wave_gen
    generic map(
        BIT_WIDTH       => BIT_WIDTH,
        TABLE_SIZE      => TABLE_SIZE,
        TABLE_WIDTH     => TABLE_WIDTH,
        SHIFT_90        => true
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        sine_o          => sine_90_o
    );
    
    
    

end architecture mix;

