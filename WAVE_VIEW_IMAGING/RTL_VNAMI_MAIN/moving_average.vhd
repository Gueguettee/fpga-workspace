LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;


entity moving_average is
    generic(
        BIT_WIDTH   : integer := 14;
        N_SAMPLES   : integer := 8; --minimum 2, must be a power of 2
        OFFSET      : integer := 3 --must be egal to log2(N_SAMPLES)
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        en_i        : in std_logic;
        input_i     : in std_logic_vector(BIT_WIDTH-1 downto 0);
        
        valid_o     : out std_logic;
        value_o     : out std_logic_vector(BIT_WIDTH-1 downto 0)
	);
end entity moving_average;

architecture mix of moving_average is
    
--------------------------- SIGNALS ---------------------------
    type state_t is
    (
       IDLE,
       SAMPLING
    );
    signal state_s          : state_t;

    signal sum_s            : signed(2*BIT_WIDTH-1 downto 0);

    signal valid_s          : std_logic;

    type data_arr_t is array (0 to N_SAMPLES-1) of signed(BIT_WIDTH-1 downto 0);
    signal data_arr_s : data_arr_t;

    signal counter_s        : integer range 0 to N_SAMPLES-1;
	
-------------------------- COMPONENTS -------------------------
	
begin
--------------------------- DESIGN ----------------------------

    
    valid_o  <= valid_s;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state_s     <= IDLE;

                counter_s   <= 0;
                valid_s     <= '0';
                sum_s       <= (others => '0');
                value_o   <= (others => '0');
                data_arr_s  <= (others => (others => '0'));

            else
                case state_s is
                    when IDLE =>
                        valid_s     <= '0';
                        counter_s   <= 0;
                        sum_s       <= (others => '0');
                        data_arr_s  <= (others => (others => '0'));

                        if en_i = '1' then
                            state_s <= SAMPLING;
                        end if;
                    
                    when SAMPLING =>
                        sum_s                   <= (sum_s - data_arr_s(counter_s) + signed(input_i));
                        data_arr_s(counter_s)   <= signed(input_i);

                        if counter_s = N_SAMPLES - 1 then
                            counter_s   <= 0;
                            valid_s     <= '1';
                            value_o <= std_logic_vector(resize(shift_right(sum_s, OFFSET), BIT_WIDTH));
                        else
                            counter_s   <= counter_s + 1;
                        end if;

                        if en_i = '0' then
                            state_s <= IDLE;
                        end if;
                        
                    when others =>
                        state_s     <= IDLE;

                    end case;
            end if; 
        end if;
    end process;

end architecture mix;
