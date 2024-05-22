library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tp1_picoblaze_pkg.all;

entity tp1_picoblaze_top is
	port (
			clk_i : in std_logic;
			reset_i : in std_logic;

			port1_i : in std_logic_vector(cIN_NB-1 downto 0);

			port1_o : out std_logic_vector(cOUT_NB-1 downto 0)
	);
end entity tp1_picoblaze_top;

architecture Behavioral of tp1_picoblaze_top is

    signal registers_o_s : tRegister := (others => (others => '0'));
    signal registers_i_s : tRegister := (others => (others => '0'));

    signal clk_s : std_logic;
    signal port1_i_s : std_logic_vector(cIN_NB-1 downto 0);
    signal port1_o_s : std_logic_vector(cOUT_NB-1 downto 0);

    signal address : std_logic_vector(11 downto 0);
    signal instruction : std_logic_vector(17 downto 0);
    signal bram_enable : std_logic;
    signal in_port : std_logic_vector(7 downto 0);
    signal out_port : std_logic_vector(7 downto 0);
    Signal port_id : std_logic_vector(7 downto 0);
    Signal write_strobe : std_logic;
    Signal k_write_strobe : std_logic;
    Signal read_strobe : std_logic;
    Signal interrupt : std_logic;
    Signal interrupt_ack : std_logic;
    Signal kcpsm6_sleep : std_logic;

begin

    clk_s <= clk_i;

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
            clk => clk_s
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
            clk => clk_s
        );
    
    output_ports: process(clk_s)
    begin
        if clk_s'event and clk_s = '1' then
            if reset_i = '1' then
                registers_o_s <= (others => (others => '0'));
            else
                if write_strobe = '1' then
                    registers_o_s(to_integer(unsigned(port_id))) <= out_port;
                end if;
            end if;
        end if;
    end process output_ports;

    input_ports: process(clk_s)
    begin
        if clk_s'event and clk_s = '1' then
            if reset_i = '1' then
                in_port <= (others => '0');
            else
                in_port <= registers_i_s(to_integer(unsigned(port_id)));
            end if;
        end if;
    end process input_ports;

    port1_o <= registers_o_s(1);
    registers_i_s(1) <= port1_i;

end architecture Behavioral;
