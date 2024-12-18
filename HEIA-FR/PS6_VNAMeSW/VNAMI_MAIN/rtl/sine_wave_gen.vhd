LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;


entity sine_wave_gen is
generic(
        BIT_WIDTH   : integer := 14;
        TABLE_SIZE  : integer := 3;
        TABLE_WIDTH : integer := 3;
        SHIFT_90    : boolean := false
    );
port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
		
        sine_o      : out std_logic_vector(BIT_WIDTH-1 downto 0)
	);
end entity sine_wave_gen;

architecture mix of sine_wave_gen is
    
--------------------------- SIGNALS ---------------------------
	type state_t is
	(
	   COUNT_UP,
	   COUNT_DOWN
    );
    

	
	type table_t is array(0 to TABLE_SIZE-1) of std_logic_vector(BIT_WIDTH-1 downto 0);
	subtype table_index_t is integer range 0 to TABLE_SIZE-1;
	
	signal sine_table :table_t := (
        0 => std_logic_vector(to_signed(0,     BIT_WIDTH)),
        1 => std_logic_vector(to_signed(5793,  BIT_WIDTH)),
        2 => std_logic_vector(to_signed(8191,  BIT_WIDTH)),
	others => (others => '0')
	);
	
	
    signal state_s          : state_t;
    signal table_index_s    : table_index_t;
    signal positive_cycle_s : boolean; -- true-> positive,  false -> negative
	
-------------------------- COMPONENTS -------------------------
	
	begin
    
--------------------------- DESIGN ----------------------------
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                if SHIFT_90 = false then
                    state_s         <= COUNT_UP;
                    table_index_s   <= 0;
                else
                    state_s         <= COUNT_down;
                    table_index_s   <= TABLE_SIZE-1;
                end if;
                
                positive_cycle_s    <= true;
            else
                case state_s is
                    when COUNT_UP =>
                        if table_index_s = TABLE_SIZE-2 then
                            state_s <= COUNT_DOWN;
                        end if;
                        
                        table_index_s <= table_index_s + 1;
                        
                    when COUNT_DOWN =>
                        if table_index_s = 1 then
                            state_s <= COUNT_UP;
                            positive_cycle_s <= not positive_cycle_s;
                        end if;
                        
                        table_index_s <= table_index_s - 1;
                        
                    when others =>
                        state_s     <= COUNT_UP;
                    end case;
            end if;
        end if;
    end process;
    
    process(table_index_s, positive_cycle_s)

    begin
        if positive_cycle_s = true then
            sine_o <= sine_table(table_index_s);
        else
            sine_o <= std_logic_vector(-signed(sine_table(table_index_s)));
        end if;
    end process;
    
    
    

end architecture mix;

