LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.SPI_synth_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;



entity SPI_synth_seq_mem is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        seq_id_i            : in unsigned(5 downto 0);
        freq_para_i         : in freq_para_t;
        
        spi_seq_o           : out spi_seq_t
	);
end entity SPI_synth_seq_mem;

architecture mix of SPI_synth_seq_mem is
    
--------------------------- SIGNALS ---------------------------
    
    type spi_seq_arr_t is array (31 downto 0) of spi_seq_t;
    signal spi_seq_arr_s    : spi_seq_arr_t;
    

  
-------------------------- COMPONENTS -------------------------


begin
--------------------------- DESIGN ----------------------------

    spi_seq_o <= spi_seq_arr_s(to_integer(seq_id_i));

--START_UP_SEQUENCE
    spi_seq_arr_s(0).nbr_of_cmds_s    <= to_unsigned(15,NBR_OF_CMD_LENGHT);
    spi_seq_arr_s(0).RW_s             <= (
        0       => '0',
        1       => '0',
        2       => '0',
        3       => '0',
        4       => '0',
        5       => '0',
        6       => '0',
        7       => '0',
        8       => '0',
        9       => '0',
        10      => '0',
        11      => '0',
        12      => '0',
        13      => '0',
        14      => '0',
        others  => '0');
    spi_seq_arr_s(0).addr_s           <= (
        0       => std_logic_vector(to_unsigned(0,7)),
        1       => std_logic_vector(to_unsigned(29,7)),
        2       => std_logic_vector(to_unsigned(30,7)),
        3       => std_logic_vector(to_unsigned(36,7)),
        4       => std_logic_vector(to_unsigned(37,7)),
        5       => std_logic_vector(to_unsigned(75,7)),
        6       => std_logic_vector(to_unsigned(38,7)),
        7       => std_logic_vector(to_unsigned(39,7)),
        8       => std_logic_vector(to_unsigned(43,7)),
        9       => std_logic_vector(to_unsigned(45,7)),
        10      => std_logic_vector(to_unsigned(52,7)),
        11      => std_logic_vector(to_unsigned(57,7)),
        12      => std_logic_vector(to_unsigned(71,7)),
        13      => std_logic_vector(to_unsigned(60,7)),
        14      => std_logic_vector(to_unsigned(0,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    spi_seq_arr_s(0).data_s             <= (
        0       => x"211E",
        1       => x"0000",
        2       => x"18A6",
        3       => freq_para_i.PLL_N_s,
        4       => freq_para_i.PFD_DLY_SEL_s,
        5       => freq_para_i.CHDIV_s,
        6       => freq_para_i.PLL_DEN_s(31 downto 16),
        7       => freq_para_i.PLL_DEN_s(15 downto 0),
        8       => freq_para_i.PLL_NUM_s(15 downto 0),
        9       => freq_para_i.OUTA_MUX_s,
        10      => x"0421",
        11      => x"0020",
        12      => x"0081",
        13      => x"0000",
        14      => x"211C",
        others  => x"0000");
        
--Setting frequency sequence
    spi_seq_arr_s(1).nbr_of_cmds_s    <= to_unsigned(7,6);
    spi_seq_arr_s(1).RW_s             <= (
        0       => '0',
        1       => '0',
        2       => '0',
        3       => '0',
        4       => '0',
        5       => '0',
        6       => '0',
        others  => '0');
    spi_seq_arr_s(1).addr_s           <= (
        0       => std_logic_vector(to_unsigned(36,7)),
        1       => std_logic_vector(to_unsigned(39,7)),
        2       => std_logic_vector(to_unsigned(43,7)),
        3       => std_logic_vector(to_unsigned(45,7)),
        4       => std_logic_vector(to_unsigned(37,7)),
        5       => std_logic_vector(to_unsigned(75,7)),
        6       => std_logic_vector(to_unsigned(0,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    spi_seq_arr_s(1).data_s             <= (
        0       => freq_para_i.PLL_N_s,
        1       => freq_para_i.PLL_DEN_s(15 downto 0),
        2       => freq_para_i.PLL_NUM_s(15 downto 0),
        3       => freq_para_i.OUTA_MUX_s,
        4       => freq_para_i.PFD_DLY_SEL_s,
        5       => freq_para_i.CHDIV_s,
        6       => x"211C",
        others  => x"0000");
        
        
--VCO No Assist Calibration with Calibration Read
--    spi_seq_arr_s(3).nbr_of_cmds_s    <= to_unsigned(4,6);
--    spi_seq_arr_s(3).RW_s             <= (
--        0       => '0',
--        1       => '1',
--        2       => '1',
--        3       => '1',
--        others  => '0');
--    spi_seq_arr_s(3).addr_s           <= (
--        0       => std_logic_vector(to_unsigned(0,7)),
--        1       => std_logic_vector(to_unsigned(20,7)),
--        2       => std_logic_vector(to_unsigned(19,7)),
--        3       => std_logic_vector(to_unsigned(16,7)),
--        others  => std_logic_vector(to_unsigned(0,7)));
--    spi_seq_arr_s(3).data_s             <= (
--        0       => x"2218",
--        1       => x"0000",
--        2       => x"0000",
--        3       => x"0000",
--        others  => x"0000");
end architecture mix;

