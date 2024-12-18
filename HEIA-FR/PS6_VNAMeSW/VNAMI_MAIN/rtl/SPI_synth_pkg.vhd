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

package SPI_synth_pkg is

    constant ADDR_LENGTH    : integer := 7;
    constant DATA_LENGTH    : integer := 16;
    constant TOTAL_LENGTH   : integer := ADDR_LENGTH + DATA_LENGTH + 1;
    constant NBR_OF_CMD_LENGHT : integer := 6;

    constant RW_READ         : std_logic := '1';
    constant RW_WRITE        : std_logic := '0';
    
    type RW_array_t     is array (32 downto 0) of std_logic;
    type addr_array_t   is array (32 downto 0) of std_logic_vector(ADDR_LENGTH-1 downto 0);
    type data_array_t   is array (32 downto 0) of std_logic_vector(DATA_LENGTH-1 downto 0);
    
    type spi_seq_t is record
        nbr_of_cmds_s       : unsigned(5 downto 0);
        RW_s                : RW_array_t;
        addr_s              : addr_array_t;
        data_s              : data_array_t;
    end record spi_seq_t;
    
    type freq_para_t is record
        CHDIV_s             : std_logic_vector(15 downto 0);
        PLL_N_s             : std_logic_vector(15 downto 0);
        PLL_NUM_s           : std_logic_vector(31 downto 0);
        PLL_DEN_s           : std_logic_vector(31 downto 0);
        OUTA_MUX_s          : std_logic_vector(15 downto 0);
        PFD_DLY_SEL_s       : std_logic_vector(15 downto 0);
    end record freq_para_t;
    
    type freq_t is
    (
        f200,   f400,   f600,   f800,   f1000,
        f1200,  f1400,  f1600,  f1800,  f2000,
        f2200,  f2400,  f2600,  f2800,  f3000,
        f3200,  f3400,  f3600,  f3800,  f4000,
        f4200,  f4400,  f4600,  f4800,  f5000,
        f5200,  f5400,  f5600,  f5800,  f6000,
        f6200,  f6400
       );

-------------------------- COMPONENTS -------------------------

    component SPI_synth_LMX2572 is
    generic(
        SPI_CLK_DIVIDER     : integer := 100;
        ADDR_LENGTH         : integer := 7;
        DATA_LENGTH         : integer := 16);
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        
        RW_i                : in std_logic; --0 is write, 1 is read
        addr_i              : in std_logic_vector(ADDR_LENGTH-1 downto 0);
        data_i              : in std_logic_vector(DATA_LENGTH-1 downto 0);
        data_o              : out std_logic_vector(DATA_LENGTH-1 downto 0);
        
        MUXout_i            : in std_logic;
        SCK_o               : out std_logic;
        SDI_o               : out std_logic;
        CSB_o               : out std_logic;
        CE_o                : out std_logic;
        
        rdy_o               : out std_logic
    );
    end component SPI_synth_LMX2572;
    
    component SPI_synth_seq is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        freq_i              : in std_logic_vector(5 downto 0);
        seq_id_i            : in unsigned(5 downto 0);
        RF_spi_seq_o        : out spi_seq_t;
        LO_spi_seq_o        : out spi_seq_t
    );
    end component SPI_synth_seq;

end SPI_synth_pkg;

package body SPI_synth_pkg is

 
end SPI_synth_pkg;
