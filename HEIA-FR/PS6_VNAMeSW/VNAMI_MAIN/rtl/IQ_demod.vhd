LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;



entity IQ_demod is
port
	(
		clk_i             : in std_logic;
		reset_i           : in std_logic;
		
		input_signal_i    : in std_logic_vector(13 downto 0);
		start_i           : in std_logic;
		smplNbr_i         : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
		
		done_o            : out std_logic;
		I_o               : out std_logic_vector(26 downto 0);
		Q_o               : out std_logic_vector(26 downto 0)
		
	);
end entity IQ_demod;

architecture mix of IQ_demod is
    
    
--------------------------- SIGNALS ---------------------------

	signal sine_0_s        : std_logic_vector(13 downto 0);
	signal sine_90_s       : std_logic_vector(13 downto 0); -- equal to cosine
	
	signal I_unfiltered_s  : std_logic_vector(26 downto 0);
	signal Q_unfiltered_s  : std_logic_vector(26 downto 0);
	
	signal I_done_s        : std_logic;
    signal Q_done_s        : std_logic;

-------------------------- COMPONENTS -------------------------

    component NCO_shift_0_90
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
    end component;
    
    component mixer
    generic (
        BIT_WIDTH   : integer := 14
    );
    port (
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        a_i         : in std_logic_vector(BIT_WIDTH-1 downto 0);
        b_i         : in std_logic_vector(BIT_WIDTH-1 downto 0);

        y_o         : out std_logic_vector(2*BIT_WIDTH-2 downto 0)
    );
    end component;
    
    component average
    generic(
        BIT_WIDTH   : integer := 27
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        
        smplNbr_i   : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- number of periods sampled (8 sample per period)
        start_i     : in std_logic;
        input_i     : in std_logic_vector(BIT_WIDTH-1 downto 0);
        
        done_o      : out std_logic;
        result_o    : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
    end component;
    
begin
	
--------------------------- DESIGN ----------------------------

    NCO : NCO_shift_0_90
    generic map(
        BIT_WIDTH       => 14,
        TABLE_SIZE      => 3,
        TABLE_WIDTH     => 3
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        sine_0_o        => sine_0_s,
        sine_90_o       => sine_90_s
    );
    
    I_mixer : mixer
    generic map(
        BIT_WIDTH       => 14
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        a_i             => sine_0_s,
        b_i             => input_signal_i,
        y_o             => I_unfiltered_s
    );
    
    Q_mixer : mixer
    generic map(
        BIT_WIDTH       => 14
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        a_i             => sine_90_s,
        b_i             => input_signal_i,
        y_o             => Q_unfiltered_s
    );
    
    I_average : average
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_i,
        smplNbr_i       => smplNbr_i,
        input_i         => I_unfiltered_s(26 downto 0),
        done_o          => I_done_s,
        result_o        => I_o
    );
    
    Q_average : average
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_i,
        smplNbr_i       => smplNbr_i,
        input_i         => Q_unfiltered_s(26 downto 0),
        done_o          => Q_done_s,
        result_o        => Q_o
    );
    
    done_o <= I_done_s and Q_done_s;

end architecture mix;
