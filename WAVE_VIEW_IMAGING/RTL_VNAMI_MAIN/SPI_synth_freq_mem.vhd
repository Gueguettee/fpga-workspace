LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_synth_freq_mem is
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
end entity SPI_synth_freq_mem;

architecture mix of SPI_synth_freq_mem is
    
--------------------------- SIGNALS ---------------------------
    
    type spi_seq_arr_t is array (63 downto 0) of spi_seq_o_t;
    signal spi_seq_arr_s    : spi_seq_arr_t;

    signal RF_freq_para_o    : freq_para_t;
    signal LO_freq_para_o    : freq_para_t;
    
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    freq_para_o <= RF_freq_para_o when RF_LO = RF else LO_freq_para_o;
    
    process(reset_i, freq_i, offset_i)
    begin
        --default values
        RF_freq_para_o.CHDIV_s          <= x"0800";
        RF_freq_para_o.PLL_N_s          <= x"0000";
        RF_freq_para_o.PLL_NUM_s        <= x"0000";
        RF_freq_para_o.PLL_DEN_s        <= std_logic_vector(to_unsigned(1000,16));
        if SYNTHESIZER = LMX2572 then
            RF_freq_para_o.OUTA_MUX_s       <= x"C600"; --TODO not here in the SPI synth seq mem file
            RF_freq_para_o.OUTB_MUX_s       <= x"07F0"; --TODO not here in the SPI synth seq mem file
            RF_freq_para_o.PFD_DLY_SEL_s    <= x"0205";
        else
            RF_freq_para_o.OUTA_MUX_s       <= x"C0DF"; --TODO not here in the SPI synth seq mem file
            RF_freq_para_o.OUTB_MUX_s       <= x"07FD"; --TODO not here in the SPI synth seq mem file
            RF_freq_para_o.PFD_DLY_SEL_s    <= x"0404";
        end if;
        
        LO_freq_para_o.CHDIV_s          <= x"0800";
        LO_freq_para_o.PLL_N_s          <= x"0000";
        LO_freq_para_o.PLL_NUM_s        <= x"0000";
        LO_freq_para_o.PLL_DEN_s        <= std_logic_vector(to_unsigned(1000,16));
        if SYNTHESIZER = LMX2572 then
            LO_freq_para_o.OUTA_MUX_s       <= x"C600"; --TODO not here in the SPI synth seq mem file
            LO_freq_para_o.OUTB_MUX_s       <= x"07F0"; --TODO not here in the SPI synth seq mem file
            LO_freq_para_o.PFD_DLY_SEL_s    <= x"0205";
        else
            LO_freq_para_o.OUTA_MUX_s       <= x"C0DF"; --TODO not here in the SPI synth seq mem file
            LO_freq_para_o.OUTB_MUX_s       <= x"07FD"; --TODO not here in the SPI synth seq mem file
            LO_freq_para_o.PFD_DLY_SEL_s    <= x"0404";
        end if;
        
        if reset_i = '1' then
            null;
        else
            if SYNTHESIZER = LMX2572 then
                 -- LMX2572 specific settings (to be generated with Python script)
            else -- LMX2594
                case offset_i is
                    when OFFSET_10_MHz => -- 10 MHz offset
                        case freq_i is
                            when 800 =>    -- 8010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(50 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 8000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 795 =>    -- 7960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 790 =>    -- 7910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(550 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1005 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 785 =>    -- 7860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 780 =>    -- 7810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(50 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 775 =>    -- 7760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 770 =>    -- 7710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(550 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1005 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 765 =>    -- 7660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 760 =>    -- 7610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(50 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 755 =>    -- 7560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 750 =>    -- 7510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(550 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1005 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 745 =>    -- 7460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 740 =>    -- 7410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 735 =>    -- 7360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 730 =>    -- 7310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 725 =>    -- 7260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 720 =>    -- 7210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 715 =>    -- 7160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 710 =>    -- 7110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 705 =>    -- 7060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 700 =>    -- 7010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 695 =>    -- 6960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 690 =>    -- 6910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 685 =>    -- 6860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 680 =>    -- 6810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 675 =>    -- 6760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 670 =>    -- 6710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 665 =>    -- 6660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 660 =>    -- 6610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 655 =>    -- 6560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 650 =>    -- 6510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 645 =>    -- 6460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 640 =>    -- 6410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 635 =>    -- 6360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 630 =>    -- 6310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 625 =>    -- 6260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 620 =>    -- 6210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 615 =>    -- 6160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 610 =>    -- 6110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 605 =>    -- 6060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 600 =>    -- 6010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 595 =>    -- 5960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 590 =>    -- 5910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 585 =>    -- 5860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 580 =>    -- 5810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 575 =>    -- 5760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 570 =>    -- 5710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 565 =>    -- 5660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 560 =>    -- 5610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 555 =>    -- 5560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 550 =>    -- 5510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 545 =>    -- 5460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 540 =>    -- 5410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 535 =>    -- 5360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 530 =>    -- 5310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 525 =>    -- 5260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 520 =>    -- 5210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 515 =>    -- 5160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 510 =>    -- 5110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 505 =>    -- 5060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 500 =>    -- 5010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 495 =>    -- 4960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 490 =>    -- 4910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 485 =>    -- 4860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 480 =>    -- 4810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 475 =>    -- 4760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 470 =>    -- 4710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 465 =>    -- 4660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 460 =>    -- 4610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 455 =>    -- 4560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 450 =>    -- 4510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 445 =>    -- 4460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 440 =>    -- 4410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 435 =>    -- 4360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 430 =>    -- 4310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 425 =>    -- 4260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 420 =>    -- 4210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 415 =>    -- 4160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 410 =>    -- 4110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 405 =>    -- 4060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 400 =>    -- 4010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 395 =>    -- 3960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 390 =>    -- 3910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 385 =>    -- 3860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 380 =>    -- 3810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(100 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(5 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 375 =>    -- 3760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(600 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(505 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 370 =>    -- 3710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 365 =>    -- 3660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 360 =>    -- 3610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 355 =>    -- 3560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 350 =>    -- 3510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 345 =>    -- 3460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 340 =>    -- 3410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 335 =>    -- 3360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 330 =>    -- 3310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 325 =>    -- 3260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 320 =>    -- 3210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 315 =>    -- 3160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 310 =>    -- 3110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 305 =>    -- 3060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 300 =>    -- 3010.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 295 =>    -- 2960.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2950.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 290 =>    -- 2910.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2900.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 285 =>    -- 2860.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2850.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 280 =>    -- 2810.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2800.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 275 =>    -- 2760.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2750.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 270 =>    -- 2710.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2700.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 265 =>    -- 2660.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2650.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 260 =>    -- 2610.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2600.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 255 =>    -- 2560.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2550.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 250 =>    -- 2510.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(200 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2500.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(10 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 245 =>    -- 2460.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2450.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(515 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 240 =>    -- 2410.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2400.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(15 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 235 =>    -- 2360.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2350.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(515 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 230 =>    -- 2310.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2300.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(15 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 225 =>    -- 2260.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2250.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(515 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 220 =>    -- 2210.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2200.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(15 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 215 =>    -- 2160.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2150.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(515 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 210 =>    -- 2110.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2100.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(15 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 205 =>    -- 2060.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(800 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2050.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(515 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when others =>    -- 2000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(300 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2000.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(15 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                        end case;
                    when others => -- 0 MHz offset
                        case freq_i is
                            when 800 =>    -- 8000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 795 =>    -- 7950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(750 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 790 =>    -- 7900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 785 =>    -- 7850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(250 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 780 =>    -- 7800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 775 =>    -- 7750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(750 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 770 =>    -- 7700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 765 =>    -- 7650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(250 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 760 =>    -- 7600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 755 =>    -- 7550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(750 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 7540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(1405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(2000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(1   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 750 =>    -- 7500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(75  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 745 =>    -- 7450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 740 =>    -- 7400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 735 =>    -- 7350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 730 =>    -- 7300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 725 =>    -- 7250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 720 =>    -- 7200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 715 =>    -- 7150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 710 =>    -- 7100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 705 =>    -- 7050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 7040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 700 =>    -- 7000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 695 =>    -- 6950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 690 =>    -- 6900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 685 =>    -- 6850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 680 =>    -- 6800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 675 =>    -- 6750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 670 =>    -- 6700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 665 =>    -- 6650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 660 =>    -- 6600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 655 =>    -- 6550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 650 =>    -- 6500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 645 =>    -- 6450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 640 =>    -- 6400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 635 =>    -- 6350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 630 =>    -- 6300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 625 =>    -- 6250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 620 =>    -- 6200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 615 =>    -- 6150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 610 =>    -- 6100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 605 =>    -- 6050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 6040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 600 =>    -- 6000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 595 =>    -- 5950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 590 =>    -- 5900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 585 =>    -- 5850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 580 =>    -- 5800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 575 =>    -- 5750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 570 =>    -- 5700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 565 =>    -- 5650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 560 =>    -- 5600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 555 =>    -- 5550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 550 =>    -- 5500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 545 =>    -- 5450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 540 =>    -- 5400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 535 =>    -- 5350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 530 =>    -- 5300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 525 =>    -- 5250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 520 =>    -- 5200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 515 =>    -- 5150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 510 =>    -- 5100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 505 =>    -- 5050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 5040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 500 =>    -- 5000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 495 =>    -- 4950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 490 =>    -- 4900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(49  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 485 =>    -- 4850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 480 =>    -- 4800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(48  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 475 =>    -- 4750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 470 =>    -- 4700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(47  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 465 =>    -- 4650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 460 =>    -- 4600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(46  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 455 =>    -- 4550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 450 =>    -- 4500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(45  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 445 =>    -- 4450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 440 =>    -- 4400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(44  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 435 =>    -- 4350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 430 =>    -- 4300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(43  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 425 =>    -- 4250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 420 =>    -- 4200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(42  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 415 =>    -- 4150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 410 =>    -- 4100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(41  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 405 =>    -- 4050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 4040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 400 =>    -- 4000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(40  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 395 =>    -- 3950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 390 =>    -- 3900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(39  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 385 =>    -- 3850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(405 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 380 =>    -- 3800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(38  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));

                                -- 3790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(0   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(37  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(905 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(3   ,6));
                                
                            when 375 =>    -- 3750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(75  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 370 =>    -- 3700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 365 =>    -- 3650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 360 =>    -- 3600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 355 =>    -- 3550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 350 =>    -- 3500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 345 =>    -- 3450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 340 =>    -- 3400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 335 =>    -- 3350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 330 =>    -- 3300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 325 =>    -- 3250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 320 =>    -- 3200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 315 =>    -- 3150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 310 =>    -- 3100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 305 =>    -- 3050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 3040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 300 =>    -- 3000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 295 =>    -- 2950.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2940.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 290 =>    -- 2900.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(58  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2890.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 285 =>    -- 2850.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(57  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2840.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 280 =>    -- 2800.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(56  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2790.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 275 =>    -- 2750.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(55  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2740.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 270 =>    -- 2700.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(54  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2690.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 265 =>    -- 2650.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(53  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2640.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 260 =>    -- 2600.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(52  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2590.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 255 =>    -- 2550.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(51  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2540.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(1   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(50  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(810 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 250 =>    -- 2500.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(75  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2490.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(74  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 245 =>    -- 2450.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2440.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(73  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(215 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 240 =>    -- 2400.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(72  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2390.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(71  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 235 =>    -- 2350.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2340.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(70  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(215 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 230 =>    -- 2300.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(69  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2290.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(68  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 225 =>    -- 2250.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2240.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(67  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(215 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 220 =>    -- 2200.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(66  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2190.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(65  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 215 =>    -- 2150.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2140.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(64  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(215 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 210 =>    -- 2100.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(63  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2090.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(62  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when 205 =>    -- 2050.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(500 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 2040.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(61  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(215 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                                
                            when others =>    -- 2000.0 MHz
                                RF_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                RF_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(60  ,16));
                                RF_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(0 ,16));
                                RF_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                RF_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                RF_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));

                                -- 1990.5 MHz
                                LO_freq_para_o.CHDIV_s(10 downto 6)         <= std_logic_vector(to_unsigned(2   ,5));
                                LO_freq_para_o.PLL_N_s                      <= std_logic_vector(to_unsigned(59  ,16));
                                LO_freq_para_o.PLL_NUM_s                    <= std_logic_vector(to_unsigned(715 ,16));
                                LO_freq_para_o.PLL_DEN_s                    <= std_logic_vector(to_unsigned(1000,16));
                                LO_freq_para_o.OUTA_MUX_s(12 downto 11)     <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.OUTB_MUX_s(1 downto 0)       <= std_logic_vector(to_unsigned(0   ,2));
                                LO_freq_para_o.PFD_DLY_SEL_s(13 downto 8)   <= std_logic_vector(to_unsigned(4   ,6));
                        end case;
                end case;
            end if;
        end if;
    end process;
end architecture mix;
