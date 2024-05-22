library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.main_control_pkg.all;

entity Input_FlipFlops is
    port( 
        clk_i           : in std_logic;                             -- System clock
        rst_i           : in std_logic;                             -- Asynchronous reset

        start_PL_i      : in std_logic;                             -- Start signal for the PL (programmable logic)
        init_meas_i     : in std_logic;                             -- Initialization signal for measurements
        freq_done_i     : in std_logic;                             -- Frequency measurement done signal
        path_done_i     : in std_logic;                             -- Path measurement done signal
        freq_val_i      : in std_logic_vector(freq_data_length_c - 1 downto 0); -- Frequency value input
        ifbw_val_i      : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- IF bandwidth value input
        path_tx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0); -- Path transmit value input
        path_rx_val_i   : in std_logic_vector(path_data_length_c - 1 downto 0); -- Path receive value input

        output_start_PL_o   : out std_logic;                         -- Synchronized output for start_PL_i
        output_init_meas_o  : out std_logic;                         -- Synchronized output for init_meas_i
        output_freq_done_o  : out std_logic;                         -- Synchronized output for freq_done_i
        output_path_done_o  : out std_logic;                         -- Synchronized output for path_done_i
        output_freq_val_o   : out std_logic_vector(freq_data_length_c - 1 downto 0); -- Synchronized output for freq_val_i
        output_ifbw_val_o   : out std_logic_vector(ifbw_data_length_c - 1 downto 0); -- Synchronized output for ifbw_val_i
        output_path_tx_val_o: out std_logic_vector(path_data_length_c - 1 downto 0); -- Synchronized output for path_tx_val_i
        output_path_rx_val_o: out std_logic_vector(path_data_length_c - 1 downto 0)  -- Synchronized output for path_rx_val_i
    );  
end Input_FlipFlops;

architecture Behavioral of Input_FlipFlops is
    signal stage1_start_PL_s      : std_logic; -- First flip-flop output for start_PL_i
    signal stage1_init_meas_s     : std_logic; -- First flip-flop output for init_meas_i
    signal stage1_freq_done_s     : std_logic; -- First flip-flop output for freq_done_i
    signal stage1_path_done_s     : std_logic; -- First flip-flop output for path_done_i
    signal stage1_freq_val_s      : std_logic_vector(freq_data_length_c - 1 downto 0); -- First flip-flop output for freq_val_i
    signal stage1_ifbw_val_s      : std_logic_vector(ifbw_data_length_c - 1 downto 0); -- First flip-flop output for ifbw_val_i
    signal stage1_path_tx_val_s   : std_logic_vector(path_data_length_c - 1 downto 0); -- First flip-flop output for path_tx_val_i
    signal stage1_path_rx_val_s   : std_logic_vector(path_data_length_c - 1 downto 0); -- First flip-flop output for path_rx_val_i
    
    signal stage2_start_PL_s      : std_logic; -- Second flip-flop output for start_PL_i
    signal stage2_init_meas_s     : std_logic; -- Second flip-flop output for init_meas_i
    signal stage2_freq_done_s     : std_logic; -- Second flip-flop output for freq_done_i
    signal stage2_path_done_s     : std_logic; -- Second flip-flop output for path_done_i
    signal stage2_freq_val_s      : std_logic_vector(freq_data_length_c - 1 downto 0); -- Second flip-flop output for freq_val_i
    signal stage2_ifbw_val_s      : std_logic_vector(ifbw_data_length_c - 1 downto 0); -- Second flip-flop output for ifbw_val_i
    signal stage2_path_tx_val_s   : std_logic_vector(path_data_length_c - 1 downto 0); -- Second flip-flop output for path_tx_val_i
    signal stage2_path_rx_val_s   : std_logic_vector(path_data_length_c - 1 downto 0); -- Second flip-flop output for path_rx_val_i
    
begin
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then  -- Asynchronous reset
            -- Reset all output signals to '0'
            stage1_start_PL_s       <= '0';
            stage1_init_meas_s      <= '0';
            stage1_freq_done_s      <= '0';
            stage1_path_done_s      <= '0';
            stage1_freq_val_s       <= (others => '0');
            stage1_ifbw_val_s       <= (others => '0');
            stage1_path_tx_val_s    <= (others => '0');
            stage1_path_rx_val_s    <= (others => '0');
            
            stage2_start_PL_s       <= '0';
            stage2_init_meas_s      <= '0';
            stage2_freq_done_s      <= '0';
            stage2_path_done_s      <= '0';
            stage2_freq_val_s       <= (others => '0');
            stage2_ifbw_val_s       <= (others => '0');
            stage2_path_tx_val_s    <= (others => '0');
            stage2_path_rx_val_s    <= (others => '0');

        elsif rising_edge(clk_i) then
            -- First flip-flop captures the input signals
            stage1_start_PL_s       <= start_PL_i;
            stage1_init_meas_s      <= init_meas_i;
            stage1_freq_done_s      <= freq_done_i;
            stage1_path_done_s      <= path_done_i;
            stage1_freq_val_s       <= freq_val_i;
            stage1_ifbw_val_s       <= ifbw_val_i;
            stage1_path_tx_val_s    <= path_tx_val_i;
            stage1_path_rx_val_s    <= path_rx_val_i;
            
            -- Second flip-flop captures the first flip-flop outputs
            stage2_start_PL_s       <= stage1_start_PL_s;
            stage2_init_meas_s      <= stage1_init_meas_s;
            stage2_freq_done_s      <= stage1_freq_done_s;
            stage2_path_done_s      <= stage1_path_done_s;
            stage2_freq_val_s       <= stage1_freq_val_s;
            stage2_ifbw_val_s       <= stage1_ifbw_val_s;
            stage2_path_tx_val_s    <= stage1_path_tx_val_s;
            stage2_path_rx_val_s    <= stage1_path_rx_val_s;
        end if;
    end process;

    -- Output the synchronized signals
    output_start_PL_o    <= stage2_start_PL_s;
    output_init_meas_o   <= stage2_init_meas_s;
    output_freq_done_o   <= stage2_freq_done_s;
    output_path_done_o   <= stage2_path_done_s;
    output_freq_val_o    <= stage2_freq_val_s;
    output_ifbw_val_o    <= stage2_ifbw_val_s;
    output_path_tx_val_o <= stage2_path_tx_val_s;
    output_path_rx_val_o <= stage2_path_rx_val_s;
end Behavioral;

