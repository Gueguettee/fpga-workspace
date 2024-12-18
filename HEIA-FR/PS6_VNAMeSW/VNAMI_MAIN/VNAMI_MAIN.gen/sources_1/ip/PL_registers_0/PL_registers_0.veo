// (c) Copyright 1995-2023 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: Julien:user:PL_registers:1.0
// IP Revision: 1

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
PL_registers_0 your_instance_name (
  .start_PL_o(start_PL_o),            // output wire start_PL_o
  .start_PL_i(start_PL_i),            // input wire start_PL_i
  .init_meas_o(init_meas_o),          // output wire init_meas_o
  .freq_done_o(freq_done_o),          // output wire freq_done_o
  .path_done_o(path_done_o),          // output wire path_done_o
  .init_meas_i(init_meas_i),          // input wire init_meas_i
  .freq_done_i(freq_done_i),          // input wire freq_done_i
  .path_done_i(path_done_i),          // input wire path_done_i
  .freq_val_o(freq_val_o),            // output wire [5 : 0] freq_val_o
  .ifbw_val_o(ifbw_val_o),            // output wire [4 : 0] ifbw_val_o
  .path_tx_val_o(path_tx_val_o),      // output wire [7 : 0] path_tx_val_o
  .path_rx_val_o(path_rx_val_o),      // output wire [7 : 0] path_rx_val_o
  .freq_val_i(freq_val_i),            // input wire [5 : 0] freq_val_i
  .ifbw_val_i(ifbw_val_i),            // input wire [4 : 0] ifbw_val_i
  .path_tx_val_i(path_tx_val_i),      // input wire [7 : 0] path_tx_val_i
  .path_rx_val_i(path_rx_val_i),      // input wire [7 : 0] path_rx_val_i
  .IQ_rdy_PL_i(IQ_rdy_PL_i),          // input wire IQ_rdy_PL_i
  .IQ_rdy_PL_o(IQ_rdy_PL_o),          // output wire IQ_rdy_PL_o
  .I_TX_PL_i(I_TX_PL_i),              // input wire [31 : 0] I_TX_PL_i
  .Q_TX_PL_i(Q_TX_PL_i),              // input wire [31 : 0] Q_TX_PL_i
  .I_RX_PL_i(I_RX_PL_i),              // input wire [31 : 0] I_RX_PL_i
  .Q_RX_PL_i(Q_RX_PL_i),              // input wire [31 : 0] Q_RX_PL_i
  .I_TX_PL_o(I_TX_PL_o),              // output wire [31 : 0] I_TX_PL_o
  .Q_TX_PL_o(Q_TX_PL_o),              // output wire [31 : 0] Q_TX_PL_o
  .I_RX_PL_o(I_RX_PL_o),              // output wire [31 : 0] I_RX_PL_o
  .Q_RX_PL_o(Q_RX_PL_o),              // output wire [31 : 0] Q_RX_PL_o
  .output_tilt_i(output_tilt_i),      // input wire [2 : 0] output_tilt_i
  .SPM_data_i(SPM_data_i),            // input wire [27 : 0] SPM_data_i
  .output_tilt_o(output_tilt_o),      // output wire [2 : 0] output_tilt_o
  .SPM_data_o(SPM_data_o),            // output wire [27 : 0] SPM_data_o
  .s00_axi_aclk(s00_axi_aclk),        // input wire s00_axi_aclk
  .s00_axi_aresetn(s00_axi_aresetn),  // input wire s00_axi_aresetn
  .s00_axi_awaddr(s00_axi_awaddr),    // input wire [6 : 0] s00_axi_awaddr
  .s00_axi_awprot(s00_axi_awprot),    // input wire [2 : 0] s00_axi_awprot
  .s00_axi_awvalid(s00_axi_awvalid),  // input wire s00_axi_awvalid
  .s00_axi_awready(s00_axi_awready),  // output wire s00_axi_awready
  .s00_axi_wdata(s00_axi_wdata),      // input wire [31 : 0] s00_axi_wdata
  .s00_axi_wstrb(s00_axi_wstrb),      // input wire [3 : 0] s00_axi_wstrb
  .s00_axi_wvalid(s00_axi_wvalid),    // input wire s00_axi_wvalid
  .s00_axi_wready(s00_axi_wready),    // output wire s00_axi_wready
  .s00_axi_bresp(s00_axi_bresp),      // output wire [1 : 0] s00_axi_bresp
  .s00_axi_bvalid(s00_axi_bvalid),    // output wire s00_axi_bvalid
  .s00_axi_bready(s00_axi_bready),    // input wire s00_axi_bready
  .s00_axi_araddr(s00_axi_araddr),    // input wire [6 : 0] s00_axi_araddr
  .s00_axi_arprot(s00_axi_arprot),    // input wire [2 : 0] s00_axi_arprot
  .s00_axi_arvalid(s00_axi_arvalid),  // input wire s00_axi_arvalid
  .s00_axi_arready(s00_axi_arready),  // output wire s00_axi_arready
  .s00_axi_rdata(s00_axi_rdata),      // output wire [31 : 0] s00_axi_rdata
  .s00_axi_rresp(s00_axi_rresp),      // output wire [1 : 0] s00_axi_rresp
  .s00_axi_rvalid(s00_axi_rvalid),    // output wire s00_axi_rvalid
  .s00_axi_rready(s00_axi_rready)    // input wire s00_axi_rready
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

