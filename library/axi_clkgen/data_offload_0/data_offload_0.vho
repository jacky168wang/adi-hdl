-- (c) Copyright 1995-2018 Xilinx, Inc. All rights reserved.
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

-- IP VLNV: analog.com:user:data_offload:1.0
-- IP Revision: 1

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT data_offload_0
  PORT (
    s_axi_aclk : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_awready : OUT STD_LOGIC;
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wready : OUT STD_LOGIC;
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bready : IN STD_LOGIC;
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_arready : OUT STD_LOGIC;
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_rx_aclk : IN STD_LOGIC;
    m_axis_rx_resetn : IN STD_LOGIC;
    m_axis_rx_ready : IN STD_LOGIC;
    m_axis_rx_valid : OUT STD_LOGIC;
    m_axis_rx_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    m_axis_rx_last : OUT STD_LOGIC;
    m_axis_rx_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    s_axis_rx_aclk : IN STD_LOGIC;
    s_axis_rx_resetn : IN STD_LOGIC;
    s_axis_rx_ready : OUT STD_LOGIC;
    s_axis_rx_valid : IN STD_LOGIC;
    s_axis_rx_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    s_axis_rx_last : IN STD_LOGIC;
    s_axis_rx_tkeep : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axis_tx_aclk : IN STD_LOGIC;
    m_axis_tx_resetn : IN STD_LOGIC;
    m_axis_tx_ready : IN STD_LOGIC;
    m_axis_tx_valid : OUT STD_LOGIC;
    m_axis_tx_data : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
    m_axis_tx_last : OUT STD_LOGIC;
    m_axis_tx_tkeep : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_tx_aclk : IN STD_LOGIC;
    s_axis_tx_resetn : IN STD_LOGIC;
    s_axis_tx_ready : OUT STD_LOGIC;
    s_axis_tx_valid : IN STD_LOGIC;
    s_axis_tx_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    s_axis_tx_last : IN STD_LOGIC;
    s_axis_tx_tkeep : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    rx_init_req : IN STD_LOGIC;
    rx_init_ack : OUT STD_LOGIC;
    rx_sync_ext : IN STD_LOGIC;
    tx_init_req : IN STD_LOGIC;
    tx_init_ack : OUT STD_LOGIC;
    tx_sync_ext : IN STD_LOGIC;
    axi_clk : IN STD_LOGIC;
    axi_resetn : IN STD_LOGIC;
    axi_awvalid : OUT STD_LOGIC;
    axi_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_awlock : OUT STD_LOGIC;
    axi_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_awaddr : OUT STD_LOGIC_VECTOR(30 DOWNTO 0);
    axi_awready : IN STD_LOGIC;
    axi_wvalid : OUT STD_LOGIC;
    axi_wdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    axi_wstrb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    axi_wlast : OUT STD_LOGIC;
    axi_wready : IN STD_LOGIC;
    axi_bvalid : IN STD_LOGIC;
    axi_bid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_bready : OUT STD_LOGIC;
    axi_arvalid : OUT STD_LOGIC;
    axi_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_arlock : OUT STD_LOGIC;
    axi_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    axi_araddr : OUT STD_LOGIC_VECTOR(30 DOWNTO 0);
    axi_arready : IN STD_LOGIC;
    axi_rvalid : IN STD_LOGIC;
    axi_rready : OUT STD_LOGIC;
    axi_rid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    axi_rlast : IN STD_LOGIC;
    axi_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : data_offload_0
  PORT MAP (
    s_axi_aclk => s_axi_aclk,
    s_axi_aresetn => s_axi_aresetn,
    s_axi_awvalid => s_axi_awvalid,
    s_axi_awaddr => s_axi_awaddr,
    s_axi_awprot => s_axi_awprot,
    s_axi_awready => s_axi_awready,
    s_axi_wvalid => s_axi_wvalid,
    s_axi_wdata => s_axi_wdata,
    s_axi_wstrb => s_axi_wstrb,
    s_axi_wready => s_axi_wready,
    s_axi_bvalid => s_axi_bvalid,
    s_axi_bresp => s_axi_bresp,
    s_axi_bready => s_axi_bready,
    s_axi_arvalid => s_axi_arvalid,
    s_axi_araddr => s_axi_araddr,
    s_axi_arprot => s_axi_arprot,
    s_axi_arready => s_axi_arready,
    s_axi_rvalid => s_axi_rvalid,
    s_axi_rready => s_axi_rready,
    s_axi_rresp => s_axi_rresp,
    s_axi_rdata => s_axi_rdata,
    m_axis_rx_aclk => m_axis_rx_aclk,
    m_axis_rx_resetn => m_axis_rx_resetn,
    m_axis_rx_ready => m_axis_rx_ready,
    m_axis_rx_valid => m_axis_rx_valid,
    m_axis_rx_data => m_axis_rx_data,
    m_axis_rx_last => m_axis_rx_last,
    m_axis_rx_tkeep => m_axis_rx_tkeep,
    s_axis_rx_aclk => s_axis_rx_aclk,
    s_axis_rx_resetn => s_axis_rx_resetn,
    s_axis_rx_ready => s_axis_rx_ready,
    s_axis_rx_valid => s_axis_rx_valid,
    s_axis_rx_data => s_axis_rx_data,
    s_axis_rx_last => s_axis_rx_last,
    s_axis_rx_tkeep => s_axis_rx_tkeep,
    m_axis_tx_aclk => m_axis_tx_aclk,
    m_axis_tx_resetn => m_axis_tx_resetn,
    m_axis_tx_ready => m_axis_tx_ready,
    m_axis_tx_valid => m_axis_tx_valid,
    m_axis_tx_data => m_axis_tx_data,
    m_axis_tx_last => m_axis_tx_last,
    m_axis_tx_tkeep => m_axis_tx_tkeep,
    s_axis_tx_aclk => s_axis_tx_aclk,
    s_axis_tx_resetn => s_axis_tx_resetn,
    s_axis_tx_ready => s_axis_tx_ready,
    s_axis_tx_valid => s_axis_tx_valid,
    s_axis_tx_data => s_axis_tx_data,
    s_axis_tx_last => s_axis_tx_last,
    s_axis_tx_tkeep => s_axis_tx_tkeep,
    rx_init_req => rx_init_req,
    rx_init_ack => rx_init_ack,
    rx_sync_ext => rx_sync_ext,
    tx_init_req => tx_init_req,
    tx_init_ack => tx_init_ack,
    tx_sync_ext => tx_sync_ext,
    axi_clk => axi_clk,
    axi_resetn => axi_resetn,
    axi_awvalid => axi_awvalid,
    axi_awid => axi_awid,
    axi_awburst => axi_awburst,
    axi_awlock => axi_awlock,
    axi_awcache => axi_awcache,
    axi_awprot => axi_awprot,
    axi_awqos => axi_awqos,
    axi_awlen => axi_awlen,
    axi_awsize => axi_awsize,
    axi_awaddr => axi_awaddr,
    axi_awready => axi_awready,
    axi_wvalid => axi_wvalid,
    axi_wdata => axi_wdata,
    axi_wstrb => axi_wstrb,
    axi_wlast => axi_wlast,
    axi_wready => axi_wready,
    axi_bvalid => axi_bvalid,
    axi_bid => axi_bid,
    axi_bresp => axi_bresp,
    axi_bready => axi_bready,
    axi_arvalid => axi_arvalid,
    axi_arid => axi_arid,
    axi_arburst => axi_arburst,
    axi_arlock => axi_arlock,
    axi_arcache => axi_arcache,
    axi_arprot => axi_arprot,
    axi_arqos => axi_arqos,
    axi_arlen => axi_arlen,
    axi_arsize => axi_arsize,
    axi_araddr => axi_araddr,
    axi_arready => axi_arready,
    axi_rvalid => axi_rvalid,
    axi_rready => axi_rready,
    axi_rid => axi_rid,
    axi_rresp => axi_rresp,
    axi_rlast => axi_rlast,
    axi_rdata => axi_rdata
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

