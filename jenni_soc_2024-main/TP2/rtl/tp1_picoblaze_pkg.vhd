library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tp1_picoblaze_pkg is

	constant cIN_NB : integer := 8;
    constant cOUT_NB : integer := cIN_NB;

    constant cREG_SEL_SIZE : integer := 8;
    constant cREG_NB : integer := 2**cREG_SEL_SIZE;

    constant cREG_FLAGS : integer := 4;

    constant cPORT_ID_UART : integer := 2;
    
    type tRegister is array (0 to cREG_NB-1) of std_logic_vector(cIN_NB-1 downto 0);

	component kcpsm6
    generic( hwbuild : std_logic_vector(7 downto 0) := X"00";
            interrupt_vector : std_logic_vector(11 downto 0) := X"3FF";
            scratch_pad_memory_size : integer := 64
    );
    port ( address : out std_logic_vector(11 downto 0);
            instruction : in std_logic_vector(17 downto 0);
            bram_enable : out std_logic;
            in_port : in std_logic_vector(7 downto 0);
            out_port : out std_logic_vector(7 downto 0);
            port_id : out std_logic_vector(7 downto 0);
            write_strobe : out std_logic;
            k_write_strobe : out std_logic;
            read_strobe : out std_logic;
            interrupt : in std_logic;
            interrupt_ack : out std_logic;
            sleep : in std_logic;
            reset : in std_logic;
            clk : in std_logic
    );
    end component;

    component tp1_program
    generic( C_FAMILY : string := "S6";
        C_RAM_SIZE_KWORDS : integer := 1;
        C_JTAG_LOADER_ENABLE : integer := 0
    );
    Port ( address : in std_logic_vector(11 downto 0);
        instruction : out std_logic_vector(17 downto 0);
        enable : in std_logic;
        rdl : out std_logic;
        clk : in std_logic
    );
    end component;

    component uart
    generic(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT: integer:=8;     -- # data bits
        SB_TICK: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT: integer:=8; -- # bits of DVSR
        FIFO_W: integer:=2    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
     );
    port(
        clk, reset: in std_logic;
        rd_uart, wr_uart: in std_logic;
        rx: in std_logic;
        w_data: in std_logic_vector(7 downto 0);
        tx_full, rx_empty: out std_logic;
        r_data: out std_logic_vector(7 downto 0);
        tx: out std_logic
    );
    end component;

    component tp1_picoblaze_top is
        port (
            clk_i : in std_logic;
            reset_i : in std_logic;
            
            port1_i : in std_logic_vector(cIN_NB-1 downto 0);
            rx_i : in std_logic;
            
            port1_o : out std_logic_vector(cOUT_NB-1 downto 0);
            tx_o : out std_logic
        );
    end component tp1_picoblaze_top;

end tp1_picoblaze_pkg;

package body tp1_picoblaze_pkg is
 
end tp1_picoblaze_pkg;
