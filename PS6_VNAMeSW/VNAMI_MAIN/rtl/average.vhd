LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.main_control_pkg.all;


entity average is
generic(
        BIT_WIDTH   : integer := 14
    );
port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        
        smplNbr_i   : in std_logic_vector(ifbw_data_length_c - 1 downto 0); -- 2^k of periods sampled (8 sample per period)
        start_i     : in std_logic;
        input_i     : in std_logic_vector(BIT_WIDTH-1 downto 0);
        
        done_o      : out std_logic;
        result_o    : out std_logic_vector(BIT_WIDTH-1 downto 0)
	);
end entity average;

architecture mix of average is
    
--------------------------- SIGNALS ---------------------------
    type state_t is
    (
       IDLE,
       SAMPLING
    );

    signal state_s          : state_t;
    signal sum_s            : std_logic_vector(2*BIT_WIDTH-1 downto 0);
    signal result_s         : std_logic_vector(2*BIT_WIDTH-1 downto 0);
    
    --signal counter_max_s    : integer := 2**(to_integer(unsigned(smplNbr_i)));
    signal counter_max_s    : unsigned(max_smpl_nmbr_c downto 0);
    
    --signal counter_s        : integer;
    signal counter_s        : unsigned(max_smpl_nmbr_c downto 0);
    signal offset_s         : integer;
	
-------------------------- COMPONENTS -------------------------
	
	
	
begin
--------------------------- DESIGN ----------------------------
    offset_s        <= to_integer(unsigned(smplNbr_i)) + 3;
    counter_max_s   <= shift_left(to_unsigned(2*8,max_smpl_nmbr_c+1), to_integer(unsigned(smplNbr_i))-1);             --8*2^smplNbr_i
    
    result_o        <= result_s(26 downto 0);
    
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                sum_s       <= (others => '0');
                result_s    <= (others => '0');
                state_s     <= IDLE;
                counter_s   <= (others => '0');
                done_o      <= '0';
            else
                case state_s is
                    when IDLE =>
                        if start_i = '1' then
                            state_s <= SAMPLING;
                            done_o  <= '0';
                        end if;
                    
                    when SAMPLING =>
                        if counter_s = (counter_max_s) then
                            state_s     <= IDLE;
                            counter_s   <= (others => '0');
                            result_s    <= std_logic_vector(shift_right(signed(sum_s), offset_s));
                            sum_s       <= (others => '0');
                            done_o      <= '1';
                        else
                            counter_s   <= counter_s + 1;
                            sum_s       <= std_logic_vector(signed(sum_s) + signed(input_i));
                        end if;
                        
                    when others =>
                        state_s     <= IDLE;
                        counter_s   <= (others => '0');
                        sum_s       <= (others => '0');
                    end case;
            end if; 
        end if;
    end process;

end architecture mix;

