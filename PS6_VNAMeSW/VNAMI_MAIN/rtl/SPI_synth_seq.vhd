LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.SPI_synth_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;



entity SPI_synth_seq is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        seq_id_i            : in unsigned(5 downto 0);
        freq_i              : in std_logic_vector(5 downto 0);
        RF_spi_seq_o        : out spi_seq_t;
        LO_spi_seq_o        : out spi_seq_t
        
      --INPUT PARAMETER
        --F_OUT
      --parameters DEPENDING ON F_OUT  
        --CHDIV
        --PLL_N
        --PLL_NUM
        --PLL_DEN
        --OUTA_MUX
        --PFD_DLY_SEL
	);
end entity SPI_synth_seq;

architecture mix of SPI_synth_seq is
    
--------------------------- SIGNALS ---------------------------
    
    
    signal RF_freq_para_s   : freq_para_t;
    signal LO_freq_para_s   : freq_para_t;
    
    signal freq_s           : freq_t;
    

-------------------------- COMPONENTS -------------------------
    component SPI_synth_freq_mem is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        freq_i              : in freq_t;
        
        RF_freq_para_o      : out freq_para_t;
        LO_freq_para_o      : out freq_para_t
    );
    end component SPI_synth_freq_mem;
    
    component SPI_synth_seq_mem is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        seq_id_i            : in unsigned(5 downto 0);
        freq_para_i         : in freq_para_t;
        
        spi_seq_o           : out spi_seq_t
    );
    end component SPI_synth_seq_mem;

begin
--------------------------- DESIGN ----------------------------

    freq_decode : freq_decoder
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_i,
        freq_o          => freq_s
    );
    
    freq_mem : SPI_synth_freq_mem
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_s,
        RF_freq_para_o  => RF_freq_para_s,
        LO_freq_para_o  => LO_freq_para_s
    );
    
    RX_seq_mem : SPI_synth_seq_mem
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        seq_id_i        => seq_id_i,
        freq_para_i     => RF_freq_para_s,
        spi_seq_o       => RF_spi_seq_o
    );
    
    TX_seq_mem : SPI_synth_seq_mem
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        seq_id_i        => seq_id_i,
        freq_para_i     => LO_freq_para_s,
        spi_seq_o       => LO_spi_seq_o
    );
    
end architecture mix;

