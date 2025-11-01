LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.SPI_synth_pkg.all;
use work.main_control_pkg.all;
use work.TL_VNAMI_MAIN_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity SPI_synth_seq_mem is
    generic(
        RF_LO               : RF_LO_t := RF;
        SYNTHESIZER         : synthesizer_t := LMX2594
    );
    port(
        clk_i               : in std_logic;
        reset_i             : in std_logic;
        
        seq_id_i            : in seq_id_t;
        freq_para_i         : in freq_para_t;
        power_i             : in power_t;
        
        spi_seq_i           : in spi_seq_i_t;
        spi_seq_o           : out spi_seq_o_t;

        vco_i               : in vco_t;
        vco_o               : out vco_t
	);
end entity SPI_synth_seq_mem;

architecture mix of SPI_synth_seq_mem is
    
--------------------------- SIGNALS ---------------------------
    
    type spi_seq_arr_o_t is array (31 downto 0) of spi_seq_o_t;
    signal LMX2572_spi_seq_arr_o_s    : spi_seq_arr_o_t;
    signal LMX2594_spi_seq_arr_o_s    : spi_seq_arr_o_t;
    signal spi_seq_arr_o_s      : spi_seq_arr_o_t;
    
    type spi_seq_arr_i_t is array (31 downto 0) of spi_seq_i_t;
    signal spi_seq_arr_i_s    : spi_seq_arr_i_t;
    
    signal POWERA_REG_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal POWERB_REG_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal R46_REG_s        : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal VCO_SEL_REG_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal VCO_CAPCTRL_REG_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal VCO_DACISET_REG_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal vco_sel_reg_i_s      : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal vco_daciset_reg_i_s  : std_logic_vector(DATA_LENGTH-1 downto 0);
    signal vco_capctrl_reg_i_s  : std_logic_vector(DATA_LENGTH-1 downto 0);
  
-------------------------- COMPONENTS -------------------------

begin
--------------------------- DESIGN ----------------------------

    spi_seq_arr_o_s <= LMX2572_spi_seq_arr_o_s when SYNTHESIZER = LMX2572 else LMX2594_spi_seq_arr_o_s;
    
    vco_o.sel <= vco_sel_reg_i_s(7 downto 5);
    vco_o.capctrl <= vco_capctrl_reg_i_s(7 downto 0);
    vco_o.daciset <= vco_daciset_reg_i_s(8 downto 0);

    process(reset_i, power_i, vco_i, seq_id_i, spi_seq_i, freq_para_i)
    begin
        if SYNTHESIZER = LMX2572 then
            POWERA_REG_s <= x"0022";
            POWERB_REG_s <= x"C600";
            VCO_SEL_REG_s <= x"7048";
            R46_REG_s <= x"07F0";
        else
            POWERA_REG_s <= x"0023";
            POWERB_REG_s <= x"C0DF";
            VCO_SEL_REG_s <= x"F048";
            R46_REG_s <= x"07FD";
        end if;
        VCO_CAPCTRL_REG_s <= x"27B7";
        VCO_DACISET_REG_s <= x"0080";

        if reset_i = '1' then
            POWERA_REG_s(13 downto 8) <= (others => '0');
            POWERB_REG_s(5 downto 0) <= (others => '0');
            POWERA_REG_s(6) <= '1';  -- OUTA_PD
            POWERA_REG_s(7) <= '1';  -- OUTB_PD
            POWERB_REG_s(12 downto 11) <= "11"; -- OUTA_MUX at high impedance
            R46_REG_s(1 downto 0) <= "11"; -- OUTB_MUX at high impedance
        else
            POWERA_REG_s(6) <= '0';  -- OUTA_PD
            POWERA_REG_s(7) <= '0';  -- OUTB_PD
            POWERA_REG_s(13 downto 8) <= power_i;
            POWERB_REG_s(5 downto 0) <= power_i;
            POWERB_REG_s(12 downto 11) <= freq_para_i.OUTA_MUX_s(12 downto 11);
            R46_REG_s(1 downto 0) <= freq_para_i.OUTB_MUX_s(1 downto 0);
            if RF_LO = RF then
                POWERA_REG_s(7) <= '1';  -- OUTB_PD, mute if RF
                POWERB_REG_s(5 downto 0) <= (others => '0'); -- OUTB_PWR at minimum if RF
                R46_REG_s(1 downto 0) <= "11"; -- OUTB_MUX at high impedance if RF
            end if;
            VCO_SEL_REG_s(10) <= '1';
            VCO_SEL_REG_s(13 downto 11) <= vco_i.sel;
            VCO_CAPCTRL_REG_s(7 downto 0) <= vco_i.capctrl;
            VCO_DACISET_REG_s(8 downto 0) <= vco_i.daciset;
        end if;
    end process;

    spi_seq_o.nbr_of_cmds_s <= spi_seq_arr_o_s(seq_id_i).nbr_of_cmds_s;
    spi_seq_o.RW_s <= spi_seq_arr_o_s(seq_id_i).RW_s;
    spi_seq_o.addr_s <= spi_seq_arr_o_s(seq_id_i).addr_s;
    spi_seq_o.data_o_s <= spi_seq_arr_o_s(seq_id_i).data_o_s;

    --START_UP_SEQUENCE
    LMX2572_spi_seq_arr_o_s(SEQ_ID_INIT).nbr_of_cmds_s    <= to_unsigned(20,NBR_OF_CMD_LENGHT);
    LMX2572_spi_seq_arr_o_s(SEQ_ID_INIT).RW_s             <= (others  => '0');
    LMX2572_spi_seq_arr_o_s(SEQ_ID_INIT).addr_s           <= (
        0       => std_logic_vector(to_unsigned(0,7)),
        1       => std_logic_vector(to_unsigned(78,7)),
        2       => std_logic_vector(to_unsigned(75,7)),
        3       => std_logic_vector(to_unsigned(71,7)),
        4       => std_logic_vector(to_unsigned(60,7)),
        5       => std_logic_vector(to_unsigned(59,7)), -- Vtune detect
        6       => std_logic_vector(to_unsigned(57,7)),
        7       => std_logic_vector(to_unsigned(52,7)),
        8       => std_logic_vector(to_unsigned(46,7)),
        9       => std_logic_vector(to_unsigned(45,7)),
        10      => std_logic_vector(to_unsigned(44,7)), -- OUTPUT POWER
        11      => std_logic_vector(to_unsigned(43,7)),
        12      => std_logic_vector(to_unsigned(42,7)),
        13      => std_logic_vector(to_unsigned(39,7)),
        14      => std_logic_vector(to_unsigned(38,7)),
        15      => std_logic_vector(to_unsigned(37,7)),
        16      => std_logic_vector(to_unsigned(36,7)),
        17      => std_logic_vector(to_unsigned(30,7)),
        18      => std_logic_vector(to_unsigned(29,7)),
        19      => std_logic_vector(to_unsigned(0,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2572_spi_seq_arr_o_s(SEQ_ID_INIT).data_o_s             <= (
        0       => x"211E",
        1       => x"0065",
        2       => freq_para_i.CHDIV_s,
        3       => x"0081",
        4       => x"0000",
        5       => x"0001", -- to turn off Vtune lock detect -> 0000 -> TODO to test
        6       => x"0020",
        7       => x"0421",
        8       => R46_REG_s,
        9       => POWERB_REG_s,
        10      => POWERA_REG_s,
        11      => freq_para_i.PLL_NUM_s(15 downto 0),
        12      => x"0000",
        13      => freq_para_i.PLL_DEN_s(15 downto 0),
        14      => x"0000",
        15      => freq_para_i.PFD_DLY_SEL_s,
        16      => freq_para_i.PLL_N_s,
        17      => x"18A6",
        18      => x"0000",
        19      => x"211C",
        others  => x"0000");
    
    LMX2594_spi_seq_arr_o_s(SEQ_ID_INIT).nbr_of_cmds_s    <= to_unsigned(82,NBR_OF_CMD_LENGHT);
    LMX2594_spi_seq_arr_o_s(SEQ_ID_INIT).RW_s             <= (others  => '0');
    LMX2594_spi_seq_arr_o_s(SEQ_ID_INIT).addr_s <= (
        0  => std_logic_vector(to_unsigned(0, 7)),  -- Reset
        1  => std_logic_vector(to_unsigned(0, 7)),  -- Stop reset
        2  => std_logic_vector(to_unsigned(78, 7)),
        3  => std_logic_vector(to_unsigned(77, 7)),
        4  => std_logic_vector(to_unsigned(76, 7)),
        5  => std_logic_vector(to_unsigned(75, 7)),
        6  => std_logic_vector(to_unsigned(74, 7)),
        7  => std_logic_vector(to_unsigned(73, 7)),
        8  => std_logic_vector(to_unsigned(72, 7)),
        9  => std_logic_vector(to_unsigned(71, 7)),
        10 => std_logic_vector(to_unsigned(70, 7)),
        11 => std_logic_vector(to_unsigned(69, 7)),
        12 => std_logic_vector(to_unsigned(68, 7)),
        13 => std_logic_vector(to_unsigned(67, 7)),
        14 => std_logic_vector(to_unsigned(66, 7)),
        15 => std_logic_vector(to_unsigned(65, 7)),
        16 => std_logic_vector(to_unsigned(64, 7)),
        17 => std_logic_vector(to_unsigned(63, 7)),
        18 => std_logic_vector(to_unsigned(62, 7)),
        19 => std_logic_vector(to_unsigned(61, 7)),
        20 => std_logic_vector(to_unsigned(60, 7)),
        21 => std_logic_vector(to_unsigned(59, 7)),
        22 => std_logic_vector(to_unsigned(58, 7)),
        23 => std_logic_vector(to_unsigned(57, 7)),
        24 => std_logic_vector(to_unsigned(56, 7)),
        25 => std_logic_vector(to_unsigned(55, 7)),
        26 => std_logic_vector(to_unsigned(54, 7)),
        27 => std_logic_vector(to_unsigned(53, 7)),
        28 => std_logic_vector(to_unsigned(52, 7)),
        29 => std_logic_vector(to_unsigned(51, 7)),
        30 => std_logic_vector(to_unsigned(50, 7)),
        31 => std_logic_vector(to_unsigned(49, 7)),
        32 => std_logic_vector(to_unsigned(48, 7)),
        33 => std_logic_vector(to_unsigned(47, 7)),
        34 => std_logic_vector(to_unsigned(46, 7)),
        35 => std_logic_vector(to_unsigned(45, 7)),
        36 => std_logic_vector(to_unsigned(44, 7)),
        37 => std_logic_vector(to_unsigned(43, 7)),
        38 => std_logic_vector(to_unsigned(42, 7)),
        39 => std_logic_vector(to_unsigned(41, 7)),
        40 => std_logic_vector(to_unsigned(40, 7)),
        41 => std_logic_vector(to_unsigned(39, 7)),
        42 => std_logic_vector(to_unsigned(38, 7)),
        43 => std_logic_vector(to_unsigned(37, 7)),
        44 => std_logic_vector(to_unsigned(36, 7)),
        45 => std_logic_vector(to_unsigned(35, 7)),
        46 => std_logic_vector(to_unsigned(34, 7)),
        47 => std_logic_vector(to_unsigned(33, 7)),
        48 => std_logic_vector(to_unsigned(32, 7)),
        49 => std_logic_vector(to_unsigned(31, 7)),
        50 => std_logic_vector(to_unsigned(30, 7)),
        51 => std_logic_vector(to_unsigned(29, 7)),
        52 => std_logic_vector(to_unsigned(28, 7)),
        53 => std_logic_vector(to_unsigned(27, 7)),
        54 => std_logic_vector(to_unsigned(26, 7)),
        55 => std_logic_vector(to_unsigned(25, 7)),
        56 => std_logic_vector(to_unsigned(24, 7)),
        57 => std_logic_vector(to_unsigned(23, 7)),
        58 => std_logic_vector(to_unsigned(22, 7)),
        59 => std_logic_vector(to_unsigned(21, 7)),
        60 => std_logic_vector(to_unsigned(20, 7)),
        61 => std_logic_vector(to_unsigned(19, 7)),
        62 => std_logic_vector(to_unsigned(18, 7)),
        63 => std_logic_vector(to_unsigned(17, 7)),
        64 => std_logic_vector(to_unsigned(16, 7)),
        65 => std_logic_vector(to_unsigned(15, 7)),
        66 => std_logic_vector(to_unsigned(14, 7)),
        67 => std_logic_vector(to_unsigned(13, 7)),
        68 => std_logic_vector(to_unsigned(12, 7)),
        69 => std_logic_vector(to_unsigned(11, 7)),
        70 => std_logic_vector(to_unsigned(10, 7)),
        71 => std_logic_vector(to_unsigned(9, 7)),
        72 => std_logic_vector(to_unsigned(8, 7)),
        73 => std_logic_vector(to_unsigned(7, 7)),
        74 => std_logic_vector(to_unsigned(6, 7)),
        75 => std_logic_vector(to_unsigned(5, 7)),
        76 => std_logic_vector(to_unsigned(4, 7)),
        77 => std_logic_vector(to_unsigned(3, 7)),
        78 => std_logic_vector(to_unsigned(2, 7)),
        79 => std_logic_vector(to_unsigned(1, 7)),
        80 => std_logic_vector(to_unsigned(0, 7)),
        81 => std_logic_vector(to_unsigned(0, 7)),
        others => std_logic_vector(to_unsigned(0, 7))
    );
    LMX2594_spi_seq_arr_o_s(SEQ_ID_INIT).data_o_s <= (
        0       => x"251E",  -- Reset
        1       => x"2514",  -- Turn off reset
        2       => x"0003",  -- R78
        3       => x"0000",  -- R77
        4       => x"000C",  -- R76
        5       => freq_para_i.CHDIV_s,  -- R75
        6       => x"0000",  -- R74
        7       => x"003F",  -- R73
        8       => x"0001",  -- R72
        9       => x"0081",  -- R71
        10      => x"C350",  -- R70
        11      => x"0000",  -- R69
        12      => x"03E8",  -- R68
        13      => x"0000",  -- R67
        14      => x"01F4",  -- R66
        15      => x"0000",  -- R65
        16      => x"1388",  -- R64
        17      => x"0000",  -- R63
        18      => x"0322",  -- R62
        19      => x"00A8",  -- R61
        20      => x"0000",  -- R60
        21      => x"0001",  -- R59 --TODO test at 0 (without VTUNE)
        22      => x"9001",  -- R58
        23      => x"0020",  -- R57
        24      => x"0000",  -- R56
        25      => x"0000",  -- R55
        26      => x"0000",  -- R54
        27      => x"0000",  -- R53
        28      => x"0820",  -- R52
        29      => x"0080",  -- R51
        30      => x"0000",  -- R50
        31      => x"4180",  -- R49
        32      => x"0300",  -- R48
        33      => x"0300",  -- R47
        34      => R46_REG_s,  -- R46
        35      => POWERB_REG_s,  -- R45
        36      => POWERA_REG_s,  -- R44
        37      => freq_para_i.PLL_NUM_s(15 downto 0),  -- R43
        38      => x"0000",  -- R42
        39      => x"0000",  -- R41
        40      => x"0000",  -- R40
        41      => freq_para_i.PLL_DEN_s(15 downto 0),  -- R39
        42      => x"0000",  -- R38
        43      => freq_para_i.PFD_DLY_SEL_s,  -- R37
        44      => freq_para_i.PLL_N_s,  -- R36
        45      => x"0004",  -- R35
        46      => x"0000",  -- R34
        47      => x"1E21",  -- R33
        48      => x"0393",  -- R32
        49      => x"43EC",  -- R31
        50      => x"318C",  -- R30
        51      => x"318C",  -- R29
        52      => x"0488",  -- R28
        53      => x"0002",  -- R27
        54      => x"0DB0",  -- R26
        55      => x"0C2B",  -- R25
        56      => x"071A",  -- R24
        57      => x"007C",  -- R23
        58      => x"0001",  -- R22
        59      => x"0401",  -- R21
        60      => x"E048",  -- R20
        61      => x"27B7",  -- R19
        62      => x"0064",  -- R18
        63      => x"012C",  -- R17
        64      => x"0080",  -- R16
        65      => x"064F",  -- R15
        66      => x"1E70",  -- R14
        67      => x"4000",  -- R13
        68      => x"5001",  -- R12
        69      => x"0018",  -- R11
        70      => x"10D8",  -- R10
        71      => x"1604",  -- R9
        72      => x"2000",  -- R8
        73      => x"40B2",  -- R7
        74      => x"C802",  -- R6
        75      => x"00C8",  -- R5
        76      => x"0A43",  -- R4
        77      => x"0642",  -- R3
        78      => x"0500",  -- R2
        79      => x"0808",  -- R1
        80      => x"2514",  -- R0
        81      => x"251C",  -- R0
        others  => x"0000"
    );
        
    --Setting frequency sequence
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).nbr_of_cmds_s    <= to_unsigned(12,NBR_OF_CMD_LENGHT);
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).RW_s             <= (
        0       => '0',
        1       => '0',
        2       => '0',
        3       => '0',
        4       => '0',
        5       => '0',
        6       => '0',
        7       => '0',
        8       => '0',
        9       => '0',
        10      => '0',
        11      => '1',
        others  => '0');
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).addr_s           <= (
        0       => std_logic_vector(to_unsigned(8,7)),
        1       => std_logic_vector(to_unsigned(20,7)),
        2       => std_logic_vector(to_unsigned(46,7)),
        3       => std_logic_vector(to_unsigned(45,7)),
        4       => std_logic_vector(to_unsigned(44,7)), -- OUTPUT POWER
        5       => std_logic_vector(to_unsigned(43,7)),
        6       => std_logic_vector(to_unsigned(39,7)),
        7       => std_logic_vector(to_unsigned(37,7)),
        8       => std_logic_vector(to_unsigned(36,7)),
        9       => std_logic_vector(to_unsigned(75,7)),
        10      => std_logic_vector(to_unsigned(0,7)),
        11      => std_logic_vector(to_unsigned(110,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).data_o_s             <= (
        0       => x"2000",     -- deactivation forcing VCO_CAPCTRL and VCO_DACISET
        1       => x"7048",     -- deactivation forcing VCO_SEL
        2       => R46_REG_s,
        3       => POWERB_REG_s,
        4       => POWERA_REG_s,
        5       => freq_para_i.PLL_NUM_s(15 downto 0),
        6       => freq_para_i.PLL_DEN_s(15 downto 0),
        7       => freq_para_i.PFD_DLY_SEL_s,
        8       => freq_para_i.PLL_N_s,
        9       => freq_para_i.CHDIV_s,
        10      => x"2118", --configure MUXout as serial out
        11      => x"0000",
        others  => x"0000");

    LMX2594_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).nbr_of_cmds_s    <= to_unsigned(12,NBR_OF_CMD_LENGHT);
    LMX2594_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).RW_s             <= (
        0       => '0',
        1       => '0',
        2       => '0',
        3       => '0',
        4       => '0',
        5       => '0',
        6       => '0',
        7       => '0',
        8       => '0',
        9       => '0',
        10      => '0',
        11      => '1',
        others  => '0');
    LMX2594_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).addr_s           <= (
        0       => std_logic_vector(to_unsigned(8,7)),
        1       => std_logic_vector(to_unsigned(20,7)),
        2       => std_logic_vector(to_unsigned(46,7)),
        3       => std_logic_vector(to_unsigned(45,7)),
        4       => std_logic_vector(to_unsigned(44,7)), -- OUTPUT POWER
        5       => std_logic_vector(to_unsigned(43,7)),
        6       => std_logic_vector(to_unsigned(39,7)),
        7       => std_logic_vector(to_unsigned(37,7)),
        8       => std_logic_vector(to_unsigned(36,7)),
        9       => std_logic_vector(to_unsigned(75,7)),
        10      => std_logic_vector(to_unsigned(0,7)),
        11      => std_logic_vector(to_unsigned(110,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2594_spi_seq_arr_o_s(SEQ_ID_SET_FREQ).data_o_s             <= (
        0       => x"2000",     -- deactivation forcing VCO_CAPCTRL and VCO_DACISET
        1       => x"F048",     -- deactivation forcing VCO_SEL
        2       => R46_REG_s,
        3       => POWERB_REG_s,
        4       => POWERA_REG_s,
        5       => freq_para_i.PLL_NUM_s(15 downto 0),
        6       => freq_para_i.PLL_DEN_s(15 downto 0),
        7       => freq_para_i.PFD_DLY_SEL_s,
        8       => freq_para_i.PLL_N_s,
        9       => freq_para_i.CHDIV_s,
        10      => x"2518", --configure MUXout as serial out
        11      => x"0000",
        others  => x"0000");
        
    --VCO No Assist Calibration with Calibration ReadBack (readback part)
    LMX2572_spi_seq_arr_o_s(SEQ_ID_READ_VCO).nbr_of_cmds_s    <= to_unsigned(4,NBR_OF_CMD_LENGHT);
    LMX2572_spi_seq_arr_o_s(SEQ_ID_READ_VCO).RW_s             <= (
        0       => '1',
        1       => '1',
        2       => '1',
        3       => '0',
        others  => '0');
    LMX2572_spi_seq_arr_o_s(SEQ_ID_READ_VCO).addr_s           <= (
        0       => std_logic_vector(to_unsigned(110,7)),
        1       => std_logic_vector(to_unsigned(111,7)),
        2       => std_logic_vector(to_unsigned(112,7)),
        3       => std_logic_vector(to_unsigned(0,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2572_spi_seq_arr_o_s(SEQ_ID_READ_VCO).data_o_s             <= (
        0       => x"0000",
        1       => x"0000",
        2       => x"0000",
        3       => x"211C",     -- Reconfigure MUXOUT as pll locked out
        others  => x"0000");

    LMX2594_spi_seq_arr_o_s(SEQ_ID_READ_VCO).nbr_of_cmds_s    <= to_unsigned(4,NBR_OF_CMD_LENGHT);
    LMX2594_spi_seq_arr_o_s(SEQ_ID_READ_VCO).RW_s             <= (
        0       => '1',
        1       => '1',
        2       => '1',
        3       => '0',
        others  => '0');
    LMX2594_spi_seq_arr_o_s(SEQ_ID_READ_VCO).addr_s           <= (
        0       => std_logic_vector(to_unsigned(110,7)),
        1       => std_logic_vector(to_unsigned(111,7)),
        2       => std_logic_vector(to_unsigned(112,7)),
        3       => std_logic_vector(to_unsigned(0,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2594_spi_seq_arr_o_s(SEQ_ID_READ_VCO).data_o_s             <= (
        0       => x"0000",
        1       => x"0000",
        2       => x"0000",
        3       => x"251C",     -- Reconfigure MUXOUT as pll locked out
        others  => x"0000");

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                spi_seq_arr_i_s <= (others => (others => (others => (others => '0'))));
                vco_sel_reg_i_s <= (others => '0');
                vco_capctrl_reg_i_s <= (others => '0');
                vco_daciset_reg_i_s <= (others => '0');
            else
                spi_seq_arr_i_s(seq_id_i).data_i_s <= spi_seq_i.data_i_s;
                if seq_id_i = SEQ_ID_READ_VCO then
                    vco_sel_reg_i_s <= spi_seq_i.data_i_s(0);
                    vco_capctrl_reg_i_s <= spi_seq_i.data_i_s(1);
                    vco_daciset_reg_i_s <= spi_seq_i.data_i_s(2);
                end if;
            end if;
        end if;
    end process;

    --VCO Full Assist Calibration with Calibration ReadBack (full assist calibration part)
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO).nbr_of_cmds_s    <= to_unsigned(11,NBR_OF_CMD_LENGHT);
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO).RW_s             <= (others  => '0');
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO).addr_s           <= (
        0       => std_logic_vector(to_unsigned(37,7)),
        1       => std_logic_vector(to_unsigned(36,7)),
        2       => std_logic_vector(to_unsigned(43,7)),
        3       => std_logic_vector(to_unsigned(39,7)),
        4       => std_logic_vector(to_unsigned(20,7)),
        5       => std_logic_vector(to_unsigned(19,7)),
        6       => std_logic_vector(to_unsigned(16,7)),
        7       => std_logic_vector(to_unsigned(46,7)),
        8       => std_logic_vector(to_unsigned(45,7)),
        9       => std_logic_vector(to_unsigned(44,7)), -- OUTPUT POWER
        10      => std_logic_vector(to_unsigned(75,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO).data_o_s             <= (
        0       => freq_para_i.PFD_DLY_SEL_s,
        1       => freq_para_i.PLL_N_s,
        2       => freq_para_i.PLL_NUM_s(15 downto 0),
        3       => freq_para_i.PLL_DEN_s(15 downto 0),
        4       => VCO_SEL_REG_s,       -- only bits from 13 to 11 the VCO seletion, and bit 10 to 1 to force VCO_SEL, default value : 7048h
        5       => VCO_CAPCTRL_REG_s,   -- only bits from 7 to 0 for the VCO_CAPCTRL, default value : 27B7h
        6       => VCO_DACISET_REG_s,   -- only bits from 8 to 0 from VCO_DACISET, default value : 0080h
        7       => R46_REG_s,
        8       => POWERB_REG_s,
        9       => POWERA_REG_s,
        10      => freq_para_i.CHDIV_s,
        others  => x"0000");

    LMX2594_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO) <= LMX2572_spi_seq_arr_o_s(SEQ_ID_SET_FREQ_VCO);

    LMX2572_spi_seq_arr_o_s(SEQ_ID_IDLE).nbr_of_cmds_s    <= to_unsigned(12,NBR_OF_CMD_LENGHT);
    LMX2572_spi_seq_arr_o_s(SEQ_ID_IDLE).RW_s             <= (others  => '0');
    LMX2572_spi_seq_arr_o_s(SEQ_ID_IDLE).addr_s           <= (
        -- R44 : OUTA_PD
        -- R45 : OUTA_MUX
        0       => std_logic_vector(to_unsigned(8,7)),
        1       => std_logic_vector(to_unsigned(37,7)),
        2       => std_logic_vector(to_unsigned(36,7)),
        3       => std_logic_vector(to_unsigned(43,7)),
        4       => std_logic_vector(to_unsigned(39,7)),
        5       => std_logic_vector(to_unsigned(20,7)),
        6       => std_logic_vector(to_unsigned(19,7)),
        7       => std_logic_vector(to_unsigned(16,7)),
        8       => std_logic_vector(to_unsigned(46,7)),
        9       => std_logic_vector(to_unsigned(45,7)),
        10      => std_logic_vector(to_unsigned(44,7)), -- OUTPUT POWER
        11      => std_logic_vector(to_unsigned(75,7)),
        others  => std_logic_vector(to_unsigned(0,7)));
    LMX2572_spi_seq_arr_o_s(SEQ_ID_IDLE).data_o_s             <= (
        0       => x"6800",     -- VCO_CAPCTRL_FORCE and VCO_DACISET_FORCE 
        1       => freq_para_i.PFD_DLY_SEL_s,
        2       => freq_para_i.PLL_N_s,
        3       => freq_para_i.PLL_NUM_s(15 downto 0),
        4       => freq_para_i.PLL_DEN_s(15 downto 0),
        5       => VCO_SEL_REG_s,       -- only bits from 13 to 11 the VCO seletion, and bit 10 to 1 to force VCO_SEL, default value : 3048h
        6       => VCO_CAPCTRL_REG_s,   -- only bits from 7 to 0 for the VCO_CAPCTRL, default value : 27B7h
        7       => VCO_DACISET_REG_s,   -- only bits from 8 to 0 from VCO_DACISET, default value : 0080h
        8       => R46_REG_s,
        9       => POWERB_REG_s,
        10      => POWERA_REG_s,
        11      => freq_para_i.CHDIV_s,
        others  => x"0000");

    LMX2594_spi_seq_arr_o_s(SEQ_ID_IDLE) <= LMX2572_spi_seq_arr_o_s(SEQ_ID_IDLE);

end architecture mix;
