library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;

entity data_flow is
    port(
        en_i: in std_logic;
        rst_i: in std_logic;
        clk_i: in std_logic;
        shift_o: out std_logic;
        enSIPO_o: out std_logic;
        enPISO_o: out std_logic
    );
end entity;

architecture mix of data_flow is
    constant DATA_BUS_WIDTH_c : integer := 8;

    type FSM_states_t is (
        IDLE,
        RUNNING,
        SHIFT,
        RESET
    );
    signal current_state_s : FSM_states_t;

    signal shift_s : std_logic;
    signal enSIPO_s : std_logic;
    signal enPISO_s : std_logic;
    signal cnt_s : std_logic;

    component cnt is
		port (
			clk_i: in std_logic;
            rst_i: in std_logic;
            cnt_finish_o: out std_logic
		);
	end component;

    begin
        enSIPO_o <= enSIPO_s;
        enPISO_o <= enPISO_s;

        shift_o <= shift_s;

        comp1: cnt
            port map (
            --  bloc => TL
                clk_i => clk_i,
                rst_i => rst_i,
                cnt_finish_o => cnt_s
            );

        reg: process(clk_i, rst_i, cnt_s)
        begin
            if (rst_i = '0') then
                current_state_s <= RESET;
            else
                if rising_edge(clk_i) then
                    case current_state_s is
                        when IDLE =>
                            if (en_i = '1') then
                                current_state_s <= RUNNING;
                            end if;
                        when RUNNING =>
                            if (en_i = '0') then
                                current_state_s <= IDLE;
                            elsif (cnt_s = '1') then
                                current_state_s <= SHIFT;
                            end if;
                        when SHIFT =>
                            if (en_i = '0') then
                                current_state_s <= IDLE;
                            else
                                current_state_s <= RUNNING;
                            end if;
                        when RESET =>
                            if (rst_i = '1') then
                                current_state_s <= RUNNING;
                            end if;
                    end case;
                end if;
            end if;
        end process;

        output_logic: process(current_state_s)
        begin
            case current_state_s is
                when IDLE =>             
                    enSIPO_s <= '0';
                    enPISO_s <= '0';
                when RUNNING =>
                    shift_s <= '0';
                    enSIPO_s <= '1';
                    enPISO_s <= '1';
                when SHIFT =>
                    shift_s <= '1';
                when RESET =>
                    shift_s <= '0';
                    enSIPO_s <= '0';
                    enPISO_s <= '0';
            end case;
        end process;
end architecture;
