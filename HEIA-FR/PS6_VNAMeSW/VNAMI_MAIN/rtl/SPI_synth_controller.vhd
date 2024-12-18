LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_synth_controller is
    generic(
        SPI_CLK_DIVIDER     : integer := 10 --minimum 2, only even numbers allowed
    );
    port(
            clk_i           : in std_logic;
            reset_i         : in std_logic;
        --intern inputs/outputs (from main control,etc)
            seq_id_i        : in std_logic_vector(5 downto 0);
            start_seq_i     : in std_logic;
            freq_i          : in std_logic_vector(5 downto 0);
            pll_locked_o    : out std_logic;
            seq_done_o      : out std_logic;
        --external input outputs(physical)
            RF_MUXout_i     : in std_logic;
            RF_SCK_o        : out std_logic;
            RF_SDI_o        : out std_logic;
            RF_CSB_o        : out std_logic;
            RF_CE_o         : out std_logic;
            LO_MUXout_i     : in std_logic;
            LO_SCK_o        : out std_logic;
            LO_SDI_o        : out std_logic;
            LO_CSB_o        : out std_logic;
            LO_CE_o         : out std_logic
    );
end entity SPI_synth_controller;

architecture mix of SPI_synth_controller is

--------------------------- SIGNALS ---------------------------

    signal RF_rdy_s             : std_logic;
    signal LO_rdy_s             : std_logic;
    signal rdy_s                : std_logic;
    
    signal start_s              : std_logic;
    signal start_seq_pulse_s    : std_logic;

    signal freq_s               : std_logic_vector(5 downto 0);
    signal seq_id_s             : unsigned(5 downto 0);
    
    signal RF_RW_s              : std_logic;
    signal LO_RW_s              : std_logic;
    signal RF_addr_s            : std_logic_vector(6 downto 0);
    signal LO_addr_s            : std_logic_vector(6 downto 0);
    signal RF_data_TX_s         : std_logic_vector(15 downto 0);
    signal LO_data_TX_s         : std_logic_vector(15 downto 0);
    signal RF_data_RX_s         : std_logic_vector(15 downto 0);
    signal LO_data_RX_s         : std_logic_vector(15 downto 0);
    signal RF_spi_seq_s         : spi_seq_t;
    signal LO_spi_seq_s         : spi_seq_t;

    signal nbr_of_cmds_s        : unsigned(NBR_OF_CMD_LENGHT-1 downto 0);

    signal spi_seq_counter_s    : integer range 0 to 2**NBR_OF_CMD_LENGHT-1;

    type synth_state_t is (
        IDLE,
        SEQ,
        START_SEQ,
        WAIT_START_BIT,
        WAIT_END_BIT,
        WAIT_END_SEQ
    );
    signal synth_state_s : synth_state_t;
    signal next_synth_state_s : synth_state_t;
    
-------------------------- COMPONENTS -------------------------
    
begin
--------------------------- DESIGN ----------------------------

    pll_locked_o <= LO_MUXout_i;--(RF_MUXout_i or LO_MUXout_i); --TODO replace or by and
    rdy_s <= LO_rdy_s;--(RF_rdy_s or LO_rdy_s); --TODO replace or by and
    
    next_state_process : process(synth_state_s, start_s, start_seq_pulse_s, rdy_s, nbr_of_cmds_s, spi_seq_counter_s)
    begin
        next_synth_state_s <= synth_state_s;
        case synth_state_s is
            when IDLE =>
                if start_seq_pulse_s = '1' then
                    next_synth_state_s <= START_SEQ;
                end if;
            when START_SEQ =>
                next_synth_state_s <= SEQ;
            when SEQ =>
                next_synth_state_s <= WAIT_START_BIT;
            when WAIT_START_BIT =>
                if rdy_s = '0' then
                    if spi_seq_counter_s = to_integer(nbr_of_cmds_s) then --MAY CAUSE PROBLEMS ONLY LOOKING ON RF
                        next_synth_state_s <= WAIT_END_SEQ;
                    else
                        next_synth_state_s <= WAIT_END_BIT;
                    end if;
                end if;
            when WAIT_END_BIT =>
                if rdy_s = '1' then
                    next_synth_state_s <= SEQ;
                end if;
            when WAIT_END_SEQ =>
                if rdy_s = '1' then
                    if start_seq_pulse_s = '1' then
                        next_synth_state_s <= START_SEQ;
                    else
                        next_synth_state_s <= IDLE;
                    end if;
                end if;
            when others =>
                next_synth_state_s <= IDLE;
        end case;
    end process;
    
    clk_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                synth_state_s <= IDLE;

                seq_done_o <= '0';
                start_s <= '0';

                spi_seq_counter_s   <= 0;
        
                RF_RW_s         <= RW_READ;
                RF_addr_s       <= (others => '0');
                RF_data_TX_s    <= (others => '0');
                
                LO_RW_s         <= RW_READ;
                LO_addr_s       <= (others => '0');
                LO_data_TX_s    <= (others => '0');

                freq_s <= (others => '0');
                seq_id_s <= (others => '0');

            else
                synth_state_s <= next_synth_state_s;

                seq_done_o <= '0';
                start_s <= '0';

                case next_synth_state_s is
                    when IDLE =>
                        spi_seq_counter_s   <= 0;
        
                        RF_RW_s         <= RW_READ;
                        RF_addr_s       <= (others => '0');
                        RF_data_TX_s    <= (others => '0');
                        
                        LO_RW_s         <= RW_READ;
                        LO_addr_s       <= (others => '0');
                        LO_data_TX_s    <= (others => '0');
        
                        freq_s <= (others => '0');
                        seq_id_s <= (others => '0');
                        
                        seq_done_o <= '1';
        
                    when START_SEQ =>
                        freq_s <= freq_i;
                        seq_id_s <= unsigned(seq_id_i);
                    
                    when SEQ =>
                        start_s <= '1';

                        if spi_seq_counter_s = 0 then
                            nbr_of_cmds_s <= RF_spi_seq_s.nbr_of_cmds_s;
                        end if;
        
                        RF_RW_s         <= RF_spi_seq_s.RW_s(spi_seq_counter_s);
                        RF_addr_s       <= RF_spi_seq_s.addr_s(spi_seq_counter_s);
                        RF_data_TX_s    <= RF_spi_seq_s.data_s(spi_seq_counter_s);
                        
                        LO_RW_s         <= LO_spi_seq_s.RW_s(spi_seq_counter_s);
                        LO_addr_s       <= LO_spi_seq_s.addr_s(spi_seq_counter_s);
                        LO_data_TX_s    <= LO_spi_seq_s.data_s(spi_seq_counter_s);
        
                        spi_seq_counter_s <= spi_seq_counter_s + 1;
        
                    when WAIT_START_BIT =>
                        start_s <= '1';
        
                    when WAIT_END_BIT =>
                        null;
        
                    when WAIT_END_SEQ =>
                        seq_done_o <= '1';
                        spi_seq_counter_s   <= 0;
        
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
    
    RF_SPI_driver : SPI_synth_LMX2572
    generic map(
        SPI_CLK_DIVIDER     => SPI_CLK_DIVIDER,
        ADDR_LENGTH         => ADDR_LENGTH,
        DATA_LENGTH         => DATA_LENGTH
        )
    port map( 
        clk_i               => clk_i,
        reset_i             => reset_i,
        start_i             => start_s,
        RW_i                => RF_RW_s,
        addr_i              => RF_addr_s,
        data_i              => RF_data_TX_s,
        data_o              => RF_data_RX_s,
        MUXout_i            => RF_MUXout_i,
        SCK_o               => RF_SCK_o,
        SDI_o               => RF_SDI_o,
        CSB_o               => RF_CSB_o,
        CE_o                => RF_CE_o,
        rdy_o               => RF_rdy_s
    );
    
    LO_SPI_driver : SPI_synth_LMX2572
    generic map(
        SPI_CLK_DIVIDER     => SPI_CLK_DIVIDER,
        ADDR_LENGTH         => ADDR_LENGTH,
        DATA_LENGTH         => DATA_LENGTH
        )
    port map( 
        clk_i               => clk_i,
        reset_i             => reset_i,
        start_i             => start_s,
        RW_i                => LO_RW_s,
        addr_i              => LO_addr_s,
        data_i              => LO_data_TX_s,
        data_o              => LO_data_RX_s,
        MUXout_i            => LO_MUXout_i,
        SCK_o               => LO_SCK_o,
        SDI_o               => LO_SDI_o,
        CSB_o               => LO_CSB_o,
        CE_o                => LO_CE_o,
        rdy_o               => LO_rdy_s
    );
    
    SPI_seq_mem : SPI_synth_seq
    port map( 
        clk_i               => clk_i,
        reset_i             => reset_i,
        freq_i              => freq_s,
        seq_id_i            => seq_id_s,
        RF_spi_seq_o        => RF_spi_seq_s,
        LO_spi_seq_o        => LO_spi_seq_s
    );

    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => start_seq_i,
        pulse_o     => start_seq_pulse_s
    );

end architecture mix;
