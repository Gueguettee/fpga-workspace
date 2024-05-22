--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
--Date        : Sun May 12 20:54:52 2024
--Host        : DESKTOP-FDL4QU3 running 64-bit major release  (build 9200)
--Command     : generate_target VNAMI_BLOCK_DESIGN_wrapper.bd
--Design      : VNAMI_BLOCK_DESIGN_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity VNAMI_BLOCK_DESIGN_wrapper is
  port (
    ADC_RX_i : in STD_LOGIC_VECTOR ( 13 downto 0 );
    ADC_TX_i : in STD_LOGIC_VECTOR ( 13 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FMC_LA00_CC_N : out STD_LOGIC;
    FMC_LA00_CC_P : in STD_LOGIC;
    FMC_LA01_CC_N : out STD_LOGIC;
    FMC_LA02_P : out STD_LOGIC;
    FMC_LA18_CC_N : out STD_LOGIC;
    FMC_LA18_CC_P : in STD_LOGIC;
    FMC_LA19_N : out STD_LOGIC;
    FMC_LA19_P : out STD_LOGIC;
    FMC_LA20_N : out STD_LOGIC;
    FMC_LA22_N : in STD_LOGIC;
    FMC_LA22_P : out STD_LOGIC;
    FMC_LA23_N : out STD_LOGIC;
    FMC_LA23_P : out STD_LOGIC;
    FMC_LA26_N : in STD_LOGIC;
    FMC_LA26_P : out STD_LOGIC;
    FMC_LA27_N : in STD_LOGIC;
    FMC_LA27_P : out STD_LOGIC;
    FMC_LA33_P : in STD_LOGIC;
    IQ_rdy_PL_o : out STD_LOGIC;
    SWR_RX_RCLK : out STD_LOGIC;
    SWR_RX_SER : out STD_LOGIC;
    SWR_RX_SRCLK : out STD_LOGIC;
    SWR_RX_SRCLR : out STD_LOGIC;
    SWR_TX_RCLK : out STD_LOGIC;
    SWR_TX_SER : out STD_LOGIC;
    SWR_TX_SRCLK : out STD_LOGIC;
    SWR_TX_SRCLR : out STD_LOGIC;
    V_o : out STD_LOGIC_VECTOR ( 3 downto 0 );
    btn_d_i : in STD_LOGIC;
    btn_l_i : in STD_LOGIC;
    btn_r_i : in STD_LOGIC;
    btn_u_i : in STD_LOGIC;
    clk_i : in STD_LOGIC;
    led_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    reset_i : in STD_LOGIC;
    sw_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    write_IQ_o : out STD_LOGIC
  );
end VNAMI_BLOCK_DESIGN_wrapper;

architecture STRUCTURE of VNAMI_BLOCK_DESIGN_wrapper is
  component VNAMI_BLOCK_DESIGN is
  port (
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FMC_LA26_P : out STD_LOGIC;
    FMC_LA22_N : in STD_LOGIC;
    FMC_LA23_N : out STD_LOGIC;
    FMC_LA27_P : out STD_LOGIC;
    btn_d_i : in STD_LOGIC;
    btn_l_i : in STD_LOGIC;
    btn_r_i : in STD_LOGIC;
    btn_u_i : in STD_LOGIC;
    clk_i : in STD_LOGIC;
    led_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    reset_i : in STD_LOGIC;
    sw_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    FMC_LA23_P : out STD_LOGIC;
    FMC_LA20_N : out STD_LOGIC;
    FMC_LA18_CC_P : in STD_LOGIC;
    FMC_LA01_CC_N : out STD_LOGIC;
    FMC_LA18_CC_N : out STD_LOGIC;
    ADC_TX_i : in STD_LOGIC_VECTOR ( 13 downto 0 );
    ADC_RX_i : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FMC_LA33_P : in STD_LOGIC;
    FMC_LA26_N : in STD_LOGIC;
    FMC_LA27_N : in STD_LOGIC;
    FMC_LA00_CC_N : out STD_LOGIC;
    FMC_LA00_CC_P : in STD_LOGIC;
    FMC_LA02_P : out STD_LOGIC;
    FMC_LA19_N : out STD_LOGIC;
    IQ_rdy_PL_o : out STD_LOGIC;
    write_IQ_o : out STD_LOGIC;
    SWR_TX_SER : out STD_LOGIC;
    SWR_TX_SRCLK : out STD_LOGIC;
    SWR_TX_RCLK : out STD_LOGIC;
    SWR_TX_SRCLR : out STD_LOGIC;
    SWR_RX_SER : out STD_LOGIC;
    SWR_RX_SRCLK : out STD_LOGIC;
    SWR_RX_SRCLR : out STD_LOGIC;
    SWR_RX_RCLK : out STD_LOGIC;
    FMC_LA22_P : out STD_LOGIC;
    FMC_LA19_P : out STD_LOGIC;
    V_o : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component VNAMI_BLOCK_DESIGN;
begin
VNAMI_BLOCK_DESIGN_i: component VNAMI_BLOCK_DESIGN
     port map (
      ADC_RX_i(13 downto 0) => ADC_RX_i(13 downto 0),
      ADC_TX_i(13 downto 0) => ADC_TX_i(13 downto 0),
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      FMC_LA00_CC_N => FMC_LA00_CC_N,
      FMC_LA00_CC_P => FMC_LA00_CC_P,
      FMC_LA01_CC_N => FMC_LA01_CC_N,
      FMC_LA02_P => FMC_LA02_P,
      FMC_LA18_CC_N => FMC_LA18_CC_N,
      FMC_LA18_CC_P => FMC_LA18_CC_P,
      FMC_LA19_N => FMC_LA19_N,
      FMC_LA19_P => FMC_LA19_P,
      FMC_LA20_N => FMC_LA20_N,
      FMC_LA22_N => FMC_LA22_N,
      FMC_LA22_P => FMC_LA22_P,
      FMC_LA23_N => FMC_LA23_N,
      FMC_LA23_P => FMC_LA23_P,
      FMC_LA26_N => FMC_LA26_N,
      FMC_LA26_P => FMC_LA26_P,
      FMC_LA27_N => FMC_LA27_N,
      FMC_LA27_P => FMC_LA27_P,
      FMC_LA33_P => FMC_LA33_P,
      IQ_rdy_PL_o => IQ_rdy_PL_o,
      SWR_RX_RCLK => SWR_RX_RCLK,
      SWR_RX_SER => SWR_RX_SER,
      SWR_RX_SRCLK => SWR_RX_SRCLK,
      SWR_RX_SRCLR => SWR_RX_SRCLR,
      SWR_TX_RCLK => SWR_TX_RCLK,
      SWR_TX_SER => SWR_TX_SER,
      SWR_TX_SRCLK => SWR_TX_SRCLK,
      SWR_TX_SRCLR => SWR_TX_SRCLR,
      V_o(3 downto 0) => V_o(3 downto 0),
      btn_d_i => btn_d_i,
      btn_l_i => btn_l_i,
      btn_r_i => btn_r_i,
      btn_u_i => btn_u_i,
      clk_i => clk_i,
      led_o(7 downto 0) => led_o(7 downto 0),
      reset_i => reset_i,
      sw_i(7 downto 0) => sw_i(7 downto 0),
      write_IQ_o => write_IQ_o
    );
end STRUCTURE;
