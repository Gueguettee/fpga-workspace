library ieee;
use ieee.std_logic_1164.all;
--use work.my_pkg.all;

entity TL is
	port
	(
		en_i : in std_logic;
        rst_i : in std_logic;
        clk_i : in std_logic;
        sw_i : in std_logic_vector(8-1 downto 0);
        led_o : out std_logic_vector(8-1 downto 0);
        --ser_o : out std_logic;
        ser_i : in std_logic--;
        --clk_pll_o : out std_logic
	);
end entity TL;

architecture structural of TL is

    constant DATA_BUS_WIDTH_c : integer := 8;

	signal clk_s : std_logic;
    signal rst_s : std_logic;
    signal rst_i_s : std_logic;
    signal shift_s : std_logic;
    signal enSIPO_s : std_logic;
    signal enPISO_s : std_logic;
    signal ser_s : std_logic;
	
	component SIPO_shift_reg is
		port (
			clk_i : in std_logic;
            rst_i : in std_logic;
            shift_i : in std_logic;
            en_i : in std_logic;
            data_i : in std_logic;
            data_o : out std_logic_vector(DATA_BUS_WIDTH_c-1 downto 0)
		);
	end component;
	
	component PISO_shift_reg is
		port (
			clk_i : in std_logic;
            rst_i : in std_logic;
            shift_i : in std_logic;
            en_i : in std_logic;
            data_i : in std_logic_vector(DATA_BUS_WIDTH_c-1 downto 0);
            data_o : out std_logic
		);
	end component;

    component data_flow is
		port (
			en_i: in std_logic;
            rst_i: in std_logic;
            clk_i: in std_logic;
            shift_o: out std_logic;
            enSIPO_o: out std_logic;
            enPISO_o: out std_logic
		);
	end component;

    component Int_PLL
        port(-- Clock in ports
            -- Clock out ports
            clk_o          : out    std_logic;
            clk_o_180          : out    std_logic;
            -- Status and control signals
            resetn             : in     std_logic;
            locked            : out    std_logic;
            clk_i           : in     std_logic
        );
    end component;
	
	begin
        --ser_o <= ser_s;
        --clk_pll_o <= clk_s;
        rst_i_s <= not rst_i;

        comp1 : SIPO_shift_reg
            port map (
            --  bloc => TL
                clk_i => clk_s,
                rst_i => rst_s,
                shift_i => shift_s,
                en_i => enSIPO_s,
                data_i => ser_s,
                data_o => led_o
            );
            
        comp2 : PISO_shift_reg
            port map (
            --  bloc => TL
                clk_i => clk_s,
                rst_i => rst_s,
                shift_i => shift_s,
                en_i => enPISO_s,
                data_i => sw_i,
                data_o => ser_s
            );

        comp3 : data_flow
            port map (
            --  bloc => TL
                en_i => en_i,
                clk_i => clk_s,
                rst_i => rst_s,
                shift_o => shift_s,
                enSIPO_o => enSIPO_s,
                enPISO_o => enPISO_s
            );

        comp4 : Int_PLL
            port map ( 
           -- Clock out ports  
                clk_o => clk_s,
                --clk_o_180 => clk_s_180,
            -- Status and control signals                
                resetn => rst_i_s,
                locked => rst_s,
                -- Clock in ports
                clk_i => clk_i
          );

end architecture;