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

-- IP VLNV: Julien:user:PL_registers:1.0
-- IP Revision: 11

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY VNAMI_BLOCK_DESIGN_PL_registers_0_2 IS
  PORT (
    start_PL_o : OUT STD_LOGIC;
    init_meas_o : OUT STD_LOGIC;
    freq_done_o : OUT STD_LOGIC;
    path_done_o : OUT STD_LOGIC;
    freq_val_o : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    ifbw_val_o : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    path_tx_val_o : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    path_rx_val_o : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
    IQ_rdy_PL_i : IN STD_LOGIC;
    I_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    I_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    output_tilt_i : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    SPM_data_i : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
    s00_axi_aclk : IN STD_LOGIC;
    s00_axi_aresetn : IN STD_LOGIC;
    s00_axi_awaddr : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    s00_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s00_axi_awvalid : IN STD_LOGIC;
    s00_axi_awready : OUT STD_LOGIC;
    s00_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s00_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s00_axi_wvalid : IN STD_LOGIC;
    s00_axi_wready : OUT STD_LOGIC;
    s00_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s00_axi_bvalid : OUT STD_LOGIC;
    s00_axi_bready : IN STD_LOGIC;
    s00_axi_araddr : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    s00_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s00_axi_arvalid : IN STD_LOGIC;
    s00_axi_arready : OUT STD_LOGIC;
    s00_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s00_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s00_axi_rvalid : OUT STD_LOGIC;
    s00_axi_rready : IN STD_LOGIC
  );
END VNAMI_BLOCK_DESIGN_PL_registers_0_2;

ARCHITECTURE VNAMI_BLOCK_DESIGN_PL_registers_0_2_arch OF VNAMI_BLOCK_DESIGN_PL_registers_0_2 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF VNAMI_BLOCK_DESIGN_PL_registers_0_2_arch: ARCHITECTURE IS "yes";
  COMPONENT PL_registers_v1_0 IS
    GENERIC (
      C_S00_AXI_DATA_WIDTH : INTEGER;
      C_S00_AXI_ADDR_WIDTH : INTEGER;
      FREQ_DATA_LENGTH : INTEGER;
      IFBW_DATA_LENGTH : INTEGER;
      PATH_DATA_LENGTH : INTEGER;
      TILT_DATA_LENGTH : INTEGER;
      SPM_DATA_LENGTH : INTEGER
    );
    PORT (
      start_PL_o : OUT STD_LOGIC;
      init_meas_o : OUT STD_LOGIC;
      freq_done_o : OUT STD_LOGIC;
      path_done_o : OUT STD_LOGIC;
      freq_val_o : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
      ifbw_val_o : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
      path_tx_val_o : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      path_rx_val_o : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
      IQ_rdy_PL_i : IN STD_LOGIC;
      I_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      Q_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      I_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      Q_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      output_tilt_i : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      SPM_data_i : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
      s00_axi_aclk : IN STD_LOGIC;
      s00_axi_aresetn : IN STD_LOGIC;
      s00_axi_awaddr : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
      s00_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s00_axi_awvalid : IN STD_LOGIC;
      s00_axi_awready : OUT STD_LOGIC;
      s00_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s00_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s00_axi_wvalid : IN STD_LOGIC;
      s00_axi_wready : OUT STD_LOGIC;
      s00_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s00_axi_bvalid : OUT STD_LOGIC;
      s00_axi_bready : IN STD_LOGIC;
      s00_axi_araddr : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
      s00_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s00_axi_arvalid : IN STD_LOGIC;
      s00_axi_arready : OUT STD_LOGIC;
      s00_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      s00_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s00_axi_rvalid : OUT STD_LOGIC;
      s00_axi_rready : IN STD_LOGIC
    );
  END COMPONENT PL_registers_v1_0;
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_aclk: SIGNAL IS "XIL_INTERFACENAME S00_AXI_CLK, ASSOCIATED_BUSIF S00_AXI, ASSOCIATED_RESET s00_axi_aresetn, FREQ_HZ 10000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN VNAMI_BLOCK_DESIGN_processing_system7_1_0_FCLK_CLK1, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 S00_AXI_CLK CLK";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_araddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARADDR";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_aresetn: SIGNAL IS "XIL_INTERFACENAME S00_AXI_RST, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 S00_AXI_RST RST";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARVALID";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_awaddr: SIGNAL IS "XIL_INTERFACENAME S00_AXI, WIZ_DATA_WIDTH 32, WIZ_NUM_REG 17, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 10000000, ID_WIDTH 0, ADDR_WIDTH 7, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 8, NUM_WRITE_OUTSTANDING 8, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN VNAMI_BLOCK_DESIGN_proces" & 
"sing_system7_1_0_FCLK_CLK1, NUM_READ_THREADS 4, NUM_WRITE_THREADS 4, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awaddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWADDR";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWPROT";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wstrb: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WVALID";
BEGIN
  U0 : PL_registers_v1_0
    GENERIC MAP (
      C_S00_AXI_DATA_WIDTH => 32,
      C_S00_AXI_ADDR_WIDTH => 7,
      FREQ_DATA_LENGTH => 6,
      IFBW_DATA_LENGTH => 5,
      PATH_DATA_LENGTH => 24,
      TILT_DATA_LENGTH => 3,
      SPM_DATA_LENGTH => 28
    )
    PORT MAP (
      start_PL_o => start_PL_o,
      init_meas_o => init_meas_o,
      freq_done_o => freq_done_o,
      path_done_o => path_done_o,
      freq_val_o => freq_val_o,
      ifbw_val_o => ifbw_val_o,
      path_tx_val_o => path_tx_val_o,
      path_rx_val_o => path_rx_val_o,
      IQ_rdy_PL_i => IQ_rdy_PL_i,
      I_TX_PL_i => I_TX_PL_i,
      Q_TX_PL_i => Q_TX_PL_i,
      I_RX_PL_i => I_RX_PL_i,
      Q_RX_PL_i => Q_RX_PL_i,
      output_tilt_i => output_tilt_i,
      SPM_data_i => SPM_data_i,
      s00_axi_aclk => s00_axi_aclk,
      s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_awaddr => s00_axi_awaddr,
      s00_axi_awprot => s00_axi_awprot,
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_awready => s00_axi_awready,
      s00_axi_wdata => s00_axi_wdata,
      s00_axi_wstrb => s00_axi_wstrb,
      s00_axi_wvalid => s00_axi_wvalid,
      s00_axi_wready => s00_axi_wready,
      s00_axi_bresp => s00_axi_bresp,
      s00_axi_bvalid => s00_axi_bvalid,
      s00_axi_bready => s00_axi_bready,
      s00_axi_araddr => s00_axi_araddr,
      s00_axi_arprot => s00_axi_arprot,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_arready => s00_axi_arready,
      s00_axi_rdata => s00_axi_rdata,
      s00_axi_rresp => s00_axi_rresp,
      s00_axi_rvalid => s00_axi_rvalid,
      s00_axi_rready => s00_axi_rready
    );
END VNAMI_BLOCK_DESIGN_PL_registers_0_2_arch;
