library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tp1_picoblaze_pkg.all;

entity tp1_picoblaze_top is
port (
    clk_i : in std_logic;
    reset_i : in std_logic;
    
    port1_i : in std_logic_vector(cIN_NB-1 downto 0);
    rx_i : in std_logic;
    
    port1_o : out std_logic_vector(cOUT_NB-1 downto 0);
    tx_o : out std_logic
);
end entity tp1_picoblaze_top;

architecture mix of tp1_picoblaze_top is

    signal registers_o_s : tRegister := (others => (others => '0'));
    signal registers_i_s : tRegister := (others => (others => '0'));
    
    signal test_port_id_s : std_logic;
    signal rd_uart_s : std_logic;
    signal wr_uart_s : std_logic;

    signal address : std_logic_vector(11 downto 0);
    signal instruction : std_logic_vector(17 downto 0);
    signal bram_enable : std_logic;
    signal in_port : std_logic_vector(cIN_NB-1 downto 0);
    signal out_port : std_logic_vector(cOUT_NB-1 downto 0);
    Signal port_id : std_logic_vector(cREG_SEL_SIZE-1 downto 0);
    Signal write_strobe : std_logic;
    Signal k_write_strobe : std_logic;
    Signal read_strobe : std_logic;
    Signal interrupt : std_logic;
    Signal interrupt_ack : std_logic;
    Signal kcpsm6_sleep : std_logic;

begin

    processor: kcpsm6
        generic map ( hwbuild => X"00",
            interrupt_vector => X"3FF",
            scratch_pad_memory_size => 64
        )
        port map( address => address,
            instruction => instruction,
            bram_enable => bram_enable,
            port_id => port_id,
            write_strobe => write_strobe,
            k_write_strobe => k_write_strobe,
            out_port => out_port,
            read_strobe => read_strobe,
            in_port => in_port,
            interrupt => interrupt,
            interrupt_ack => interrupt_ack,
            sleep => kcpsm6_sleep,
            reset => reset_i,
            clk => clk_i
        );

    kcpsm6_sleep <= '0';
    interrupt <= '0';

    rogram_rom: tp1_program
        generic map( C_FAMILY => "7S",
            C_RAM_SIZE_KWORDS => 2,
            C_JTAG_LOADER_ENABLE => 0
        )
        port map( address => address,
            instruction => instruction,
            enable => bram_enable,
            rdl => open,
            clk => clk_i
        );
    
    output_ports: process(clk_i)
    begin
        if clk_i'event and clk_i = '1' then
            if reset_i = '1' then
                wr_uart_s <= '0';
                registers_o_s <= (others => (others => '0'));
            else
                wr_uart_s <= '0';
                if write_strobe = '1' then
                    registers_o_s(to_integer(unsigned(port_id))) <= out_port;
                    if port_id = std_logic_vector(to_unsigned(cPORT_ID_UART, cREG_SEL_SIZE)) then
                        wr_uart_s <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process output_ports;

    input_ports: process(clk_i)
    begin
        if clk_i'event and clk_i = '1' then
            if reset_i = '1' then
                in_port <= (others => '0');
            else
                in_port <= registers_i_s(to_integer(unsigned(port_id)));
            end if;
        end if;
    end process input_ports;

    port1_o <= registers_o_s(1);
    registers_i_s(1) <= port1_i;
    
    test_port_id_s <= '1' when port_id = std_logic_vector(to_unsigned(cPORT_ID_UART, cREG_SEL_SIZE)) else '0';
    rd_uart_s <= read_strobe and test_port_id_s;

    uart_component: uart
        generic map(
            -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop bits, 2^3 FIFO
            DBIT => 8,      -- # data bits
            SB_TICK => 16,  -- # ticks for stop bits, 16/24/32
                                --   for 1/1.5/2 stop bits
            DVSR => 326,    -- baud rate divisor
                                -- DVSR = 100M/(16*baud rate)
            DVSR_BIT => 9,  -- # bits of DVSR
            FIFO_W => 3     -- # addr bits of FIFO
                                -- # words in FIFO=2^FIFO_W
        )
        port map(
            clk => clk_i,
            reset => reset_i,
            rd_uart =>rd_uart_s,
            wr_uart => wr_uart_s,
            rx => rx_i,
            w_data => registers_o_s(cPORT_ID_UART),
            tx_full => registers_i_s(cREG_FLAGS)(1),
            rx_empty => registers_i_s(cREG_FLAGS)(0),
            r_data => registers_i_s(cPORT_ID_UART),
            tx => tx_o
        );

end architecture mix;
