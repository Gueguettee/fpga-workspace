library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.main_control_pkg.all;

entity Output_FlipFlops is
    port( 
        clk_i           : in std_logic;                             -- System clock
        rst_i           : in std_logic;                             -- Asynchronous reset

        I_TX_PL_i       : in std_logic_vector(31 downto 0);
        Q_TX_PL_i       : in std_logic_vector(31 downto 0);
        I_RX_PL_i       : in std_logic_vector(31 downto 0);
        Q_RX_PL_i       : in std_logic_vector(31 downto 0);

        IQ_rdy_PL_i     : in std_logic;

        output_tilt_i   : in std_logic_vector(2 downto 0);
        
        SPM_data_i      : in std_logic_vector(27 downto 0);

        I_TX_PL_o       : out std_logic_vector(31 downto 0);
        Q_TX_PL_o       : out std_logic_vector(31 downto 0);
        I_RX_PL_o       : out std_logic_vector(31 downto 0);
        Q_RX_PL_o       : out std_logic_vector(31 downto 0);

        IQ_rdy_PL_o     : out std_logic;

        output_tilt_o   : out std_logic_vector(2 downto 0);
        
        SPM_data_o      : out std_logic_vector(27 downto 0)
    );  
end Output_FlipFlops;

architecture mix of Output_FlipFlops is
    signal stage1_I_TX_PL_o : std_logic_vector(31 downto 0);
    signal stage2_I_TX_PL_o : std_logic_vector(31 downto 0);

    signal stage1_Q_TX_PL_o : std_logic_vector(31 downto 0);
    signal stage2_Q_TX_PL_o : std_logic_vector(31 downto 0);

    signal stage1_I_RX_PL_o : std_logic_vector(31 downto 0);
    signal stage2_I_RX_PL_o : std_logic_vector(31 downto 0);

    signal stage1_Q_RX_PL_o : std_logic_vector(31 downto 0);
    signal stage2_Q_RX_PL_o : std_logic_vector(31 downto 0);

    signal stage1_IQ_rdy_PL_o : std_logic;
    signal stage2_IQ_rdy_PL_o : std_logic;

    signal stage1_output_tilt_o : std_logic_vector(2 downto 0);
    signal stage2_output_tilt_o : std_logic_vector(2 downto 0);

    signal stage1_SPM_data_o : std_logic_vector(27 downto 0);
    signal stage2_SPM_data_o : std_logic_vector(27 downto 0);
    
begin
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then  -- Asynchronous reset
            -- Reset all output signals to '0'

            stage1_I_TX_PL_o <= (others => '0');
            stage2_I_TX_PL_o <= (others => '0');

            stage1_Q_TX_PL_o <= (others => '0');
            stage2_Q_TX_PL_o <= (others => '0');

            stage1_I_RX_PL_o <= (others => '0');
            stage2_I_RX_PL_o <= (others => '0');

            stage1_Q_RX_PL_o <= (others => '0');
            stage2_Q_RX_PL_o <= (others => '0');

            stage1_IQ_rdy_PL_o <= '0';
            stage2_IQ_rdy_PL_o <= '0';

            stage1_output_tilt_o <= (others => '0');
            stage2_output_tilt_o <= (others => '0');

            stage1_SPM_data_o <= (others => '0');
            stage2_SPM_data_o <= (others => '0');
            
        elsif rising_edge(clk_i) then
            -- First flip-flop captures the input signals
            
            stage1_I_TX_PL_o <= I_TX_PL_i;
            stage1_Q_TX_PL_o <= Q_TX_PL_i;
            stage1_I_RX_PL_o <= I_RX_PL_i;
            stage1_Q_RX_PL_o <= Q_RX_PL_i;

            stage1_IQ_rdy_PL_o <= IQ_rdy_PL_i;

            stage1_output_tilt_o <= output_tilt_i;

            stage1_SPM_data_o <= SPM_data_i;
            
            -- Second flip-flop captures the first flip-flop outputs

            stage2_I_TX_PL_o <= stage1_I_TX_PL_o;
            stage2_Q_TX_PL_o <= stage1_Q_TX_PL_o;
            stage2_I_RX_PL_o <= stage1_I_RX_PL_o;
            stage2_Q_RX_PL_o <= stage1_Q_RX_PL_o;

            stage2_IQ_rdy_PL_o <= stage1_IQ_rdy_PL_o;

            stage2_output_tilt_o <= stage1_output_tilt_o;

            stage2_SPM_data_o <= stage1_SPM_data_o;
            
        end if;
    end process;

    -- Output the synchronized signals
    I_TX_PL_o <= stage2_I_TX_PL_o;
    Q_TX_PL_o <= stage2_Q_TX_PL_o;
    I_RX_PL_o <= stage2_I_RX_PL_o;
    Q_RX_PL_o <= stage2_Q_RX_PL_o;

    IQ_rdy_PL_o <= stage2_IQ_rdy_PL_o;

    output_tilt_o <= stage2_output_tilt_o;

    SPM_data_o <= stage2_SPM_data_o;
    
end mix;

