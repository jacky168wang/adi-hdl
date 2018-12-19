// (c) Copyright 1995-2018 Xilinx, Inc. All rights reserved.
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

// IP VLNV: analog.com:user:data_offload:1.0
// IP Revision: 1

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
data_offload_0 your_instance_name (
  .s_axi_aclk(s_axi_aclk),              // input wire s_axi_aclk
  .s_axi_aresetn(s_axi_aresetn),        // input wire s_axi_aresetn
  .s_axi_awvalid(s_axi_awvalid),        // input wire s_axi_awvalid
  .s_axi_awaddr(s_axi_awaddr),          // input wire [15 : 0] s_axi_awaddr
  .s_axi_awprot(s_axi_awprot),          // input wire [2 : 0] s_axi_awprot
  .s_axi_awready(s_axi_awready),        // output wire s_axi_awready
  .s_axi_wvalid(s_axi_wvalid),          // input wire s_axi_wvalid
  .s_axi_wdata(s_axi_wdata),            // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),            // input wire [3 : 0] s_axi_wstrb
  .s_axi_wready(s_axi_wready),          // output wire s_axi_wready
  .s_axi_bvalid(s_axi_bvalid),          // output wire s_axi_bvalid
  .s_axi_bresp(s_axi_bresp),            // output wire [1 : 0] s_axi_bresp
  .s_axi_bready(s_axi_bready),          // input wire s_axi_bready
  .s_axi_arvalid(s_axi_arvalid),        // input wire s_axi_arvalid
  .s_axi_araddr(s_axi_araddr),          // input wire [15 : 0] s_axi_araddr
  .s_axi_arprot(s_axi_arprot),          // input wire [2 : 0] s_axi_arprot
  .s_axi_arready(s_axi_arready),        // output wire s_axi_arready
  .s_axi_rvalid(s_axi_rvalid),          // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),          // input wire s_axi_rready
  .s_axi_rresp(s_axi_rresp),            // output wire [1 : 0] s_axi_rresp
  .s_axi_rdata(s_axi_rdata),            // output wire [31 : 0] s_axi_rdata
  .m_axis_rx_aclk(m_axis_rx_aclk),      // input wire m_axis_rx_aclk
  .m_axis_rx_resetn(m_axis_rx_resetn),  // input wire m_axis_rx_resetn
  .m_axis_rx_ready(m_axis_rx_ready),    // input wire m_axis_rx_ready
  .m_axis_rx_valid(m_axis_rx_valid),    // output wire m_axis_rx_valid
  .m_axis_rx_data(m_axis_rx_data),      // output wire [63 : 0] m_axis_rx_data
  .m_axis_rx_last(m_axis_rx_last),      // output wire m_axis_rx_last
  .m_axis_rx_tkeep(m_axis_rx_tkeep),    // output wire [7 : 0] m_axis_rx_tkeep
  .s_axis_rx_aclk(s_axis_rx_aclk),      // input wire s_axis_rx_aclk
  .s_axis_rx_resetn(s_axis_rx_resetn),  // input wire s_axis_rx_resetn
  .s_axis_rx_ready(s_axis_rx_ready),    // output wire s_axis_rx_ready
  .s_axis_rx_valid(s_axis_rx_valid),    // input wire s_axis_rx_valid
  .s_axis_rx_data(s_axis_rx_data),      // input wire [63 : 0] s_axis_rx_data
  .s_axis_rx_last(s_axis_rx_last),      // input wire s_axis_rx_last
  .s_axis_rx_tkeep(s_axis_rx_tkeep),    // input wire [7 : 0] s_axis_rx_tkeep
  .m_axis_tx_aclk(m_axis_tx_aclk),      // input wire m_axis_tx_aclk
  .m_axis_tx_resetn(m_axis_tx_resetn),  // input wire m_axis_tx_resetn
  .m_axis_tx_ready(m_axis_tx_ready),    // input wire m_axis_tx_ready
  .m_axis_tx_valid(m_axis_tx_valid),    // output wire m_axis_tx_valid
  .m_axis_tx_data(m_axis_tx_data),      // output wire [127 : 0] m_axis_tx_data
  .m_axis_tx_last(m_axis_tx_last),      // output wire m_axis_tx_last
  .m_axis_tx_tkeep(m_axis_tx_tkeep),    // output wire [15 : 0] m_axis_tx_tkeep
  .s_axis_tx_aclk(s_axis_tx_aclk),      // input wire s_axis_tx_aclk
  .s_axis_tx_resetn(s_axis_tx_resetn),  // input wire s_axis_tx_resetn
  .s_axis_tx_ready(s_axis_tx_ready),    // output wire s_axis_tx_ready
  .s_axis_tx_valid(s_axis_tx_valid),    // input wire s_axis_tx_valid
  .s_axis_tx_data(s_axis_tx_data),      // input wire [127 : 0] s_axis_tx_data
  .s_axis_tx_last(s_axis_tx_last),      // input wire s_axis_tx_last
  .s_axis_tx_tkeep(s_axis_tx_tkeep),    // input wire [15 : 0] s_axis_tx_tkeep
  .rx_init_req(rx_init_req),            // input wire rx_init_req
  .rx_init_ack(rx_init_ack),            // output wire rx_init_ack
  .rx_sync_ext(rx_sync_ext),            // input wire rx_sync_ext
  .tx_init_req(tx_init_req),            // input wire tx_init_req
  .tx_init_ack(tx_init_ack),            // output wire tx_init_ack
  .tx_sync_ext(tx_sync_ext),            // input wire tx_sync_ext
  .axi_clk(axi_clk),                    // input wire axi_clk
  .axi_resetn(axi_resetn),              // input wire axi_resetn
  .axi_awvalid(axi_awvalid),            // output wire axi_awvalid
  .axi_awid(axi_awid),                  // output wire [3 : 0] axi_awid
  .axi_awburst(axi_awburst),            // output wire [1 : 0] axi_awburst
  .axi_awlock(axi_awlock),              // output wire axi_awlock
  .axi_awcache(axi_awcache),            // output wire [3 : 0] axi_awcache
  .axi_awprot(axi_awprot),              // output wire [2 : 0] axi_awprot
  .axi_awqos(axi_awqos),                // output wire [3 : 0] axi_awqos
  .axi_awlen(axi_awlen),                // output wire [7 : 0] axi_awlen
  .axi_awsize(axi_awsize),              // output wire [2 : 0] axi_awsize
  .axi_awaddr(axi_awaddr),              // output wire [30 : 0] axi_awaddr
  .axi_awready(axi_awready),            // input wire axi_awready
  .axi_wvalid(axi_wvalid),              // output wire axi_wvalid
  .axi_wdata(axi_wdata),                // output wire [511 : 0] axi_wdata
  .axi_wstrb(axi_wstrb),                // output wire [63 : 0] axi_wstrb
  .axi_wlast(axi_wlast),                // output wire axi_wlast
  .axi_wready(axi_wready),              // input wire axi_wready
  .axi_bvalid(axi_bvalid),              // input wire axi_bvalid
  .axi_bid(axi_bid),                    // input wire [3 : 0] axi_bid
  .axi_bresp(axi_bresp),                // input wire [1 : 0] axi_bresp
  .axi_bready(axi_bready),              // output wire axi_bready
  .axi_arvalid(axi_arvalid),            // output wire axi_arvalid
  .axi_arid(axi_arid),                  // output wire [3 : 0] axi_arid
  .axi_arburst(axi_arburst),            // output wire [1 : 0] axi_arburst
  .axi_arlock(axi_arlock),              // output wire axi_arlock
  .axi_arcache(axi_arcache),            // output wire [3 : 0] axi_arcache
  .axi_arprot(axi_arprot),              // output wire [2 : 0] axi_arprot
  .axi_arqos(axi_arqos),                // output wire [3 : 0] axi_arqos
  .axi_arlen(axi_arlen),                // output wire [7 : 0] axi_arlen
  .axi_arsize(axi_arsize),              // output wire [2 : 0] axi_arsize
  .axi_araddr(axi_araddr),              // output wire [30 : 0] axi_araddr
  .axi_arready(axi_arready),            // input wire axi_arready
  .axi_rvalid(axi_rvalid),              // input wire axi_rvalid
  .axi_rready(axi_rready),              // output wire axi_rready
  .axi_rid(axi_rid),                    // input wire [3 : 0] axi_rid
  .axi_rresp(axi_rresp),                // input wire [1 : 0] axi_rresp
  .axi_rlast(axi_rlast),                // input wire axi_rlast
  .axi_rdata(axi_rdata)                // input wire [511 : 0] axi_rdata
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

