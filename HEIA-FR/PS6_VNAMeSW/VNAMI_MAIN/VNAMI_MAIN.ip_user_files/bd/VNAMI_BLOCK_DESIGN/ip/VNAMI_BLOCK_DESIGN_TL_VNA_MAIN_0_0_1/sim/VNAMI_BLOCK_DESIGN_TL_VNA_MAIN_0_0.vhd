-- (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- (c) Copyright 2022-2024 Advanced Micro Devices, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:module_ref:TL_VNA_MAIN:1.0
-- IP Revision: 1

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0 IS
  PORT (
    clk_i : IN STD_LOGIC;
    reset_i : IN STD_LOGIC;
    clk_100_o : OUT STD_LOGIC;
    clk_80_o : OUT STD_LOGIC;
    clk_40_o : OUT STD_LOGIC;
    clk_10_o : OUT STD_LOGIC;
    start_PL_i : IN STD_LOGIC;
    init_meas_i : IN STD_LOGIC;
    freq_done_i : IN STD_LOGIC;
    path_done_i : IN STD_LOGIC;
    freq_val_i : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    ifbw_val_i : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    path_tx_val_i : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    path_rx_val_i : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    IQ_rdy_PL_o : OUT STD_LOGIC;
    I_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    I_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    write_IQ_o : OUT STD_LOGIC;
    sw_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    led_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    btn_u_i : IN STD_LOGIC;
    btn_d_i : IN STD_LOGIC;
    btn_l_i : IN STD_LOGIC;
    btn_r_i : IN STD_LOGIC;
    ADC_TX_i : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    ADC_RX_i : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    RF_MUXout_i : IN STD_LOGIC;
    RF_SCK_o : OUT STD_LOGIC;
    RF_CSB_o : OUT STD_LOGIC;
    RF_SDI_o : OUT STD_LOGIC;
    RF_CE_o : OUT STD_LOGIC;
    LO_MUXout_i : IN STD_LOGIC;
    LO_SCK_o : OUT STD_LOGIC;
    LO_CSB_o : OUT STD_LOGIC;
    LO_SDI_o : OUT STD_LOGIC;
    LO_CE_o : OUT STD_LOGIC;
    output_tilt_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    input_tilt_1 : IN STD_LOGIC;
    input_tilt_2 : IN STD_LOGIC;
    input_tilt_3 : IN STD_LOGIC;
    SPM_data_o : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
    SPM_MISO_i : IN STD_LOGIC;
    SPM_SCLK_o : OUT STD_LOGIC;
    SPM_CSB_o : OUT STD_LOGIC;
    SWR_TX_SER_o : OUT STD_LOGIC;
    SWR_TX_SRCLK_o : OUT STD_LOGIC;
    SWR_TX_SRCLR_o : OUT STD_LOGIC;
    SWR_TX_RCLK_o : OUT STD_LOGIC;
    SWR_RX_SER_o : OUT STD_LOGIC;
    SWR_RX_SRCLK_o : OUT STD_LOGIC;
    SWR_RX_SRCLR_o : OUT STD_LOGIC;
    SWR_RX_RCLK_o : OUT STD_LOGIC;
    V_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0;

ARCHITECTURE VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0_arch OF VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT TL_VNA_MAIN IS
    PORT (
      clk_i : IN STD_LOGIC;
      reset_i : IN STD_LOGIC;
      clk_100_o : OUT STD_LOGIC;
      clk_80_o : OUT STD_LOGIC;
      clk_40_o : OUT STD_LOGIC;
      clk_10_o : OUT STD_LOGIC;
      start_PL_i : IN STD_LOGIC;
      init_meas_i : IN STD_LOGIC;
      freq_done_i : IN STD_LOGIC;
      path_done_i : IN STD_LOGIC;
      freq_val_i : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      ifbw_val_i : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      path_tx_val_i : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      path_rx_val_i : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
      IQ_rdy_PL_o : OUT STD_LOGIC;
      I_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      Q_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      I_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      Q_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      write_IQ_o : OUT STD_LOGIC;
      sw_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      led_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      btn_u_i : IN STD_LOGIC;
      btn_d_i : IN STD_LOGIC;
      btn_l_i : IN STD_LOGIC;
      btn_r_i : IN STD_LOGIC;
      ADC_TX_i : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      ADC_RX_i : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      RF_MUXout_i : IN STD_LOGIC;
      RF_SCK_o : OUT STD_LOGIC;
      RF_CSB_o : OUT STD_LOGIC;
      RF_SDI_o : OUT STD_LOGIC;
      RF_CE_o : OUT STD_LOGIC;
      LO_MUXout_i : IN STD_LOGIC;
      LO_SCK_o : OUT STD_LOGIC;
      LO_CSB_o : OUT STD_LOGIC;
      LO_SDI_o : OUT STD_LOGIC;
      LO_CE_o : OUT STD_LOGIC;
      output_tilt_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      input_tilt_1 : IN STD_LOGIC;
      input_tilt_2 : IN STD_LOGIC;
      input_tilt_3 : IN STD_LOGIC;
      SPM_data_o : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
      SPM_MISO_i : IN STD_LOGIC;
      SPM_SCLK_o : OUT STD_LOGIC;
      SPM_CSB_o : OUT STD_LOGIC;
      SWR_TX_SER_o : OUT STD_LOGIC;
      SWR_TX_SRCLK_o : OUT STD_LOGIC;
      SWR_TX_SRCLR_o : OUT STD_LOGIC;
      SWR_TX_RCLK_o : OUT STD_LOGIC;
      SWR_RX_SER_o : OUT STD_LOGIC;
      SWR_RX_SRCLK_o : OUT STD_LOGIC;
      SWR_RX_SRCLR_o : OUT STD_LOGIC;
      SWR_RX_RCLK_o : OUT STD_LOGIC;
      V_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
  END COMPONENT TL_VNA_MAIN;
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF reset_i: SIGNAL IS "XIL_INTERFACENAME reset_i, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF reset_i: SIGNAL IS "xilinx.com:signal:reset:1.0 reset_i RST";
BEGIN
  U0 : TL_VNA_MAIN
    PORT MAP (
      clk_i => clk_i,
      reset_i => reset_i,
      clk_100_o => clk_100_o,
      clk_80_o => clk_80_o,
      clk_40_o => clk_40_o,
      clk_10_o => clk_10_o,
      start_PL_i => start_PL_i,
      init_meas_i => init_meas_i,
      freq_done_i => freq_done_i,
      path_done_i => path_done_i,
      freq_val_i => freq_val_i,
      ifbw_val_i => ifbw_val_i,
      path_tx_val_i => path_tx_val_i,
      path_rx_val_i => path_rx_val_i,
      IQ_rdy_PL_o => IQ_rdy_PL_o,
      I_TX_PL_o => I_TX_PL_o,
      Q_TX_PL_o => Q_TX_PL_o,
      I_RX_PL_o => I_RX_PL_o,
      Q_RX_PL_o => Q_RX_PL_o,
      write_IQ_o => write_IQ_o,
      sw_i => sw_i,
      led_o => led_o,
      btn_u_i => btn_u_i,
      btn_d_i => btn_d_i,
      btn_l_i => btn_l_i,
      btn_r_i => btn_r_i,
      ADC_TX_i => ADC_TX_i,
      ADC_RX_i => ADC_RX_i,
      RF_MUXout_i => RF_MUXout_i,
      RF_SCK_o => RF_SCK_o,
      RF_CSB_o => RF_CSB_o,
      RF_SDI_o => RF_SDI_o,
      RF_CE_o => RF_CE_o,
      LO_MUXout_i => LO_MUXout_i,
      LO_SCK_o => LO_SCK_o,
      LO_CSB_o => LO_CSB_o,
      LO_SDI_o => LO_SDI_o,
      LO_CE_o => LO_CE_o,
      output_tilt_o => output_tilt_o,
      input_tilt_1 => input_tilt_1,
      input_tilt_2 => input_tilt_2,
      input_tilt_3 => input_tilt_3,
      SPM_data_o => SPM_data_o,
      SPM_MISO_i => SPM_MISO_i,
      SPM_SCLK_o => SPM_SCLK_o,
      SPM_CSB_o => SPM_CSB_o,
      SWR_TX_SER_o => SWR_TX_SER_o,
      SWR_TX_SRCLK_o => SWR_TX_SRCLK_o,
      SWR_TX_SRCLR_o => SWR_TX_SRCLR_o,
      SWR_TX_RCLK_o => SWR_TX_RCLK_o,
      SWR_RX_SER_o => SWR_RX_SER_o,
      SWR_RX_SRCLK_o => SWR_RX_SRCLK_o,
      SWR_RX_SRCLR_o => SWR_RX_SRCLR_o,
      SWR_RX_RCLK_o => SWR_RX_RCLK_o,
      V_o => V_o
    );
END VNAMI_BLOCK_DESIGN_TL_VNA_MAIN_0_0_arch;
