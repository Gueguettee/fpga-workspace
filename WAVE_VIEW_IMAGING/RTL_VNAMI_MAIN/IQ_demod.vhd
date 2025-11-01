LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity IQ_demod is
port
	(
		clk_i             : in std_logic;
		reset_i           : in std_logic;
		
		input_signal_i    : in std_logic_vector(ADC_data_length_c - 1 downto 0);
		start_i           : in std_logic;
		smplNbr_i         : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        sub_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        sup_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
		
		done_o            : out std_logic;

		I_o               : out std_logic_vector(26 downto 0);
		Q_o               : out std_logic_vector(26 downto 0);

        ADC_sub_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        ADC_sup_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);

        sine_0_o    : out std_logic_vector(ADC_data_length_c - 1 downto 0);
        sine_90_o   : out std_logic_vector(ADC_data_length_c - 1 downto 0)
		
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

    signal adc_input_s : std_logic_vector(13 downto 0);

-------------------------- COMPONENTS -------------------------

    component NCO_shift_0_90
    generic (
        BIT_WIDTH   : integer := 14;
        TABLE_SIZE  : integer := 3
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
    
begin
--------------------------- DESIGN ----------------------------

    sine_0_o <= input_signal_i;
    sine_90_o <= sine_90_s;

    -- To retrieve analog data instead of doing the IQ demodulation
    -- I_unfiltered_s(13 downto 0) <= input_signal_i when signed(input_signal_i) >= 0 else std_logic_vector(-signed(input_signal_i));
    -- I_unfiltered_s(26 downto 14) <= (others => '0');
    -- Q_unfiltered_s(13 downto 0) <= input_signal_i when signed(input_signal_i) >= 0 else std_logic_vector(-signed(input_signal_i));
    -- Q_unfiltered_s(26 downto 14) <= (others => '0');

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                adc_input_s <= (others => '0');
            else
                adc_input_s <= input_signal_i;
            end if;
        end if;
    end process;

    NCO : NCO_shift_0_90
    generic map(
        BIT_WIDTH       => 14,
        TABLE_SIZE      => 41
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
    
    I_average : average_IQ
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_i,
        smplNbr_i       => smplNbr_i,
        IQ_input_i      => I_unfiltered_s(26 downto 0),
        done_o          => I_done_s,
        result_o        => I_o
    );
    
    Q_average : average_IQ
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_i,
        smplNbr_i       => smplNbr_i,
        IQ_input_i      => Q_unfiltered_s(26 downto 0),
        done_o          => Q_done_s,
        result_o        => Q_o
    );

    done_o <= I_done_s and Q_done_s;

    average_adc_data_for_vga : average_ADC
    generic map(
        BIT_WIDTH       => 27
    )
    port map( 
        clk_i           => clk_i,
        reset_i         => reset_i,
        start_i         => start_i,
        smplNbr_i       => smplNbr_i,
        adc_input_i     => adc_input_s,
        sub_threshold_i => sub_threshold_i,
        sup_threshold_i => sup_threshold_i,
        done_o          => open,
        ADC_sub_threshold_indicator_o => ADC_sub_threshold_indicator_o,
        ADC_sup_threshold_indicator_o => ADC_sup_threshold_indicator_o
    );

end architecture mix;
