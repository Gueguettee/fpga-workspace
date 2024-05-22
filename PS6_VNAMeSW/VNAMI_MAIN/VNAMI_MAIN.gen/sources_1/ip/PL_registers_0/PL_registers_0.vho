-- (c) Copyright 1995-2023 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: Julien:user:PL_registers:1.0
-- IP Revision: 1

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT PL_registers_0
  PORT (
    start_PL_o : OUT STD_LOGIC;
    start_PL_i : IN STD_LOGIC;
    init_meas_o : OUT STD_LOGIC;
    freq_done_o : OUT STD_LOGIC;
    path_done_o : OUT STD_LOGIC;
    init_meas_i : IN STD_LOGIC;
    freq_done_i : IN STD_LOGIC;
    path_done_i : IN STD_LOGIC;
    freq_val_o : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    ifbw_val_o : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    path_tx_val_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    path_rx_val_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    freq_val_i : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    ifbw_val_i : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    path_tx_val_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    path_rx_val_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    IQ_rdy_PL_i : IN STD_LOGIC;
    IQ_rdy_PL_o : OUT STD_LOGIC;
    I_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_TX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    I_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_RX_PL_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    I_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_TX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    I_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Q_RX_PL_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    output_tilt_i : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    SPM_data_i : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
    output_tilt_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    SPM_data_o : OUT STD_LOGIC_VECTOR(27 DOWNTO 0);
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
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : PL_registers_0
  PORT MAP (
    start_PL_o => start_PL_o,
    start_PL_i => start_PL_i,
    init_meas_o => init_meas_o,
    freq_done_o => freq_done_o,
    path_done_o => path_done_o,
    init_meas_i => init_meas_i,
    freq_done_i => freq_done_i,
    path_done_i => path_done_i,
    freq_val_o => freq_val_o,
    ifbw_val_o => ifbw_val_o,
    path_tx_val_o => path_tx_val_o,
    path_rx_val_o => path_rx_val_o,
    freq_val_i => freq_val_i,
    ifbw_val_i => ifbw_val_i,
    path_tx_val_i => path_tx_val_i,
    path_rx_val_i => path_rx_val_i,
    IQ_rdy_PL_i => IQ_rdy_PL_i,
    IQ_rdy_PL_o => IQ_rdy_PL_o,
    I_TX_PL_i => I_TX_PL_i,
    Q_TX_PL_i => Q_TX_PL_i,
    I_RX_PL_i => I_RX_PL_i,
    Q_RX_PL_i => Q_RX_PL_i,
    I_TX_PL_o => I_TX_PL_o,
    Q_TX_PL_o => Q_TX_PL_o,
    I_RX_PL_o => I_RX_PL_o,
    Q_RX_PL_o => Q_RX_PL_o,
    output_tilt_i => output_tilt_i,
    SPM_data_i => SPM_data_i,
    output_tilt_o => output_tilt_o,
    SPM_data_o => SPM_data_o,
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
-- INST_TAG_END ------ End INSTANTIATION Template ---------

