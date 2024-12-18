library ieee;
use ieee.std_logic_1164.all;

-- Memory Control FSM
entity MemCTRL is
	port
	(
		clk_i :		in std_logic;
		rst_i :		in std_logic;
		en_i :		in std_logic;
		rw_i :		in std_logic;
		ready_i :	in std_logic;
		re_o :		out std_logic;
		we_o :		out std_logic
);
end entity MemCTRL;


architecture behavioral of MemCTRL is

	type FSM_states is
	(
		--CMD states
		RST, IDLE, ENABLE,
		--WR states
		WR_DATA,
		--RD states
		RD_DATA
	);


	signal next_state_s, current_state_s : FSM_states;

begin
	-- Next state logic ; Comb
	next_state_logic: process(current_state_s, en_i, rw_i, ready_i)
	begin
		case current_state_s is
			when RST =>
				next_state_s <= IDLE;
				
			when IDLE =>
				if en_i = '1' then
					next_state_s <= ENABLE;
				else
					next_state_s <= IDLE;
				end if;
				
			when ENABLE =>
				if rw_i = '1' then
					next_state_s <= RD_DATA;
				else
					next_state_s <= WR_DATA;
				end if;
				
			when RD_DATA =>
				if ready_i = '1' then
					next_state_s <= IDLE;
				else
					next_state_s <= RD_DATA;
				end if;
				
			when WR_DATA =>
				if ready_i = '1' then
					next_state_s <= IDLE;
				else
					next_state_s <= WR_DATA;
				end if;
				
			when others =>
				next_state_s <= RST;
		end case;
	end process;


	-- Current state logic ; Sync + Comb
	current_state: process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			current_state_s <= RST;
		elsif rising_edge(clk_i) then
			current_state_s <= next_state_s;
		end if;
	end process;
	
	
	output_logic: process(current_state_s)
	begin
		case current_state_s is
			when RST =>
				re_o <= '0';
				we_o <= '0';
			when IDLE =>
				re_o <= '0';
				we_o <= '0';
			when ENABLE =>
				re_o <= '0';
				we_o <= '0';
			when WR_DATA =>
				re_o <= '0';
				we_o <= '1';
			when RD_DATA =>
				re_o <= '1';
				we_o <= '0';
			when others =>
				re_o <= '0';
				we_o <= '0';
		end case;
	end process;
	
end architecture behavioral;


