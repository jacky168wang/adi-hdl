// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  inout       [14:0]      ddr_addr,
  inout       [ 2:0]      ddr_ba,
  inout                   ddr_cas_n,
  inout                   ddr_ck_n,
  inout                   ddr_ck_p,
  inout                   ddr_cke,
  inout                   ddr_cs_n,
  inout       [ 3:0]      ddr_dm,
  inout       [31:0]      ddr_dq,
  inout       [ 3:0]      ddr_dqs_n,
  inout       [ 3:0]      ddr_dqs_p,
  inout                   ddr_odt,
  inout                   ddr_ras_n,
  inout                   ddr_reset_n,
  inout                   ddr_we_n,

  inout                   fixed_io_ddr_vrn,
  inout                   fixed_io_ddr_vrp,
  inout       [53:0]      fixed_io_mio,
  inout                   fixed_io_ps_clk,
  inout                   fixed_io_ps_porb,
  inout                   fixed_io_ps_srstb,

  inout       [14:0]      gpio_bd,

//output                  hdmi_out_clk,
//output                  hdmi_vsync,
//output                  hdmi_hsync,
//output                  hdmi_data_e,
//output      [23:0]      hdmi_data,

//output                  spdif,

  inout                   iic_scl,
  inout                   iic_sda,

  input                   ref_clk0_p,
  input                   ref_clk0_n,
  input                   ref_clk1_p,
  input                   ref_clk1_n,
  input       [ 3:0]      rx_data_p,
  input       [ 3:0]      rx_data_n,
  output      [ 3:0]      tx_data_p,
  output      [ 3:0]      tx_data_n,
  output                  rx_sync_p,
  output                  rx_sync_n,
  output                  rx_os_sync_p,
  output                  rx_os_sync_n,
  input                   tx_sync_p,
  input                   tx_sync_n,
  input                   tx_sync_1_p,
  input                   tx_sync_1_n,
  input                   sysref_p,
  input                   sysref_n,

  output                  sysref_out_p,
  output                  sysref_out_n,

  output                  spi_csn_ad9528,
  output                  spi_clk_ad9528,
  output                  spi_mosi_ad9528,
  input                   spi_miso_ad9528,

  output                  spi_csn_ad9544,
  output                  spi_clk_ad9544,
  output                  spi_mosi_ad9544,
  input                   spi_miso_ad9544,

  output                  spi_csn_adrv9009,
  output                  spi_clk_adrv9009,
  output                  spi_mosi_adrv9009,
  input                   spi_miso_adrv9009,

  inout                   ad9528_reset_b,
  inout                   ad9528_sysref_req,
  inout                   adrv9009_tx1_enable,
  inout                   adrv9009_tx2_enable,
  inout                   adrv9009_rx1_enable,
  inout                   adrv9009_rx2_enable,
  inout                   adrv9009_test,
  inout                   adrv9009_reset_b,
  inout                   adrv9009_gpint,

  inout                   adrv9009_gpio_00,
  inout                   adrv9009_gpio_01,
  inout                   adrv9009_gpio_02,
  inout                   adrv9009_gpio_03,
  inout                   adrv9009_gpio_04,
  inout                   adrv9009_gpio_05,
  inout                   adrv9009_gpio_06,
  inout                   adrv9009_gpio_07,
  inout                   adrv9009_gpio_15,
  inout                   adrv9009_gpio_08,
  inout                   adrv9009_gpio_09,
  inout                   adrv9009_gpio_10,
  inout                   adrv9009_gpio_11,
  inout                   adrv9009_gpio_12,
  inout                   adrv9009_gpio_14,
  inout                   adrv9009_gpio_13,
  inout                   adrv9009_gpio_17,
  inout                   adrv9009_gpio_16,
  inout                   adrv9009_gpio_18,
  
  // RFFC rf frond-end  io 13bit
  output                  GPIO_TX_CAL      , //tdd_gpio_out[26] 
//output                  GPIO_RF_SW_PHACAL, //tdd_gpio_out[25]
  output                  GPIO_UA_TR1_A    , //tdd_gpio_out[24]
  output                  GPIO_UA_TR1_SW   , //tdd_gpio_out[23]
  output                  GPIO_UA_TR2_A    , //tdd_gpio_out[22]
  output                  GPIO_UA_TR2_SW   , //tdd_gpio_out[21]
//output                  GPIO_UB_TR1_A    , //tdd_gpio_out[20]
//output                  GPIO_UB_TR1_SW   , //tdd_gpio_out[19]
//output                  GPIO_UB_TR2_A    , //tdd_gpio_out[18]
//output                  GPIO_UB_TR2_SW   , //tdd_gpio_out[17]
//output                  GPIO_RF_SW_ORX   , //tdd_gpio_out[16]
  output                  GPIO_SP4T_V1     , //tdd_gpio_out[15]
  output                  GPIO_SP4T_V2     , //tdd_gpio_out[14]
  
  input                   pps_in_dfb       , //pps from dfb 
  input                   pps_in_rfb       , //pps from rfb   
  output                  pm_power_enable  ,
  output                  pa_power_enable  ,          

  //10g    interface                         
  input                  sys_rst,            
  input                  xg_refclk_n,        
  input 			           xg_refclk_p,        
                                             
  output                 xg_txn,             
  output                 xg_txp,             
  input                  xg_rxn,             
  input                  xg_rxp, 
  output                 xg_tx_disable, 

  output                 tx_trigger ,
  output                 tx_lcp     ,
  output                 rx_trigger ,
  output                 rx_lcp                       

  );

//input                   sys_rst,
//input                   sys_clk_p,
//input                   sys_clk_n,

//output      [14:0]      ddr3_addr,
//output      [ 2:0]      ddr3_ba,
//output                  ddr3_cas_n,
//output      [ 0:0]      ddr3_ck_n,
//output      [ 0:0]      ddr3_ck_p,
//output      [ 0:0]      ddr3_cke,
//output      [ 0:0]      ddr3_cs_n,
//output      [ 7:0]      ddr3_dm,
//inout       [63:0]      ddr3_dq,
//inout       [ 7:0]      ddr3_dqs_n,
//inout       [ 7:0]      ddr3_dqs_p,
//output      [ 0:0]      ddr3_odt,
//output                  ddr3_ras_n,
//output                  ddr3_reset_n,
//output                  ddr3_we_n);

  // internal signals

  wire                    spi_clk;
  wire                    spi_mosi;
  wire                    spi_miso;

  wire                    n2_spi_clk;
  wire                    n2_spi_mosi;
  wire                    n2_spi_miso;

  wire        [63:0]      gpio_i;
  wire        [63:0]      gpio_o;
  wire        [63:0]      gpio_t;
  wire                    ref_clk0;
  wire                    ref_clk1;
  wire                    rx_sync;
  wire                    rx_os_sync;
  wire                    tx_sync;
  wire                    tx_sync_1;
  wire                    sysref;
  wire                    sysref_out;
  

  assign spi_clk_ad9528 = spi_clk;
  assign spi_clk_adrv9009 = spi_clk;
  assign spi_mosi_ad9528 = spi_mosi;
  assign spi_mosi_adrv9009 = spi_mosi;
  assign spi_miso = spi_miso_ad9528 & spi_miso_adrv9009;

  assign spi_clk_ad9544 = n2_spi_clk;
  assign spi_mosi_ad9544 = n2_spi_mosi;
  assign n2_spi_miso = spi_miso_ad9544;

  assign gpio_i[63:60] = gpio_o[63:60];
  assign gpio_i[31:15] = gpio_o[31:15];

  assign sysref_out = 0;
  assign pm_power_enable = 1;
  assign xg_tx_disable = 1;
   
 //======================================================================                                                                                                               
 //                       inside 1pps  generator                                                                                                                                               
 //======================================================================  
                                                                                                                         
  // 1pps                                                                                                                                                                               
    parameter PPS_CLK_FREQ = 122880000;  
    wire      pps_in_outside ;                                                                                                                                               
    reg [26:0] pps_clk_cnt;  
                                                                                                                                                               
    assign pps_in_outside = pps_in_dfb | pps_in_rfb ;                                                                                                                                                                                    
    assign pps_in_inside  = pps_clk_cnt >= (PPS_CLK_FREQ / 100) * 99;                                                                                                                           
                                                                                                                                                                                        
    always @ ( posedge ref_clk1 ) begin                                                                                                                                                  
       if (pps_clk_cnt == PPS_CLK_FREQ - 1) begin                                                                                                                                       
            pps_clk_cnt <= 0;                                                                                                                                                           
        end                                                                                                                                                                             
        else begin                                                                                                                                                                        
            pps_clk_cnt <= pps_clk_cnt + 1'b1;                                                                                                                                            
        end                                                                                                                                                                               
    end   
  
  /********************************************************************/ 
  //rfio_ctrl assign                                                           
  wire [31:0] rfio_ctrl ; 
  wire    pps_in ; 
  assign  pps_in = rfio_ctrl[0] ? pps_in_inside : pps_in_outside ;
  assign  pa_power_enable = rfio_ctrl[4]; 
  wire    arm_tdd_enable = rfio_ctrl[8];       
    
 /***************************************************************************/
 // tdd gpio_out 
  wire   [31:0]tdd_gpio_output;  
  
  wire    adrv9009_tx1_enable_from_arm;       
  wire    adrv9009_tx2_enable_from_arm;       
  wire    adrv9009_rx1_enable_from_arm;       
  wire    adrv9009_rx2_enable_from_arm;                                                     
  wire    adrv9009_gpio_09_from_arm;          
  wire    adrv9009_gpio_04_from_arm;          
  wire    adrv9009_gpio_05_from_arm;  
  
  assign    GPIO_TX_CAL           =    tdd_gpio_output[26]  ;
//assign    GPIO_RF_SW_PHACAL     =    tdd_gpio_output[25]  ;
  assign    GPIO_UA_TR1_A         =    tdd_gpio_output[24]  ;
  assign    GPIO_UA_TR1_SW        =    tdd_gpio_output[23]  ;
  assign    GPIO_UA_TR2_A         =    tdd_gpio_output[22]  ;
  assign    GPIO_UA_TR2_SW        =    tdd_gpio_output[21]  ;
//assign    GPIO_UB_TR1_A         =    tdd_gpio_output[20]  ;
//assign    GPIO_UB_TR1_SW        =    tdd_gpio_output[19]  ;
//assign    GPIO_UB_TR2_A         =    tdd_gpio_output[18]  ;
//assign    GPIO_UB_TR2_SW        =    tdd_gpio_output[17]  ;
//assign    GPIO_RF_SW_ORX        =    tdd_gpio_output[16]  ;
  assign    GPIO_SP4T_V1          =    tdd_gpio_output[15]  ;
  assign    GPIO_SP4T_V2          =    tdd_gpio_output[14]  ;
   
  assign    adrv9009_tx1_enable   =    arm_tdd_enable ? adrv9009_tx1_enable_from_arm  :  tdd_gpio_output[13]  ;
  assign    adrv9009_tx2_enable   =    arm_tdd_enable ? adrv9009_tx2_enable_from_arm  :  tdd_gpio_output[12]  ;     
  assign    adrv9009_rx1_enable   =    arm_tdd_enable ? adrv9009_rx1_enable_from_arm  :  tdd_gpio_output[ 9]  ;
  assign    adrv9009_rx2_enable   =    arm_tdd_enable ? adrv9009_rx2_enable_from_arm  :  tdd_gpio_output[ 8]  ;                                                                                           
  assign    adrv9009_gpio_09      =    arm_tdd_enable ? adrv9009_gpio_09_from_arm     :  tdd_gpio_output[ 5]  ;      //ORX1_ENABLE_UA  
  assign    adrv9009_gpio_04      =    arm_tdd_enable ? adrv9009_gpio_04_from_arm     :  tdd_gpio_output[ 3]  ;      //ORX1_TX_SEL1_UA
  assign    adrv9009_gpio_05      =    arm_tdd_enable ? adrv9009_gpio_05_from_arm     :  tdd_gpio_output[ 2]  ;      //ORX1_TX_SEL0_UA
                                      
 /*****************************************************************************************/
  // instantiations

  IBUFDS_GTE2 i_ibufds_rx_ref_clk (
    .CEB (1'd0),
    .I (ref_clk0_p),
    .IB (ref_clk0_n),
    .O (ref_clk0),
    .ODIV2 ());

  IBUFDS_GTE2 i_ibufds_ref_clk1 (
    .CEB (1'd0),
    .I (ref_clk1_p),
    .IB (ref_clk1_n),
    .O (ref_clk1),
    .ODIV2 ());

  OBUFDS i_obufds_rx_sync (
    .I (rx_sync),
    .O (rx_sync_p),
    .OB (rx_sync_n));

  OBUFDS i_obufds_rx_os_sync (
    .I (rx_os_sync),
    .O (rx_os_sync_p),
    .OB (rx_os_sync_n));

  OBUFDS i_obufds_sysref_out (
    .I (sysref_out),
    .O (sysref_out_p),
    .OB (sysref_out_n));

  IBUFDS i_ibufds_tx_sync (
    .I (tx_sync_p),
    .IB (tx_sync_n),
    .O (tx_sync));

  IBUFDS i_ibufds_tx_sync_1 (
    .I (tx_sync_1_p),
    .IB (tx_sync_1_n),
    .O (tx_sync_1));

  IBUFDS i_ibufds_sysref (
    .I (sysref_p),
    .IB (sysref_n),
    .O (sysref));

  ad_iobuf #(.DATA_WIDTH(28)) i_iobuf (
    .dio_t ({gpio_t[59:32]}),
    .dio_i ({gpio_o[59:32]}),
    .dio_o ({gpio_i[59:32]}),
    .dio_p ({ ad9528_reset_b,       // 59
              ad9528_sysref_req,    // 58
              adrv9009_tx1_enable_from_arm,  // 57
              adrv9009_tx2_enable_from_arm,  // 5
              adrv9009_rx1_enable_from_arm,  // 55
              adrv9009_rx2_enable_from_arm,  // 54
              adrv9009_test,                 // 53
              adrv9009_reset_b,              // 52
              adrv9009_gpint,                // 51
              adrv9009_gpio_00,              // 50
              adrv9009_gpio_01,              // 49
              adrv9009_gpio_02,              // 48
              adrv9009_gpio_03,              // 47
              adrv9009_gpio_04_from_arm,     // 46
              adrv9009_gpio_05_from_arm,     // 45
              adrv9009_gpio_06,              // 44
              adrv9009_gpio_07,              // 43
              adrv9009_gpio_15,              // 42
              adrv9009_gpio_08,              // 41
              adrv9009_gpio_09_from_arm,     // 40
              adrv9009_gpio_10,              // 39
              adrv9009_gpio_11,              // 38
              adrv9009_gpio_12,              // 37
              adrv9009_gpio_14,              // 36
              adrv9009_gpio_13,              // 35
              adrv9009_gpio_17,              // 34
              adrv9009_gpio_16_from_arm,     // 33
              adrv9009_gpio_18}));           // 32

  ad_iobuf #(.DATA_WIDTH(15)) i_iobuf_bd (
    .dio_t (gpio_t[14:0]),
    .dio_i (gpio_o[14:0]),
    .dio_o (gpio_i[14:0]),
    .dio_p (gpio_bd));

  system_wrapper i_system_wrapper (
    .dac_fifo_bypass (gpio_o[60]),
  //.ddr3_addr (ddr3_addr),
  //.ddr3_ba (ddr3_ba),
  //.ddr3_cas_n (ddr3_cas_n),
  //.ddr3_ck_n (ddr3_ck_n),
  //.ddr3_ck_p (ddr3_ck_p),
  //.ddr3_cke (ddr3_cke),
  //.ddr3_cs_n (ddr3_cs_n),
  //.ddr3_dm (ddr3_dm),
  //.ddr3_dq (ddr3_dq),
  //.ddr3_dqs_n (ddr3_dqs_n),
  //.ddr3_dqs_p (ddr3_dqs_p),
  //.ddr3_odt (ddr3_odt),
  //.ddr3_ras_n (ddr3_ras_n),
  //.ddr3_reset_n (ddr3_reset_n),
  //.ddr3_we_n (ddr3_we_n),
    .ddr_addr (ddr_addr),
    .ddr_ba (ddr_ba),
    .ddr_cas_n (ddr_cas_n),
    .ddr_ck_n (ddr_ck_n),
    .ddr_ck_p (ddr_ck_p),
    .ddr_cke (ddr_cke),
    .ddr_cs_n (ddr_cs_n),
    .ddr_dm (ddr_dm),
    .ddr_dq (ddr_dq),
    .ddr_dqs_n (ddr_dqs_n),
    .ddr_dqs_p (ddr_dqs_p),
    .ddr_odt (ddr_odt),
    .ddr_ras_n (ddr_ras_n),
    .ddr_reset_n (ddr_reset_n),
    .ddr_we_n (ddr_we_n),
    .fixed_io_ddr_vrn (fixed_io_ddr_vrn),
    .fixed_io_ddr_vrp (fixed_io_ddr_vrp),
    .fixed_io_mio (fixed_io_mio),
    .fixed_io_ps_clk (fixed_io_ps_clk),
    .fixed_io_ps_porb (fixed_io_ps_porb),
    .fixed_io_ps_srstb (fixed_io_ps_srstb),
    .gpio_i (gpio_i),
    .gpio_o (gpio_o),
    .gpio_t (gpio_t),
  //.hdmi_data (hdmi_data),
  //.hdmi_data_e (hdmi_data_e),
  //.hdmi_hsync (hdmi_hsync),
  //.hdmi_out_clk (hdmi_out_clk),
  //.hdmi_vsync (hdmi_vsync),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .rx_data_0_n (rx_data_n[0]),
    .rx_data_0_p (rx_data_p[0]),
    .rx_data_1_n (rx_data_n[1]),
    .rx_data_1_p (rx_data_p[1]),
    .rx_data_2_n (rx_data_n[2]),
    .rx_data_2_p (rx_data_p[2]),
    .rx_data_3_n (rx_data_n[3]),
    .rx_data_3_p (rx_data_p[3]),
    .rx_ref_clk_0 (ref_clk1),
    .rx_ref_clk_2 (ref_clk1),
    .rx_sync_0 (rx_sync),
    .rx_sync_2 (rx_os_sync),
    .rx_sysref_0 (sysref),
    .rx_sysref_2 (sysref),
  //.spdif (spdif),
    .spi0_clk_i (spi_clk),
    .spi0_clk_o (spi_clk),
    .spi0_csn_0_o (spi_csn_ad9528),
    .spi0_csn_1_o (spi_csn_adrv9009),
    .spi0_csn_2_o (),
    .spi0_csn_i (1'b1),
    .spi0_sdi_i (spi_miso),
    .spi0_sdo_i (spi_mosi),
    .spi0_sdo_o (spi_mosi),
    .spi1_clk_i (n2_spi_clk),
    .spi1_clk_o (n2_spi_clk),
    .spi1_csn_0_o (spi_csn_ad9544),
    .spi1_csn_1_o (),
    .spi1_csn_2_o (),
    .spi1_csn_i (1'b1),
    .spi1_sdi_i (n2_spi_miso),
    .spi1_sdo_i (n2_spi_mosi),
    .spi1_sdo_o (n2_spi_mosi),
  //.sys_clk_clk_n (sys_clk_n),
  //.sys_clk_clk_p (sys_clk_p),
  //.sys_rst(sys_rst),
    .tx_data_0_n (tx_data_n[0]),
    .tx_data_0_p (tx_data_p[0]),
    .tx_data_1_n (tx_data_n[1]),
    .tx_data_1_p (tx_data_p[1]),
    .tx_data_2_n (tx_data_n[2]),
    .tx_data_2_p (tx_data_p[2]),
    .tx_data_3_n (tx_data_n[3]),
    .tx_data_3_p (tx_data_p[3]),
    .tx_ref_clk_0 (ref_clk1),
    .tx_sync_0 (tx_sync),
    .tx_sysref_0 (sysref),
    
    .rfio_ctrl       (rfio_ctrl      ),	
    .rf_gpio_out     (tdd_gpio_output),    	
    .pps_in          (pps_in         ),
    .xg_refclk_p     ( xg_refclk_p   ),
    .xg_refclk_n     ( xg_refclk_n   ),
    .xg_rxp          ( xg_rxp        ),          
    .xg_rxn          ( xg_rxn        ),                                                                         
    .xg_txp          ( xg_txp        ),          
    .xg_txn          ( xg_txn        ),
    .xg_reset        ( sys_rst       ),     
    .xg_tx_disable   (               ),
    .xg_signal_detect( 1'b1          ),
    .xg_tx_fault     ( 1'b0          ),
    .tx_trigger      ( tx_trigger    ),
    .tx_lcp          ( tx_lcp        ),
    .rx_trigger      ( rx_trigger    ),
    .rx_lcp          ( rx_lcp        )   
    );

endmodule

// ***************************************************************************
// ***************************************************************************
