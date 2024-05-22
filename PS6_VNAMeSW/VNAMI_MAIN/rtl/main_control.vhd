LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;


entity main_control is
port(
        clk_i           : in std_logic;
        reset_i         : in std_logic;
		
        start_i         : in std_logic;

        init_meas_i     : in std_logic;
        freq_done_i     : in std_logic;
        path_done_i     : in std_logic;

        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0);

        sample_done_i   : in std_logic;
        pll_locked_i    : in std_logic;
        switch_set_i    : in std_logic;
        
        state_o         : out std_logic_vector(3 downto 0);
        
        synth_seq_id_o  : out std_logic_vector(5 downto 0);
        en_set_sw_o     : out std_logic;
        en_set_freq_o   : out std_logic;
        en_rf_o         : out std_logic;

        start_sample_o  : out std_logic;

        IQ_rdy_PL_o     : out std_logic;
        write_IQ_o      : out std_logic;

        freq_val_o      : out std_logic_vector(freq_data_length_c - 1 downto 0);
        ifbw_val_o      : out std_logic_vector(ifbw_data_length_c - 1 downto 0);
        path_tx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0);
        path_rx_val_o   : out std_logic_vector(path_data_length_c - 1 downto 0)
	);
end entity main_control;

architecture mix of main_control is
    
--------------------------- SIGNALS ---------------------------
	type state_t is
	(
        WAIT_FOR_START_UP,
        START_UP,
        IDLE,

        SET_SW,
        SET_FREQ,
        START_SAMPLE,
        RF_ON,
        IQ_READY,
        WRITE_IQ,

        START_INIT,
        INIT_MEAS,
        SAVE_FREQ,
        SAVE_PATH
    );
    
    constant N_PERIOD_TO_WAIT_AT_START : integer := 50000;
    signal wait_counter_s : integer range N_PERIOD_TO_WAIT_AT_START downto 0;

    signal state_s          : state_t;
    signal freq_done_s      : std_logic;
    signal path_done_s      : std_logic;

    signal freq_val_o_s     : std_logic_vector(freq_data_length_c - 1 downto 0);
    
    -- RAMs write and read enable
    signal freq_wr_en_s     : std_logic;
    signal path_wr_en_s     : std_logic;

    signal freq_rd_en_s     : std_logic;
    signal path_rd_en_s     : std_logic;

    -- RAMs address
    signal freq_RAM_wr_add_s   : unsigned(freq_addr_length_c - 1 downto 0);
    signal freq_RAM_rd_add_s   : unsigned(freq_addr_length_c - 1 downto 0);

    signal path_RAM_wr_add_s   : unsigned(path_addr_length_c - 1 downto 0);
    signal path_RAM_rd_add_s   : unsigned(path_addr_length_c - 1 downto 0);
	
-------------------------- COMPONENTS -------------------------


begin
--------------------------- DESIGN ----------------------------

    --next state logic
    process(clk_i)
    variable cnt_v : integer;
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= WAIT_FOR_START_UP;
                wait_counter_s <= N_PERIOD_TO_WAIT_AT_START;
            
                freq_RAM_wr_add_s   <= (others => '0');
                freq_RAM_rd_add_s   <= (others => '0');
            
                path_RAM_wr_add_s   <= (others => '0');
                path_RAM_rd_add_s   <= (others => '0');
            else
                IQ_rdy_PL_o     <= '0'; --in general, can change inside of certain states, in which it needs to be updated at each clock

                case state_s is
                    when WAIT_FOR_START_UP =>
                        if wait_counter_s > 0 then
                            wait_counter_s <= wait_counter_s - 1;
                        else
                            state_s     <= START_UP;
                        end if;

                    when START_UP =>
                        if pll_locked_i = '1' then
                            state_s     <= IDLE;
                            freq_done_s <= not freq_done_i; --IQ_rdy_PL_o should be down at init
                        end if;

                    when IDLE =>
                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                        if start_i = '1' then
                            state_s     <= SET_SW;
                            freq_done_s <= not freq_done_i; --for first measure, no need to wait before update value
                            path_done_s <= path_done_i; --to go out the routine if path_done is toggled (avoid to get stuck in IQ_READY)

                        elsif init_meas_i = '1' then
                            state_s     <= START_INIT;
                            freq_done_s <=  freq_done_i;
                            path_done_s <=  path_done_i;
                        end if;

                    when SET_SW =>
                        if switch_set_i = '1' then
                            state_s             <= SET_FREQ;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when SET_FREQ =>
                        if pll_locked_i = '1' then
                            state_s             <= START_SAMPLE;
                            --update addresses for next values (values are loaded in state IQ_READY)
                            if freq_RAM_rd_add_s = (freq_RAM_wr_add_s - 1) then
                                freq_RAM_rd_add_s   <= (others => '0');
                                path_RAM_rd_add_s   <= path_RAM_rd_add_s + 1;
                            else
                                freq_RAM_rd_add_s   <= freq_RAM_rd_add_s + 1;
                            end if;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when START_SAMPLE =>    --This state is to avoid reading 1 directly on sample_done_i as it is set to 0 only after start_sample 
                        if sample_done_i = '0' then
                            state_s     <= RF_ON;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when RF_ON =>
                        if sample_done_i = '1' then 
                            state_s <= IQ_READY;
                        end if;

                        IQ_rdy_PL_o     <= freq_done_i xnor freq_done_s;

                    when IQ_READY =>
                        if (freq_done_i xor freq_done_s) = '1' then --wait for PS to have read the last value before update with the new one
                            freq_done_s <= freq_done_i;
                            state_s     <= WRITE_IQ;
                        elsif (path_done_i xor path_done_s) = '1' then --if path_done toggle -> back to IDLE (to stop a the routine from PS)
                            state_s     <= IDLE;
                            -- reset read adresses 
                            freq_RAM_rd_add_s   <= (others => '0');
                            path_RAM_rd_add_s   <= (others => '0');
                            freq_done_s         <= not freq_done_i; --IQ_rdy_PL_o low in IDLE
                        end if;
                        
                        IQ_rdy_PL_o     <= '1';

                    when WRITE_IQ =>
                        --next frequency 
                        state_s <= SET_FREQ;

                        if path_RAM_rd_add_s = path_RAM_wr_add_s then --check if it was the last path (if next path is out of initialized RAM)
                            state_s             <= IDLE;
                            -- reset read adresses 
                            freq_RAM_rd_add_s   <= (others => '0');
                            path_RAM_rd_add_s   <= (others => '0');

                        elsif freq_RAM_rd_add_s = 0 then --if next frequency is the first of the list, change path before frequency
                            state_s <= SET_SW;
                        end if;

                        IQ_rdy_PL_o     <= '1';

                    when START_INIT =>
                        state_s     <= INIT_MEAS;

                        -- Init read and write addresses to 0
                        freq_RAM_wr_add_s   <= (others => '0');
                        freq_RAM_rd_add_s   <= (others => '0');
                    
                        path_RAM_wr_add_s   <= (others => '0');
                        path_RAM_rd_add_s   <= (others => '0');

                    when INIT_MEAS =>
                        if init_meas_i = '0' then
                            state_s     <= IDLE;
                            freq_done_s <= not freq_done_i;
                        elsif (freq_done_i xor freq_done_s) = '1' then
                            state_s     <= SAVE_FREQ;
                            freq_done_s <= freq_done_i;
                        elsif (path_done_i xor path_done_s) = '1' then
                            state_s     <= SAVE_PATH;
                            path_done_s <= path_done_i;
                        end if;

                    when SAVE_FREQ =>
                        state_s <= INIT_MEAS;

                        freq_RAM_wr_add_s   <= freq_RAM_wr_add_s + 1;
                    
                    when SAVE_PATH =>
                        state_s <= INIT_MEAS;

                        path_RAM_wr_add_s   <= path_RAM_wr_add_s + 1;
                            
                    when others =>
                        state_s     <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
    --output logic
    process(state_s)
    begin

        state_o         <= "0000";
        synth_seq_id_o  <= "000001";
        en_set_sw_o     <= '0';
        en_set_freq_o   <= '0';
        en_rf_o         <= '0';
        start_sample_o  <= '0';
        write_IQ_o      <= '0';

        freq_wr_en_s    <= '0';
        path_wr_en_s    <= '0';

        freq_rd_en_s    <= '0';
        path_rd_en_s    <= '0';

        freq_val_o      <= freq_val_o_s;
            
        case state_s is
            when WAIT_FOR_START_UP =>
                null;

            when START_UP =>
                state_o         <= "0001";
                synth_seq_id_o  <= "000000";
                en_set_freq_o   <= '1';
                freq_val_o      <= (others => '0');

            when IDLE =>
                state_o         <= "0010";

                freq_rd_en_s    <= '1';
                path_rd_en_s    <= '1';

                freq_val_o      <= (others => '0');

            when SET_SW =>
                state_o         <= "0011";
                en_set_sw_o     <= '1';

            when SET_FREQ =>
                state_o         <= "0100";
                en_set_freq_o   <= '1';

            when START_SAMPLE =>
                state_o         <= "0101";
                start_sample_o  <= '1';
                en_rf_o         <= '1';

            when RF_ON =>
                state_o         <= "0110";
                en_rf_o         <= '1';

            when IQ_READY =>
                state_o         <= "0111";
                
                -- Load next values for synthesizer and SW (for next measurement)
                freq_rd_en_s    <= '1';
                path_rd_en_s    <= '1';

            when WRITE_IQ =>
                state_o         <= "1000";
                write_IQ_o      <= '1';
            
            when START_INIT =>
                state_o         <= "1001";

            when INIT_MEAS =>
                state_o         <= "1010";

            when SAVE_FREQ =>
                state_o         <= "1011";
                freq_wr_en_s    <= '1';
            
            when SAVE_PATH =>
                state_o         <= "1100";
                path_wr_en_s    <= '1';

            when others =>
                state_o         <= "0000";
            end case;
    end process;

    FREQ_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => freq_data_length_c,
        ADDR_LENGTH     => freq_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => freq_val_i,
        data_o      => freq_val_o_s
    );

    IFBW_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => ifbw_data_length_c,
        ADDR_LENGTH     => ifbw_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => freq_wr_en_s,
        rd_en_i     => freq_rd_en_s,
        wr_addr_i   => std_logic_vector(freq_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(freq_RAM_rd_add_s),
        data_i      => ifbw_val_i,
        data_o      => ifbw_val_o
    );

    TX_PATH_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => path_data_length_c,
        ADDR_LENGTH     => path_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => path_wr_en_s,
        rd_en_i     => path_rd_en_s,
        wr_addr_i   => std_logic_vector(path_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(path_RAM_rd_add_s),
        data_i      => path_tx_val_i,
        data_o      => path_tx_val_o
    );

    RX_PATH_RAM: sp_RAM
    generic map(
        DATA_LENGTH     => path_data_length_c,
        ADDR_LENGTH     => path_addr_length_c
    )
    port map(
        clk_i       => clk_i,
        rst_i       => reset_i,
        wr_en_i     => path_wr_en_s,
        rd_en_i     => path_rd_en_s,
        wr_addr_i   => std_logic_vector(path_RAM_wr_add_s),
        rd_addr_i   => std_logic_vector(path_RAM_rd_add_s),
        data_i      => path_rx_val_i,
        data_o      => path_rx_val_o
    );

end architecture mix;

