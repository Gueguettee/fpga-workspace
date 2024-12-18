LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.SPI_synth_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;



entity SPI_synth_freq_mem is
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        freq_i              : in freq_t;
        
        RF_freq_para_o      : out freq_para_t;
        LO_freq_para_o      : out freq_para_t
	);
end entity SPI_synth_freq_mem;

architecture mix of SPI_synth_freq_mem is
    
--------------------------- SIGNALS ---------------------------
    
    type spi_seq_arr_t is array (63 downto 0) of spi_seq_t;
    signal spi_seq_arr_s    : spi_seq_arr_t;
    
-------------------------- COMPONENTS -------------------------


begin
--------------------------- DESIGN ----------------------------
    
    process(reset_i, freq_i)
    begin
        if reset_i = '1' then
            --default values
            RF_freq_para_o.CHDIV_s          <= x"0800";
            RF_freq_para_o.PLL_N_s          <= x"0000";
            RF_freq_para_o.PLL_NUM_s        <= x"00000000";
            RF_freq_para_o.PLL_DEN_s        <= x"00000000";
            RF_freq_para_o.OUTA_MUX_s       <= x"C600";
            RF_freq_para_o.PFD_DLY_SEL_s    <= x"0005";
            
            LO_freq_para_o.CHDIV_s          <= x"0800";
            LO_freq_para_o.PLL_N_s          <= x"0000";
            LO_freq_para_o.PLL_NUM_s        <= x"00000000";
            LO_freq_para_o.PLL_DEN_s        <= x"00000000";
            LO_freq_para_o.OUTA_MUX_s       <= x"C600";
            LO_freq_para_o.PFD_DLY_SEL_s    <= x"0005";
        else
            --default values
            RF_freq_para_o.CHDIV_s          <= x"0800";
            RF_freq_para_o.PLL_N_s          <= x"0000";
            RF_freq_para_o.PLL_NUM_s        <= x"00000000";
            RF_freq_para_o.PLL_DEN_s        <= x"00000000";
            RF_freq_para_o.OUTA_MUX_s       <= x"C600";
            RF_freq_para_o.PFD_DLY_SEL_s    <= x"0005";
            
            LO_freq_para_o.CHDIV_s          <= x"0800";
            LO_freq_para_o.PLL_N_s          <= x"0000";
            LO_freq_para_o.PLL_NUM_s        <= x"00000000";
            LO_freq_para_o.PLL_DEN_s        <= x"00000000";
            LO_freq_para_o.OUTA_MUX_s       <= x"C600";
            LO_freq_para_o.PFD_DLY_SEL_s    <= x"0005";
            
            case freq_i is
                when f200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(7   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(7   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                when f400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(5   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(5   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(400 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                when f600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(3   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(3   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                when f800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(3   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(3   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    
                when f1000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                        
                when f1200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                        
                when f1400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));            
                    
                when f1600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));  
                    
                when f1800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(36  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(35  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));  
                    
                when f2000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));  
                    
                when f2200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));  
                    
                when f2400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));  
                    
                when f2600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f2800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));  
                    
                when f3000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));  
                    
                when f3200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));  
                    
                when f3400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(34  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(33  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f3600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(36  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(25  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f3800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f4000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f4200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f4400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f4600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6)); 
                    
                when f4800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(2   ,6));
                    
                when f5000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f5200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f5400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f5600 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                when f5800 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f6000 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f6200 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 
                    
                when f6400 =>
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(900 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6)); 


                when others => --200MHz 
                    RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(7   ,5));
                    RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                    RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0   ,32));
                    RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                    
                    LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(7   ,5));
                    LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                    LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,32));
                    LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,32));
                    LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                    LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
            end case;
        end if;
    end process;
end architecture mix;

