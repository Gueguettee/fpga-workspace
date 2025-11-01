--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.main_control_pkg.all;

package SPI_synth_pkg is

    constant ADDR_LENGTH    : integer := 7;
    constant DATA_LENGTH    : integer := 16;
    constant TOTAL_LENGTH   : integer := ADDR_LENGTH + DATA_LENGTH + 1;

    constant RW_READ         : std_logic := '1';
    constant RW_WRITE        : std_logic := '0';

    subtype seq_id_t is integer range 0 to 6;
    constant SEQ_ID_INIT : seq_id_t := 0;
    constant SEQ_ID_SET_FREQ : seq_id_t := 1;
    constant SEQ_ID_READ_VCO : seq_id_t := 4;
    constant SEQ_ID_SET_FREQ_VCO : seq_id_t := 5;
    constant SEQ_ID_IDLE : seq_id_t := 6;

    constant N_MAX_CMDS : integer := 128; 
    constant NBR_OF_CMD_LENGHT : integer := 7; --log2(N_MAX_CMDS)
    
    type RW_array_t     is array (N_MAX_CMDS-1 downto 0) of std_logic;
    type addr_array_t   is array (N_MAX_CMDS-1 downto 0) of std_logic_vector(ADDR_LENGTH-1 downto 0);
    type data_array_t   is array (N_MAX_CMDS-1 downto 0) of std_logic_vector(DATA_LENGTH-1 downto 0);
    
    type spi_seq_o_t is record
        nbr_of_cmds_s       : unsigned(NBR_OF_CMD_LENGHT-1 downto 0);
        RW_s                : RW_array_t;
        addr_s              : addr_array_t;
        data_o_s            : data_array_t;
    end record spi_seq_o_t;

    type spi_seq_i_t is record
        data_i_s            : data_array_t;
    end record spi_seq_i_t;
    
    type freq_para_t is record
        CHDIV_s             : std_logic_vector(15 downto 0);
        PLL_N_s             : std_logic_vector(15 downto 0);
        PLL_NUM_s           : std_logic_vector(15 downto 0);
        PLL_DEN_s           : std_logic_vector(15 downto 0);
        OUTA_MUX_s          : std_logic_vector(15 downto 0);
        OUTB_MUX_s          : std_logic_vector(15 downto 0);
        PFD_DLY_SEL_s       : std_logic_vector(15 downto 0);
    end record freq_para_t;

    constant fmin       : integer := 100;   --MHz
    constant fmax       : integer := 8000;  --MHz
    constant fstep      : integer := 50;    --MHz
    constant fmultiFpga : integer := 10;
    
    constant fmin_div : integer := fmin / fmultiFpga;
    constant fmax_div : integer := fmax / fmultiFpga;
    constant fstep_div : integer := fstep / fmultiFpga;

    constant n_freq : integer := (fmax_div - fmin_div) / fstep_div + 1;
    
    subtype freq_t is integer range fmin_div to fmax_div;

    subtype offset_t is integer range 0 to 2**offset_data_length_c - 1; -- 0 to 15, 4 bits
    constant OFFSET_0_MHz : offset_t := 0;
    constant OFFSET_10_MHz : offset_t := 1;

    constant vco_sel_data_length : integer := 3;
    constant vco_capctrl_data_length : integer := 8;
    constant vco_daciset_data_length : integer := 9;

    type vco_t is record
        sel           : std_logic_vector(vco_sel_data_length-1 downto 0);
        capctrl       : std_logic_vector(vco_capctrl_data_length-1 downto 0);
        daciset       : std_logic_vector(vco_daciset_data_length-1 downto 0);
    end record vco_t;

    constant synth_spi_clk_divider : integer := 80; --tested with success with 4 with the analog board

    constant watch_dog_timeout_init : integer := 100000 * clk_freq_mhz;  --100 ms
    constant watch_dog_timeout_set_freq : integer := 10000 * clk_freq_mhz; --10 ms
    constant watch_dog_timeout_set_freq_vco : integer := 5000 * clk_freq_mhz; --5000 us
    constant glitch_management_delay_c : integer := 3 * clk_freq_mhz; --3 us
    constant glitch_management_n_loop_c : integer := 3; --ceil(glitch_management_delay_c / synth_spi_clk_divider / 32) + 1 ("+1" because we are not testing in continue) --3
    constant watch_dog_timeout_loop : integer := 6250; --ceil(watch_dog_timeout_set_freq / synth_spi_clk_divider / 32)  --6250

-------------------------- COMPONENTS -------------------------

    component SPI_synth_driver is
    generic(
        ADDR_LENGTH         : integer := 7;
        DATA_LENGTH         : integer := 16;
        BLOCK_PROGRAMMING   : boolean_t := YES
    );
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        spi_clk_divider_i   : in integer range 0 to max_spi_clock_divider_c;
        
        RW_i                : in std_logic; --0 is write, 1 is read
        addr_i              : in std_logic_vector(ADDR_LENGTH-1 downto 0);
        data_i              : in std_logic_vector(DATA_LENGTH-1 downto 0);
        data_o              : out std_logic_vector(DATA_LENGTH-1 downto 0);
        
        MUXout_i            : in std_logic;
        SCK_o               : out std_logic;
        SDI_o               : out std_logic;
        CSB_o               : out std_logic;
        CE_o                : out std_logic;
        
        rdy_o               : out std_logic;
        rdy_next_data_o     : out std_logic
    );
    end component SPI_synth_driver;

    component SPI_synth_freq_mem is
        generic(
            RF_LO               : RF_LO_t := RF;
            SYNTHESIZER         : synthesizer_t := LMX2572
        );
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;
            
            freq_i              : in freq_t;
            offset_i            : in offset_t;
            
            freq_para_o         : out freq_para_t
        );
    end component SPI_synth_freq_mem;
    
    component SPI_synth_seq_mem is
        generic(
            RF_LO               : RF_LO_t := RF;
            SYNTHESIZER         : synthesizer_t := LMX2572
        );
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;
            
            seq_id_i            : in seq_id_t;
            freq_para_i         : in freq_para_t;
            power_i             : in power_t;
            
            spi_seq_i           : in spi_seq_i_t;
            spi_seq_o           : out spi_seq_o_t;

            vco_i               : in vco_t;
            vco_o               : out vco_t
        );
    end component SPI_synth_seq_mem;

    component SPI_synth_vco_mem is
        port(
            clk_i               : in std_logic;
            reset_i             : in std_logic;
            
            freq_i              : in std_logic_vector(freq_data_length_c-1 downto 0);
            rw_i                : in std_logic;

            vco_i               : in vco_t;

            vco_o               : out vco_t
        );
    end component SPI_synth_vco_mem;

end SPI_synth_pkg;


package body SPI_synth_pkg is
 
end SPI_synth_pkg;
