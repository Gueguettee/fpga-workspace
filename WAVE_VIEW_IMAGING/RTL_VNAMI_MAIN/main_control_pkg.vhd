library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

package main_control_pkg is

-------------------------- CONSTANTS ------------------------- 

	constant freq_addr_length_c    	        : integer := 6;
    constant ifbw_addr_length_c    	        : integer := freq_addr_length_c;
    constant path_addr_length_c    	        : integer := 13;
    constant att_power_addr_length_c        : integer := freq_addr_length_c;
    constant power_addr_length_c            : integer := freq_addr_length_c;
    constant calFact_power_freqPath_addr_length_c    : integer := freq_addr_length_c + path_addr_length_c;
    constant vga_gain_addr_length_c         : integer := freq_addr_length_c;

    constant freq_data_length_c 	        : integer := 8;
    constant ifbw_data_length_c 	        : integer := 5;
    constant path_data_length_c		        : integer := 16;
    constant att_power_data_length_c        : integer := 8;
    constant synth_power_data_length_c      : integer := 6;
    constant calFact_power_cable_data_length_c : integer := 6;
    constant calFact_power_freqPath_data_length_c    : integer := 6;
    constant vga_gain_data_length_c         : integer := 5;
    constant ADC_data_length_c              : integer := 14;
    constant VGA_data_length_c              : integer := 14; -- to be able to count until 100
    constant PL_status_data_length_c        : integer := 3;
    constant mode_data_length_c             : integer := 4;
    constant PE43705_power_data_length_c    : integer := 7;
    constant filter_bank_controller_length_c : integer := 4;
    constant filter_bank_controller_output_length_c : integer := 3;
    constant synth_stability_data_length_c : integer := 8;
    constant ADC_data_range_indicator_data_length_c : integer := 27; -- 2^26 samples, +1 bit of sign
    constant LED_INDICATORS_DATA_LENGTH_c : integer := 8;
    constant SPI_CLOCK_SPEED_DATA_LENGTH_c : integer := 8;
    constant offset_data_length_c          : integer := 4;
    constant vga_power_adjust_enable_data_length_c : integer := 2;

    constant max_smpl_nmbr_c        : integer := 26; --(23 ifbw values + 3 + 1: 2^3 * 2^23 (+1 for calcul)) 

    constant clk_freq_mhz           : integer := 80;--MHz

    constant ATTENUATION_MULTIPLE   : integer := 4; --because 0.25 of precision

    constant SW_EXCEPTION_BIT : integer := 0;
    constant SYNTH_EXCEPTION_BIT : integer := 1;
    constant SYNTH_EXCEPTION_WHILE_MEASUREMENT_BIT : integer := 2;

    constant N_MODE : integer := 16;

    constant CW_BUFFER_SIZE : integer := 1024;
    constant CW_N_ADC_CHAINED_BUFFERS : integer := 16;
    constant CW_BUFFER_SIZE_CHAINED : integer := CW_BUFFER_SIZE * CW_N_ADC_CHAINED_BUFFERS;

    constant max_spi_clock_divider_c : integer := 160;

    constant vga_adjust_ifbw_c : std_logic_vector(ifbw_data_length_c-1 downto 0) := "00001";

    constant VGA_ADJUST_ENABLE : integer := 0;
    constant POWER_ADJUST_ENABLE : integer := 1;

-------------------------- TYPES ------------------------- 

    type synthesizer_t is
    (
        LMX2572,
        LMX2594
    );

    type RF_LO_t is
    (
        RF,
        LO
    );

    type boolean_t is 
    (
        YES,
        NO
    );

    subtype power_t is std_logic_vector(synth_power_data_length_c-1 downto 0);
    subtype att_power_t is std_logic_vector(att_power_data_length_c-1 downto 0);
    
    type mode_t is 
    (
        S21,    -- 0000
        NA1,    -- 0001
        S11,    -- 0010
        LOAD,   -- 0011
        NA2,    -- 0100
        NA3,    -- 0101
        NA4,    -- 0110
        S22,    -- 0111
        NA5,    -- 1000
        NA6,    -- 1001
        NA7,    -- 1010
        SHORT,  -- 1011
        NA8,    -- 1100
        NA9,    -- 1101
        NA10,   -- 1110
        OPENED  -- 1111
    );
    type mode_array_t is array (N_MODE-1 downto 0) of mode_t;

    type ADC_Buffer_Array_t is array (0 to CW_N_ADC_CHAINED_BUFFERS) of std_logic_vector(ADC_data_length_c-1 downto 0);

-------------------------- LOOK-UP TABLE ------------------------- 

    constant MODE_LUT : mode_array_t := (
        S21,    -- 0000
        NA1,    -- 0001
        S11,    -- 0010
        LOAD,   -- 0011
        NA2,    -- 0100
        NA3,    -- 0101
        NA4,    -- 0110
        S22,    -- 0111
        NA5,    -- 1000
        NA6,    -- 1001
        NA7,    -- 1010
        SHORT,  -- 1011
        NA8,    -- 1100
        NA9,    -- 1101
        NA10,   -- 1110
        OPENED  -- 1111
    );

-------------------------- COMPONENTS ------------------------- 

end main_control_pkg;
