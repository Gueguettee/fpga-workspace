LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;


entity SPI_synth_controller is
    generic(
        SYNTHESIZER         : synthesizer_t := LMX2594;
        RF_LO               : RF_LO_t := RF;
        BLOCK_PROGRAMMING   : boolean_t := NO;   --only avaiable for LMX2572
        BYPASS_SAME_ONES    : boolean_t := YES
    );
    port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;

        --intern inputs/outputs (from main control,etc)
        SPI_clock_speed_i : in std_logic_vector(SPI_CLOCK_SPEED_DATA_LENGTH_c - 1 downto 0);
        seq_id_i        : in seq_id_t;
        start_seq_i     : in std_logic;
        freq_i          : in std_logic_vector(freq_data_length_c-1 downto 0);
        offset_i        : in offset_t;
        power_i         : in power_t;

        pll_locked_o    : out std_logic;
        seq_done_o      : out std_logic;
        exception_o     : out std_logic;

        --external input outputs(physical)
        MUXout_i        : in std_logic;

        SCK_o           : out std_logic;
        SDI_o           : out std_logic;
        CSB_o           : out std_logic
    );
end entity SPI_synth_controller;

architecture mix of SPI_synth_controller is

--------------------------- SIGNALS ---------------------------

    signal rdy_s                : std_logic;

    signal rdy_next_data_s      : std_logic;
    
    signal start_s              : std_logic;
    signal start_seq_pulse_s    : std_logic;

    signal freq_s               : std_logic_vector(freq_data_length_c-1 downto 0);
    signal freq_decode_s        : freq_t;
    signal offset_s             : offset_t;
    signal power_s              : power_t;
    signal seq_id_s             : seq_id_t;
    
    signal RW_s              : std_logic;
    signal addr_s            : std_logic_vector(6 downto 0);
    signal data_TX_s         : std_logic_vector(15 downto 0);
    signal data_RX_s         : std_logic_vector(15 downto 0);
    signal spi_seq_i_s       : spi_seq_i_t;
    signal spi_seq_o_s       : spi_seq_o_t;

    signal last_seq_id_s        : seq_id_t;
    signal spi_last_seq_o_s     : spi_seq_o_t;

    signal nbr_of_cmds_s        : unsigned(NBR_OF_CMD_LENGHT-1 downto 0);

    signal spi_seq_counter_s    : integer range 0 to 2**NBR_OF_CMD_LENGHT-1;

    signal vco_rw_s             : std_logic;
    signal vco_i_s           : vco_t;
    signal vco_o_s           : vco_t;

    signal freq_para_s   : freq_para_t;

    type synth_state_t is (
        RESET,
        IDLE,
        SEQ,
        START_SEQ,
        WAIT_START_BIT,
        WAIT_END_BIT,
        WAIT_PLL_LOCKED,
        WRITE_VCO
    );
    signal synth_state_s : synth_state_t;

    signal SPI_clk_divider_s : integer range 0 to max_spi_clock_divider_c;

    signal watch_dog_timeout_counter_s : integer range 0 to ((2**synth_stability_data_length_c - 1)*clk_freq_mhz + watch_dog_timeout_init - 1);
    signal watch_dog_timeout_counter_loop_s : integer range 0 to watch_dog_timeout_loop - 1;
    signal glitch_management_counter_s : integer range 0 to glitch_management_delay_c - 1;
    signal glitch_management_counter_loop_s : integer range 0 to glitch_management_n_loop_c - 1;
    
-------------------------- COMPONENTS -------------------------
    
begin
--------------------------- DESIGN ----------------------------
    
    clk_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                spi_seq_counter_s   <= 0;

                spi_seq_i_s.data_i_s <= (others => (others => '0'));

                seq_done_o <= '0';
                exception_o <= '0';
                start_s <= '0';
                vco_rw_s <= '0';
                pll_locked_o <= '0';

                RW_s         <= RW_READ;
                addr_s       <= (others => '0');
                data_TX_s    <= (others => '0');

                freq_s <= (others => '0');
                offset_s <= OFFSET_0_MHz;
                seq_id_s <= 0;
                power_s <= (others => '0');

                SPI_clk_divider_s <= max_spi_clock_divider_c;

                watch_dog_timeout_counter_s <= 0;
                watch_dog_timeout_counter_loop_s <= 0;
                glitch_management_counter_s <= 0;
                glitch_management_counter_loop_s <= 0;

            else
                start_s <= '0';
                vco_rw_s <= '0';
                seq_done_o <= '0';

                case synth_state_s is
                    when IDLE =>
                        RW_s         <= RW_READ;
                        addr_s       <= (others => '0');
                        data_TX_s    <= (others => '0');

                        spi_seq_counter_s   <= 0;
                        seq_done_o <= '1';
                        pll_locked_o <= '1';

                        if start_seq_pulse_s = '1' then
                            synth_state_s <= START_SEQ;
                            power_s <= power_i;
                            seq_id_s <= seq_id_i;
                            freq_s <= freq_i;
                            offset_s <= offset_i;
                            seq_done_o <= '0';
                            exception_o <= '0';
                            pll_locked_o <= '0';
                            watch_dog_timeout_counter_s <= 0;
                            watch_dog_timeout_counter_loop_s <= 0;
                            glitch_management_counter_s <= 0;
                            glitch_management_counter_loop_s <= 0;
                        end if;

                    when START_SEQ =>
                        synth_state_s <= SEQ;
                        if seq_id_s = SEQ_ID_SET_FREQ_VCO then
                            SPI_clk_divider_s <= to_integer(unsigned(SPI_clock_speed_i));
                        else
                            SPI_clk_divider_s <= to_integer(unsigned(SPI_clock_speed_i));
                        end if;

                    when SEQ =>
                        if spi_seq_counter_s = 0 then
                            nbr_of_cmds_s <= spi_seq_o_s.nbr_of_cmds_s;
                        end if;

                        RW_s         <= spi_seq_o_s.RW_s(spi_seq_counter_s);
                        addr_s       <= spi_seq_o_s.addr_s(spi_seq_counter_s);
                        data_TX_s    <= spi_seq_o_s.data_o_s(spi_seq_counter_s);

                        synth_state_s <= WAIT_START_BIT;
                        start_s <= '1';
                        if BYPASS_SAME_ONES = YES
                            and seq_id_s = last_seq_id_s 
                            and seq_id_s = SEQ_ID_SET_FREQ_VCO 
                            and spi_seq_o_s.data_o_s(spi_seq_counter_s) = spi_last_seq_o_s.data_o_s(spi_seq_counter_s) then
                            start_s <= '0';
                            if spi_seq_counter_s < (to_integer(spi_seq_o_s.nbr_of_cmds_s)-1) then
                                synth_state_s <= SEQ;
                                spi_seq_counter_s <= spi_seq_counter_s + 1;
                            else
                                spi_last_seq_o_s <= spi_seq_o_s;
                                last_seq_id_s <= seq_id_s;
                                seq_done_o <= '1';
                                synth_state_s <= WAIT_PLL_LOCKED;
                            end if;
                        end if;

                    when WAIT_START_BIT =>
                        start_s <= '1';

                        if rdy_s = '0' then
                            synth_state_s <= WAIT_END_BIT;
                        end if;

                    when WAIT_END_BIT =>
                        start_s <= '1';
                        
                        if rdy_s = '1' then
                            spi_seq_i_s.data_i_s(spi_seq_counter_s) <= data_RX_s;
                            if spi_seq_counter_s = (to_integer(nbr_of_cmds_s)-1) then
                                spi_last_seq_o_s <= spi_seq_o_s;
                                last_seq_id_s <= seq_id_s;
                                if seq_id_s = SEQ_ID_READ_VCO then
                                    synth_state_s <= WRITE_VCO;
                                elsif seq_id_s = SEQ_ID_SET_FREQ then
                                    if data_RX_s(10 downto 9) = "10" then
                                        if glitch_management_counter_loop_s = glitch_management_n_loop_c - 1 then
                                            seq_done_o <= '1';
                                            synth_state_s <= IDLE;
                                        else
                                            glitch_management_counter_loop_s <= glitch_management_counter_loop_s + 1;
                                            synth_state_s <= SEQ;
                                        end if;
                                    else
                                        glitch_management_counter_loop_s <= 0;
                                        synth_state_s <= SEQ;
                                    end if;
                                    if watch_dog_timeout_counter_loop_s < watch_dog_timeout_loop - 1 then
                                        watch_dog_timeout_counter_loop_s <= watch_dog_timeout_counter_loop_s + 1;
                                    else
                                        synth_state_s <= IDLE;
                                        exception_o <= '1';
                                    end if;
                                else
                                    seq_done_o <= '1';
                                    synth_state_s <= WAIT_PLL_LOCKED;
                                end if;
                            else
                                synth_state_s <= SEQ;
                                spi_seq_counter_s <= spi_seq_counter_s + 1;
                            end if;
                        elsif BLOCK_PROGRAMMING = YES and spi_seq_counter_s < (to_integer(nbr_of_cmds_s)-1) then
                            if rdy_next_data_s = '1' and spi_seq_o_s.RW_s(spi_seq_counter_s + 1) = RW_WRITE and (unsigned(spi_seq_o_s.addr_s(spi_seq_counter_s + 1)) = unsigned(addr_s)-1) then
                                synth_state_s <= SEQ;
                                spi_seq_counter_s <= spi_seq_counter_s + 1;
                            end if;
                        end if;

                    when WAIT_PLL_LOCKED =>
                        seq_done_o <= '1';
                        
                        if MUXout_i = '1' then
                            if glitch_management_counter_s = glitch_management_delay_c - 1 then
                                synth_state_s <= IDLE;
                            else
                                glitch_management_counter_s <= glitch_management_counter_s + 1;
                            end if;
                        else
                            if seq_id_s = SEQ_ID_IDLE then
                                synth_state_s <= IDLE;
                            end if;
                            glitch_management_counter_s <= 0;
                        end if;

                        if seq_id_s = SEQ_ID_SET_FREQ_VCO and watch_dog_timeout_counter_s < watch_dog_timeout_set_freq_vco - 1 then
                            watch_dog_timeout_counter_s <= watch_dog_timeout_counter_s + 1;
                        elsif seq_id_s /= SEQ_ID_SET_FREQ_VCO and seq_id_s /= SEQ_ID_INIT and watch_dog_timeout_counter_s < watch_dog_timeout_set_freq - 1 then
                            watch_dog_timeout_counter_s <= watch_dog_timeout_counter_s + 1;
                        elsif seq_id_s = SEQ_ID_INIT and watch_dog_timeout_counter_s < watch_dog_timeout_init - 1 then
                            watch_dog_timeout_counter_s <= watch_dog_timeout_counter_s + 1;
                        else
                            synth_state_s <= IDLE;
                            exception_o <= '1';
                        end if;

                    when WRITE_VCO =>
                        vco_rw_s <= '1';
                        seq_done_o <= '1';
                        synth_state_s <= WAIT_PLL_LOCKED;

                    when others =>
                        synth_state_s <= IDLE;
                end case;
            end if;
        end if;
    end process;

    freq_decode : freq_decoder
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_s,
        freq_o          => freq_decode_s
    );
    
    freq_mem : SPI_synth_freq_mem
    generic map(
        RF_LO => RF_LO,
        SYNTHESIZER => SYNTHESIZER
    )
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_decode_s,
        offset_i        => offset_s,
        freq_para_o     => freq_para_s
    );
    
    seq_mem : SPI_synth_seq_mem
    generic map(
        RF_LO => RF_LO,
        SYNTHESIZER => SYNTHESIZER
    )
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        seq_id_i        => seq_id_s,
        freq_para_i     => freq_para_s,
        power_i         => power_s,
        spi_seq_i       => spi_seq_i_s,
        spi_seq_o       => spi_seq_o_s,
        vco_i           => vco_o_s,
        vco_o           => vco_i_s
    );
    
    SPI_driver : SPI_synth_driver
    generic map(
        ADDR_LENGTH         => ADDR_LENGTH,
        DATA_LENGTH         => DATA_LENGTH,
        BLOCK_PROGRAMMING   => BLOCK_PROGRAMMING
    )
    port map( 
        clk_i               => clk_i,
        reset_i             => reset_i,
        start_i             => start_s,
        spi_clk_divider_i   => SPI_clk_divider_s,
        RW_i                => RW_s,
        addr_i              => addr_s,
        data_i              => data_TX_s,
        data_o              => data_RX_s,
        MUXout_i            => MUXout_i,
        SCK_o               => SCK_o,
        SDI_o               => SDI_o,
        CSB_o               => CSB_o,
        CE_o                => open,
        rdy_o               => rdy_s,
        rdy_next_data_o     => rdy_next_data_s
    );

    start_edge_detect : edge_detector
    port map(
        clk_i       => clk_i,
        reset_i     => reset_i,
        input_i     => start_seq_i,
        pulse_o     => start_seq_pulse_s
    );

    vco_mem : SPI_synth_vco_mem
    port map(
        clk_i           => clk_i,
        reset_i         => reset_i,
        freq_i          => freq_s,
        rw_i            => vco_rw_s,
        vco_i           => vco_i_s,
        vco_o           => vco_o_s
    );

end architecture mix;
