
# facc_5g cores

  ad_ip_instance harden_tx_top adrv9009_harden_tx_top

  ad_ip_parameter adrv9009_harden_tx_top CONFIG.CP_LEN1 352
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.CP_LEN2 288
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.EXP_MASK 8388606
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.FFT_SIZE 4096
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.SC_NUM 3276
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.COEF_NUM 28    
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.STATUS_NUM 8   

  ad_ip_instance harden_rx_top adrv9009_harden_rx_top

  ad_ip_parameter adrv9009_harden_rx_top CONFIG.CP_LEN1 352
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.CP_LEN2 288
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.EXP_MASK 8388606
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.FFT_SIZE 4096
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.SC_NUM 3276
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.COEF_NUM 28
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.STATUS_NUM 3
  

  ad_ip_instance tddc_sync adrv9009_tddc_sync
  ad_ip_parameter adrv9009_tddc_sync CONFIG.ADDRESS_WIDTH 10
  ad_ip_parameter adrv9009_tddc_sync CONFIG.AXI_ADDRESS_WIDTH 12
  ad_ip_parameter adrv9009_tddc_sync CONFIG.WORD_QTY 52
  

  ad_ip_instance pack pack

  ad_ip_parameter pack CONFIG.ANTE_NUM 4
  ad_ip_parameter pack CONFIG.ARBIT_LEVEL 2
  ad_ip_parameter pack CONFIG.DATA_1G_WIDTH 32
  ad_ip_parameter pack CONFIG.PACKET_ANTE_NUM 1
  ad_ip_parameter pack CONFIG.SC_NUM 3276

  ad_ip_instance unpack unpack
  ad_ip_parameter unpack CONFIG.DATA_BIG_ENDIAN 1

  ad_ip_instance aximm_inout aximm_inout
  ad_ip_parameter aximm_inout CONFIG.ADDRESS_WIDTH 10
  ad_ip_parameter aximm_inout CONFIG.AXI_ADDRESS_WIDTH 12
  ad_ip_parameter aximm_inout CONFIG.WORD_QTY 100

  ad_ip_instance dma_inter dma_interconnct
  ad_ip_instance jesd_looback jesd_looback
  

    # Create instance: axi_10g_ethernet_0, and set properties
  set xg_ethernet [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 xg_ethernet ]
  set_property -dict [ list \
   CONFIG.MAC_and_BASER_32 {64bit} \
   CONFIG.Management_Frequency {100} \
   CONFIG.SupportLevel {1} \
 ] $xg_ethernet

  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   CONFIG.ASSOCIATED_BUSIF {m_axis_rx:s_axis_pause:s_axis_tx} \
   CONFIG.ASSOCIATED_ASYNC_RESET {tx_axis_aresetn:rx_axis_aresetn} \
 ] [get_bd_pins /xg_ethernet/coreclk_out]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
 ] [get_bd_pins /xg_ethernet/qplloutrefclk_out]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {322265625} \
 ] [get_bd_pins /xg_ethernet/rxrecclk_out]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {322265625} \
 ] [get_bd_pins /xg_ethernet/txusrclk2_out]

  set_property -dict [ list \
   CONFIG.FREQ_HZ {322265625} \
 ] [get_bd_pins /xg_ethernet/txusrclk_out]

  # Create instance: axis_data_rx_fifo, and set properties
  set axis_data_rx_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_rx_fifo ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {8} \
 ] $axis_data_rx_fifo

  # Create instance: axis_data_tx_fifo, and set properties
  set axis_data_tx_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_tx_fifo ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {8192} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {8} \
 ] $axis_data_tx_fifo

  # pll cores
  #ad_ip_instance clk_wiz fast_pll
  #ad_ip_parameter fast_pll CONFIG.REF_CLK_FREQ {122.88}
  #ad_ip_parameter fast_pll CONFIG.PRIMITIVE {PLL}
  #ad_ip_parameter fast_pll CONFIG.CLKOUT1_USED {true}
  #ad_ip_parameter fast_pll CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {245.76}
  #ad_ip_parameter fast_pll CONFIG.CLKOUT2_USED {true}
  #ad_ip_parameter fast_pll CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {153.6 }
  #ad_ip_parameter fast_pll CONFIG.RESET_TYPE {ACTIVE_LOW}

   set fast_pll [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 fast_pll ]
   set_property -dict [ list \
    CONFIG.CLKIN1_JITTER_PS {81.38} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {106.280} \
    CONFIG.CLKOUT1_PHASE_ERROR {98.137} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {245.760} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {102.955} \
    CONFIG.CLKOUT2_PHASE_ERROR {84.619} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {153.600} \
    CONFIG.CLKOUT2_USED {false} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT4_DRIVES {BUFG} \
    CONFIG.CLKOUT5_DRIVES {BUFG} \
    CONFIG.CLKOUT6_DRIVES {BUFG} \
    CONFIG.CLKOUT7_DRIVES {BUFG} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {8} \
    CONFIG.MMCM_CLKIN1_PERIOD {8.138} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {4} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {1} \
    CONFIG.MMCM_COMPENSATION {ZHOLD} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {1} \
    CONFIG.PRIMITIVE {PLL} \
    CONFIG.PRIM_IN_FREQ {122.880} \
    CONFIG.RESET_PORT {resetn} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    #CONFIG.CLKIN1_JITTER_PS {81.38} \
    #CONFIG.CLKOUT1_JITTER {100.432} \
    #CONFIG.CLKOUT1_PHASE_ERROR {92.130} \
    #CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {245.760} \
    #CONFIG.CLKOUT2_JITTER {109.689} \
    #CONFIG.CLKOUT2_PHASE_ERROR {92.130} \
    #CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {153.600} \
    #CONFIG.CLKOUT2_USED {true} \
    #CONFIG.MMCM_CLKFBOUT_MULT_F {8.750} \
    #CONFIG.MMCM_CLKIN1_PERIOD {8.138} \
    #CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
    #CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.375} \
    #CONFIG.MMCM_CLKOUT1_DIVIDE {7} \
    #CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    #CONFIG.NUM_OUT_CLKS {2} \
    #CONFIG.PRIM_IN_FREQ {122.880} \
    #CONFIG.RESET_PORT {resetn} \
    #CONFIG.RESET_TYPE {ACTIVE_LOW} \
  ] $fast_pll

  # I/O  port
  create_bd_port -dir I pps_in
  create_bd_port -dir O rfio_ctrl
  #create_bd_port -dir O calib_enable
  create_bd_port -dir O rf_gpio_out
  #create_bd_port -dir O excalib_enable
  #create_bd_port -dir O gpio_excal_output

  create_bd_port -dir I xg_rxp
  create_bd_port -dir I xg_rxn
  create_bd_port -dir I xg_signal_detect
  create_bd_port -dir I xg_tx_fault
  create_bd_port -dir I xg_refclk_p
  create_bd_port -dir I xg_refclk_n
  create_bd_port -dir I xg_reset
  create_bd_port -dir o xg_txp
  create_bd_port -dir o xg_txn
  create_bd_port -dir o xg_tx_disable   
  create_bd_port -dir o tx_lcp            
  create_bd_port -dir o tx_trigger
  create_bd_port -dir o rx_lcp                           
  create_bd_port -dir o rx_trigger           
  

  # clock & reset connect

  ad_connect  axi_adrv9009_rx_clkgen/clk_0    fast_pll/clk_in1
  ad_connect  sys_cpu_resetn fast_pll/resetn

  ad_connect  fast_clk fast_pll/clk_out1
  ad_connect  eth_clk  xg_ethernet/coreclk_out

  ad_connect  eth_clk pack/clk
  ad_connect  eth_clk pack/clk_1g
  ad_connect  sys_cpu_resetn pack/rst_n
  ad_connect  eth_clk unpack/clk_in
  ad_connect  eth_clk unpack/clk_rd
  ad_connect  sys_cpu_resetn unpack/rst_n
  ad_connect  sys_cpu_clk aximm_inout/s_axi_aclk
  ad_connect  sys_cpu_resetn aximm_inout/s_axi_aresetn
  
  ad_connect  axi_adrv9009_rx_clkgen/clk_0    adrv9009_tddc_sync/clk
  ad_connect  sys_cpu_resetn                  adrv9009_tddc_sync/rst_n
  ad_connect  sys_cpu_clk                     adrv9009_tddc_sync/s_axi_aclk
  ad_connect  sys_cpu_resetn                  adrv9009_tddc_sync/s_axi_aresetn
  #ad_connect  pack/avalon_dout unpack/avalon_din

  ad_connect  axi_adrv9009_tx_clkgen/clk_0    adrv9009_harden_tx_top/link_clk
  ad_connect  eth_clk        adrv9009_harden_tx_top/eth_clk
  ad_connect  fast_clk       adrv9009_harden_tx_top/fast_clk
  ad_connect  sys_cpu_resetn adrv9009_harden_tx_top/rst_n
  ad_connect  axi_adrv9009_rx_clkgen/clk_0    adrv9009_harden_rx_top/link_clk
  ad_connect  eth_clk        adrv9009_harden_rx_top/eth_clk
  ad_connect  fast_clk       adrv9009_harden_rx_top/fast_clk
  ad_connect  sys_cpu_resetn adrv9009_harden_rx_top/rst_n

  ad_connect  axi_adrv9009_tx_clkgen/clk_0    dma_interconnct/tx_link_clk
  ad_connect  axi_adrv9009_rx_clkgen/clk_0    dma_interconnct/rx_link_clk
  ad_connect  eth_clk        dma_interconnct/eth_clk
  ad_connect  fast_clk       dma_interconnct/fast_clk
  ad_connect  sys_cpu_resetn dma_interconnct/rst_n

  ad_connect  axi_adrv9009_tx_clkgen/clk_0    jesd_looback/tx_link_clk
  ad_connect  axi_adrv9009_rx_clkgen/clk_0    jesd_looback/rx_link_clk
  ad_connect  sys_cpu_resetn                  jesd_looback/rst_n
  ad_connect  aximm_inout/harden_rx_ctrl      jesd_looback/enable

    # connections (facc_ip)

  ad_connect  aximm_inout/harden_tx_ctrl adrv9009_harden_tx_top/gp_control
  ad_connect  aximm_inout/tx_gp_status   adrv9009_harden_tx_top/gp_status  
  ad_connect  aximm_inout/tx_phs_coef    adrv9009_harden_tx_top/phs_coef 
  
  ad_connect  aximm_inout/harden_rx_ctrl adrv9009_harden_rx_top/gp_control
  ad_connect  aximm_inout/rx_gp_status   adrv9009_harden_rx_top/gp_status   
  ad_connect  aximm_inout/rx_phs_coef    adrv9009_harden_rx_top/phs_coef 
     
  ad_connect  aximm_inout/harden_tx_ctrl dma_interconnct/tx_gp_control
  ad_connect  aximm_inout/harden_rx_ctrl dma_interconnct/rx_gp_control
  ad_connect  aximm_inout/mac_addr       pack/mac_addr 
  ad_connect  rfio_ctrl                  aximm_inout/rfio_ctrl
  ad_connect  aximm_inout/unpack_ctrl    unpack/loopback_ctrl

  ad_connect  pack/xg_m_axis               axis_data_tx_fifo/S_AXIS
  ad_connect  axis_data_rx_fifo/M_AXIS     unpack/xg_s_axis
  ad_connect  adrv9009_tddc_sync/slot_cnt  pack/timing_slot_index
  ad_connect  adrv9009_tddc_sync/frame_cnt pack/timing_frame_index
  ad_connect  adrv9009_tddc_sync/irq_1ms   pack/irq_1ms
  ad_connect  pack/pusch_ante   adrv9009_harden_rx_top/pusch_ante
  ad_connect  unpack/pdsch_ante adrv9009_harden_tx_top/pdsch_ante
  
  ad_connect  adrv9009_tddc_sync/tx_long_cp adrv9009_harden_tx_top/long_cp
  ad_connect  adrv9009_tddc_sync/tx_trigger adrv9009_harden_tx_top/trigger
  ad_connect  adrv9009_tddc_sync/symbol_cnt adrv9009_harden_tx_top/sync_symbol
  ad_connect  adrv9009_tddc_sync/slot_cnt   adrv9009_harden_tx_top/sync_slot
  ad_connect  adrv9009_tddc_sync/frame_cnt  adrv9009_harden_tx_top/sync_frame
  
  ad_connect  adrv9009_tddc_sync/rx_long_cp adrv9009_harden_rx_top/long_cp
  ad_connect  adrv9009_tddc_sync/rx_trigger adrv9009_harden_rx_top/trigger
  ad_connect  adrv9009_tddc_sync/symbol_cnt adrv9009_harden_rx_top/sync_symbol
  ad_connect  adrv9009_tddc_sync/slot_cnt   adrv9009_harden_rx_top/sync_slot
  ad_connect  adrv9009_tddc_sync/frame_cnt  adrv9009_harden_rx_top/sync_frame   
  
  ad_connect  tx_lcp           adrv9009_tddc_sync/tx_long_cp                
  ad_connect  tx_trigger       adrv9009_tddc_sync/tx_trigger             
  ad_connect  rx_lcp           adrv9009_tddc_sync/rx_long_cp             
  ad_connect  rx_trigger       adrv9009_tddc_sync/rx_trigger             
  
  
  ad_connect  pps_in      adrv9009_tddc_sync/pps_in
  ad_connect  adrv9009_harden_rx_top/m_axis_fast dma_interconnct/s_rx_axis_fast
  ad_connect  adrv9009_harden_rx_top/m_axis_eth  dma_interconnct/s_rx_axis_eth
  ad_connect  adrv9009_harden_rx_top/m_axis_link dma_interconnct/s_rx_axis_link
  ad_connect  adrv9009_harden_tx_top/m_axis_fast dma_interconnct/s_tx_axis_fast
  ad_connect  adrv9009_harden_tx_top/m_axis_link dma_interconnct/s_tx_axis_link
  set_property CONFIG.FREQ_HZ 245760000 [get_bd_intf_pins /dma_interconnct/s_tx_axis_fast]
  set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_pins /dma_interconnct/s_tx_axis_link]
  set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_pins /dma_interconnct/s_rx_axis_eth]
  set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_pins /pack/xg_m_axis]
  set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_pins /unpack/xg_s_axis]
  set_property CONFIG.FREQ_HZ 245760000 [get_bd_intf_pins /dma_interconnct/s_rx_axis_fast]
  set_property CONFIG.FREQ_HZ 122880000 [get_bd_intf_pins /dma_interconnct/s_rx_axis_link]
  set_property CONFIG.FREQ_HZ 122880000 [get_bd_pins /util_adrv9009_xcvr/rx_out_clk_0]

  #set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_pins /fast_pll/clk_in1]
  #set_property CONFIG.FREQ_HZ 122880000 [get_bd_intf_pins /axi_adrv9009_rx_clkgen/clk_0]

  ad_connect  adrv9009_harden_tx_top/dma_out_valid   adrv9009_harden_rx_top/dma_in_valid

  ad_connect  axi_adrv9009_tx_dma/fifo_rd_valid  adrv9009_harden_tx_top/fifo_rd_valid
  ad_connect  adrv9009_harden_tx_top/dac_valid   util_adrv9009_tx_upack/dac_valid
  ad_connect  adrv9009_harden_tx_top/fifo_rd_en  axi_adrv9009_tx_dma/fifo_rd_en

  ad_connect  dma_interconnct/fifo_wr_sync           axi_adrv9009_rx_dma/fifo_wr_sync
  ad_connect  dma_interconnct/fifo_wr_en             axi_adrv9009_rx_dma/fifo_wr_en
  ad_connect  dma_interconnct/fifo_wr_data           axi_adrv9009_rx_dma/fifo_wr_din

  ad_connect  util_adrv9009_tx_upack/dac_valid_0       adrv9009_harden_tx_top/valid_out_i0
  ad_connect  util_adrv9009_tx_upack/dac_enable_0      adrv9009_harden_tx_top/enable_out_i0
  ad_connect  util_adrv9009_tx_upack/dac_data_0        adrv9009_harden_tx_top/data_in_i0
  ad_connect  util_adrv9009_tx_upack/dac_valid_1       adrv9009_harden_tx_top/valid_out_q0
  ad_connect  util_adrv9009_tx_upack/dac_enable_1      adrv9009_harden_tx_top/enable_out_q0
  ad_connect  util_adrv9009_tx_upack/dac_data_1        adrv9009_harden_tx_top/data_in_q0
  ad_connect  util_adrv9009_tx_upack/dac_valid_2       adrv9009_harden_tx_top/valid_out_i1
  ad_connect  util_adrv9009_tx_upack/dac_enable_2      adrv9009_harden_tx_top/enable_out_i1
  ad_connect  util_adrv9009_tx_upack/dac_data_2        adrv9009_harden_tx_top/data_in_i1
  ad_connect  util_adrv9009_tx_upack/dac_valid_3       adrv9009_harden_tx_top/valid_out_q1
  ad_connect  util_adrv9009_tx_upack/dac_enable_3      adrv9009_harden_tx_top/enable_out_q1
  ad_connect  util_adrv9009_tx_upack/dac_data_3        adrv9009_harden_tx_top/data_in_q1

  ad_connect  adrv9009_harden_tx_top/valid_in_i0       axi_adrv9009_core/dac_valid_i0
  ad_connect  adrv9009_harden_tx_top/enable_in_i0      axi_adrv9009_core/dac_enable_i0
  ad_connect  adrv9009_harden_tx_top/data_out_i0       axi_adrv9009_core/dac_data_i0
  ad_connect  adrv9009_harden_tx_top/valid_in_q0       axi_adrv9009_core/dac_valid_q0
  ad_connect  adrv9009_harden_tx_top/enable_in_q0      axi_adrv9009_core/dac_enable_q0
  ad_connect  adrv9009_harden_tx_top/data_out_q0       axi_adrv9009_core/dac_data_q0
  ad_connect  adrv9009_harden_tx_top/valid_in_i1       axi_adrv9009_core/dac_valid_i1
  ad_connect  adrv9009_harden_tx_top/enable_in_i1      axi_adrv9009_core/dac_enable_i1
  ad_connect  adrv9009_harden_tx_top/data_out_i1       axi_adrv9009_core/dac_data_i1
  ad_connect  adrv9009_harden_tx_top/valid_in_q1       axi_adrv9009_core/dac_valid_q1
  ad_connect  adrv9009_harden_tx_top/enable_in_q1      axi_adrv9009_core/dac_enable_q1
  ad_connect  adrv9009_harden_tx_top/data_out_q1       axi_adrv9009_core/dac_data_q1

  ad_connect  adrv9009_harden_tx_top/dma_out_valid     jesd_looback/dma_in_valid
  ad_connect  adrv9009_harden_tx_top/data_out_i0       jesd_looback/dac_din_0
  ad_connect  adrv9009_harden_tx_top/data_out_q0       jesd_looback/dac_din_1
  ad_connect  adrv9009_harden_tx_top/data_out_i1       jesd_looback/dac_din_2
  ad_connect  adrv9009_harden_tx_top/data_out_q1       jesd_looback/dac_din_3


  ad_connect  axi_adrv9009_core/adc_enable_i0          adrv9009_harden_rx_top/adc_enable_0
  ad_connect  axi_adrv9009_core/adc_valid_i0           adrv9009_harden_rx_top/adc_valid_0
  ad_connect  axi_adrv9009_core/adc_data_i0            jesd_looback/adc_din_0
  ad_connect  axi_adrv9009_core/adc_enable_q0          adrv9009_harden_rx_top/adc_enable_1
  ad_connect  axi_adrv9009_core/adc_valid_q0           adrv9009_harden_rx_top/adc_valid_1
  ad_connect  axi_adrv9009_core/adc_data_q0            jesd_looback/adc_din_1
  ad_connect  axi_adrv9009_core/adc_enable_i1          adrv9009_harden_rx_top/adc_enable_2
  ad_connect  axi_adrv9009_core/adc_valid_i1           adrv9009_harden_rx_top/adc_valid_2
  ad_connect  axi_adrv9009_core/adc_data_i1            jesd_looback/adc_din_2
  ad_connect  axi_adrv9009_core/adc_enable_q1          adrv9009_harden_rx_top/adc_enable_3
  ad_connect  axi_adrv9009_core/adc_valid_q1           adrv9009_harden_rx_top/adc_valid_3
  ad_connect  axi_adrv9009_core/adc_data_q1            jesd_looback/adc_din_3

   ad_connect  jesd_looback/adc_dout_0      adrv9009_harden_rx_top/adc_data_0
   ad_connect  jesd_looback/adc_dout_1      adrv9009_harden_rx_top/adc_data_1
   ad_connect  jesd_looback/adc_dout_2      adrv9009_harden_rx_top/adc_data_2
   ad_connect  jesd_looback/adc_dout_3      adrv9009_harden_rx_top/adc_data_3

   ad_connect  rf_gpio_out   adrv9009_tddc_sync/gpio_out
   

   #XG_Ethernet
   ad_connect  sys_cpu_clk                    xg_ethernet/dclk
   ad_connect  sys_cpu_clk                    xg_ethernet/s_axi_aclk
   ad_connect  xg_rxp                         xg_ethernet/rxp
   ad_connect  xg_rxn                         xg_ethernet/rxn
   ad_connect  xg_signal_detect               xg_ethernet/signal_detect
   ad_connect  xg_tx_fault                    xg_ethernet/tx_fault
   ad_connect  xg_refclk_p                    xg_ethernet/refclk_p
   ad_connect  xg_refclk_n                    xg_ethernet/refclk_n
   ad_connect  xg_reset                       xg_ethernet/reset
   ad_connect  xg_txp                         xg_ethernet/txp
   ad_connect  xg_txn                         xg_ethernet/txn
   ad_connect  xg_tx_disable                  xg_ethernet/tx_disable

   ad_connect  xg_ethernet/m_axis_rx          axis_data_rx_fifo/S_AXIS
   ad_connect  axis_data_tx_fifo/M_AXIS       xg_ethernet/s_axis_tx
   ad_connect  sys_cpu_resetn                 xg_ethernet/tx_axis_aresetn
   ad_connect  sys_cpu_resetn                 xg_ethernet/rx_axis_aresetn
   ad_connect  sys_cpu_resetn                 xg_ethernet/s_axi_aresetn

   ad_connect  eth_clk                        axis_data_tx_fifo/s_axis_aclk
   ad_connect  sys_cpu_resetn                 axis_data_tx_fifo/s_axis_aresetn

   ad_connect  eth_clk                        axis_data_rx_fifo/s_axis_aclk
   ad_connect  sys_cpu_resetn                 axis_data_rx_fifo/s_axis_aresetn

   ad_cpu_interconnect 0x43c30000 aximm_inout
   ad_cpu_interconnect 0x43c40000 xg_ethernet
   ad_cpu_interconnect 0x43c50000 adrv9009_tddc_sync