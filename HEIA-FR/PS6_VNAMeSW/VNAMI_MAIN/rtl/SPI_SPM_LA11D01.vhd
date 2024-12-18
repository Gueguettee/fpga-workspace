library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_SPM_LA11D01 is
  generic(
        SPI_CLK_DIVIDER     : integer := 18;
        DATA_LENGTH         : integer := 28
   );
   port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        start_i             : in std_logic;
        
        data_o              : out std_logic_vector(DATA_LENGTH-1 downto 0);
        
        MISO_i              : in std_logic;
        SCK_o               : out std_logic;
        CSB_o               : out std_logic
	);
end SPI_SPM_LA11D01;

architecture mix of SPI_SPM_LA11D01 is

--------------------------- SIGNALS ---------------------------
    
    signal SCK_s                : std_logic := '0';
    signal reset_counter_s      : unsigned(9 downto 0);
    signal startread_counter_s  : unsigned(9 downto 0);
    signal data_counter_s       : unsigned(9 downto 0);
    signal clk_counter_s        : unsigned(9 downto 0);
    signal data_s               : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal done_data_S          : std_logic := '0';
    signal endread_counter_s    : unsigned(9 downto 0);
    signal start_s              : std_logic;
    
    type spi_state_t is (
        IDLE,
        START_READ,
        READ,
        END_READ);
    signal spi_state_s      : spi_state_t;
 
begin

--------------------------- DESIGN ----------------------------

SCK_o <= SCK_s;
    
    SPI_READ_process : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                reset_counter_s     <= to_unsigned(10,10);
                startread_counter_s <= to_unsigned(10,10);
                data_counter_s      <= to_unsigned(DATA_LENGTH-1,10);
                clk_counter_s       <= to_unsigned(0, 10);
                endread_counter_s   <= to_unsigned(10,10);
           
                data_s              <= (others => '0');
                start_s             <= '0';
                
                SCK_s               <= '0';
                CSB_o               <= '1';
                done_data_s         <= '0';
                spi_state_s         <= IDLE;
            else
                done_data_s         <= '0';
                
                if start_i = '1' then
                    start_s <= '1';
                end if;
                
                case spi_state_s is
                    when IDLE =>
                        
                        startread_counter_s <= to_unsigned(10,10);
                        data_counter_s      <= to_unsigned(DATA_LENGTH-1,10);
                        endread_counter_s   <= to_unsigned(10,10);
                        
                        if start_s = '1' then
                            if clk_counter_s = to_unsigned(SPI_CLK_DIVIDER-1, 10) then
                                if reset_counter_s = to_unsigned(0,1) then
                                    spi_state_s     <= START_READ;
                                    CSB_o           <= '0';
                                    start_s         <= '0';
                                else
                                    reset_counter_s <= reset_counter_s - 1;
                                end if;
                                clk_counter_s   <= (others => '0');
                            else
                                clk_counter_s   <= clk_counter_s + 1;
                            end if;
                        end if;

                    when START_READ =>
                        
                        if clk_counter_s = to_unsigned(SPI_CLK_DIVIDER-1, 10) then
                            clk_counter_s   <= (others => '0');
                            
                            if startread_counter_s = to_unsigned(0,1) then
                                SCK_s           <= not SCK_s;
                                spi_state_s     <= READ;
                            else
                                startread_counter_s <= startread_counter_s - 1;
                            end if;
                        else
                            clk_counter_s   <= clk_counter_s + 1;
                        end if;
                                               
                    when READ =>
                      
                        DATA_s(to_integer(DATA_counter_s)) <= MISO_i;
                                            
                        if clk_counter_s = to_unsigned(SPI_CLK_DIVIDER-1, 10) then
                            clk_counter_s <= (others => '0');
                            
                            if done_data_s = '0' then -- if read cycle is not done yet toggle clock
                                SCK_s <= not SCK_s;
                            end if;
                            
                            if SCK_s = '0' then -- falling edge of SCK_s
                            
                                if data_counter_s = to_unsigned(0, 10) then --last bit reached
                                    done_data_s     <= '1';
                                    SCK_s           <= '0';
                                    spi_state_s     <= END_READ;
                                else
                                    data_counter_s <= data_counter_s - 1;
                                end if;
                            end if;
                        else
                            clk_counter_s <= clk_counter_s + 1;
                        end if;
                        
                    when END_READ =>
                        data_o  <= data_s;
                        if clk_counter_s = to_unsigned(SPI_CLK_DIVIDER-1, 10) then
                            clk_counter_s <= (others => '0');
                            
                            if endread_counter_s = to_unsigned(0,1) then
                                CSB_o           <= '1';
                                reset_counter_s <= to_unsigned(10,10);
                                spi_state_s     <= IDLE;
                            else
                                endread_counter_s   <= endread_counter_s - 1;
                            end if;
                        else
                            clk_counter_s <= clk_counter_s + 1;
                        end if;
                        
                    when others =>
                        CSB_o           <= '0';
                        SCK_S           <= '0';
                        clk_counter_s   <= (others => '0');
                        spi_state_s     <= IDLE;
                
                end case;
            end if;
        end if;
    end process;
end mix;