LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;


entity average_ADC is
    generic(
        BIT_WIDTH   : integer := 27
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        
        smplNbr_i   : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- 2^k of periods sampled (8 sample per period)
        start_i     : in std_logic;
        adc_input_i : in std_logic_vector(ADC_data_length_c - 1 downto 0);
        sub_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        sup_threshold_i   : in std_logic_vector(ADC_data_length_c - 2 downto 0);
        
        done_o      : out std_logic;

        ADC_sub_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0);
        ADC_sup_threshold_indicator_o : out std_logic_vector(ADC_data_range_indicator_data_length_c - 1 downto 0)
    );
end entity average_ADC;

architecture mix of average_ADC is

--------------------------- SIGNALS ---------------------------
    type state_t is
    (
       IDLE,
       SAMPLING
    );

    signal state_s          : state_t;
    
    --signal counter_max_s    : integer := 2**(to_integer(unsigned(smplNbr_i)));
    signal counter_max_s    : unsigned(max_smpl_nmbr_c downto 0);
    
    --signal counter_s        : integer;
    signal counter_s        : unsigned(max_smpl_nmbr_c downto 0);
    signal offset_s         : integer;

    signal saturation_counter_s : integer range 0 to (2**max_smpl_nmbr_c);
    signal sub_threshold_counter_s : integer range 0 to (2**max_smpl_nmbr_c);

    signal sub_threshold_s : std_logic_vector(ADC_data_length_c-1 downto 0);
    signal sup_threshold_s : std_logic_vector(ADC_data_length_c-1 downto 0);
	
-------------------------- COMPONENTS -------------------------
	
begin
--------------------------- DESIGN ----------------------------
    counter_max_s   <= shift_left(to_unsigned(8, max_smpl_nmbr_c+1), to_integer(unsigned(smplNbr_i)));   --8*(2^smplNbr_i) -> verified
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;
                counter_s   <= (others => '0');
                done_o      <= '1';
                sub_threshold_s <= (others => '0');
                sup_threshold_s <= (others => '0');
                ADC_sub_threshold_indicator_o <= (others => '0');
                ADC_sup_threshold_indicator_o <= (others => '0');
            else
                case state_s is
                    when IDLE =>
                        if start_i = '1' then
                            state_s <= SAMPLING;
                            done_o  <= '0';
                            saturation_counter_s <= 0;
                            sub_threshold_counter_s <= 0;
                            sub_threshold_s(ADC_data_length_c-1) <= '0';
                            sub_threshold_s(ADC_data_length_c-2 downto 0) <= sub_threshold_i;
                            sup_threshold_s(ADC_data_length_c-1) <= '0';
                            sup_threshold_s(ADC_data_length_c-2 downto 0) <= sup_threshold_i;
                        end if;
                    
                    when SAMPLING =>
                        if counter_s = counter_max_s then
                            state_s     <= IDLE;
                            counter_s   <= (others => '0');
                            done_o      <= '1';
                            ADC_sub_threshold_indicator_o <= std_logic_vector(to_unsigned(sub_threshold_counter_s, ADC_data_range_indicator_data_length_c));
                            ADC_sup_threshold_indicator_o <= std_logic_vector(to_unsigned(saturation_counter_s, ADC_data_range_indicator_data_length_c));
                        else
                            counter_s   <= counter_s + 1;
                            if adc_input_i = "10000000000000" then  -- Signed minimum value
                                saturation_counter_s <= saturation_counter_s + 1;
                            else
                                if (signed(adc_input_i) >= 0 and signed(adc_input_i) >= signed(sup_threshold_s)) or (signed(adc_input_i) < 0 and -signed(adc_input_i) >= signed(sup_threshold_s)) then
                                    saturation_counter_s <= saturation_counter_s + 1;
                                elsif (signed(adc_input_i) >= 0 and signed(adc_input_i) < signed(sub_threshold_s)) or (signed(adc_input_i) < 0 and -signed(adc_input_i) < signed(sub_threshold_s)) then
                                    sub_threshold_counter_s <= sub_threshold_counter_s + 1;
                                end if;
                            end if;
                        end if;
                        
                    when others =>
                        state_s     <= IDLE;
                        counter_s   <= (others => '0');
                    end case;
            end if; 
        end if;
    end process;

end architecture mix;

