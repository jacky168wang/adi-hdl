## facc_5g_bd.tcl
## auther : xj.z  version 3
## version 1   time : 2019.01.05 : harden_tx_top&rx,pack&unpack,aximm_inout,pll modules added.
## version 2   time : 2019.01.07 : 10g Ethernet module added.
## version 3   time : 2019.02.13 : harden_tx_top_top & harden_tx_top_top replaced harden_tx_top & harden_tx_top.

# facc_5g cores

# set xg_ethernet [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 xg_ethernet ]
# set_property -dict [ list \
#  CONFIG.Management_Frequency {200.00} \
#  CONFIG.base_kr	{BASE-R } \
#  CONFIG.MAC_and_BASER_32 {64bit} \
#  CONFIG.IEEE_1588 {None} \
#  CONFIG.Statistics_Gathering {true} \
#  CONFIG.DClkRate {100.00} \
#  CONFIG.RefClkRate {156.25} \
#  CONFIG.SupportLevel {1} \
#] $xg_ethernet

  ad_ip_instance harden_tx_top adrv9009_harden_tx_top
 
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.CP_LEN1 352
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.CP_LEN2 288
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.EXP_MASK 8388606
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.FFT_SIZE 4096
  ad_ip_parameter adrv9009_harden_tx_top CONFIG.SC_NUM 3276

  ad_ip_instance harden_rx_top adrv9009_harden_rx_top

  ad_ip_parameter adrv9009_harden_rx_top CONFIG.CP_LEN1 352
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.CP_LEN2 288
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.EXP_MASK 8388606
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.FFT_SIZE 4096
  ad_ip_parameter adrv9009_harden_rx_top CONFIG.SC_NUM 3276

  ad_ip_instance harden_sync adrv9009_harden_sync

  ad_ip_parameter adrv9009_harden_sync CONFIG.CP_LEN1 352
  ad_ip_parameter adrv9009_harden_sync CONFIG.CP_LEN2 288
  ad_ip_parameter adrv9009_harden_sync CONFIG.FFT_SIZE 4096

  ad_ip_instance pack pack

  ad_ip_parameter pack CONFIG.ANTE_NUM 4
  ad_ip_parameter pack CONFIG.ARBIT_LEVEL 2
  ad_ip_parameter pack CONFIG.DATA_1G_WIDTH 32
  ad_ip_parameter pack CONFIG.PACKET_ANTE_NUM 1
  ad_ip_parameter pack CONFIG.SC_NUM 3276

  ad_ip_instance unpack unpack

  ad_ip_instance aximm_inout aximm_inout

  ad_ip_parameter aximm_inout CONFIG.ADDRESS_WIDTH 5
  ad_ip_parameter aximm_inout CONFIG.AXI_ADDRESS_WIDTH 7
  ad_ip_parameter aximm_inout CONFIG.WORD_QTY 13
  
  ad_ip_instance axis_test axis_test

  # pll cores
  ad_ip_instance clk_wiz pll
  ad_ip_parameter pll CONFIG.REF_CLK_FREQ {100.0}
  ad_ip_parameter pll CONFIG.PRIMITIVE {PLL}
  ad_ip_parameter pll CONFIG.CLKOUT1_USED {true}
  ad_ip_parameter pll CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000}
  ad_ip_parameter pll CONFIG.CLKOUT2_USED {true}
  ad_ip_parameter pll CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {130.000}
  ad_ip_parameter pll CONFIG.CLKOUT3_USED {true}
  ad_ip_parameter pll CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000}
  ad_ip_parameter pll CONFIG.CLKOUT4_USED {true}
  ad_ip_parameter pll CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {50.000}
  ad_ip_parameter pll CONFIG.RESET_PORT {resetn}    
  ad_ip_parameter pll CONFIG.RESET_TYPE {ACTIVE_LOW}
    
  # Create instance: axis_interconnect, and set properties
  set axis_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 axis_interconnect ]
  set_property -dict [ list \
   CONFIG.ARB_ALGORITHM {2} \
   CONFIG.ARB_ON_TLAST {0} \
   CONFIG.M00_FIFO_DEPTH {4096} \
   CONFIG.M00_FIFO_MODE {1} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_FIFO_DEPTH {4096} \
   CONFIG.S00_FIFO_MODE {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.S01_FIFO_DEPTH {4096} \
   CONFIG.S01_FIFO_MODE {1} \
   CONFIG.S01_HAS_REGSLICE {1} \
   CONFIG.S02_FIFO_DEPTH {4096} \
   CONFIG.S02_FIFO_MODE {1} \
   CONFIG.S02_HAS_REGSLICE {1} \
   CONFIG.S03_FIFO_DEPTH {4096} \
   CONFIG.S03_FIFO_MODE {1} \
   CONFIG.S03_HAS_REGSLICE {1} \
 ] $axis_interconnect  
  
  # I/O

  create_bd_port -dir O top_clk
  create_bd_port -dir I pps_in

#  create_bd_port -dir I reset
#  create_bd_port -dir I xg_rxn
#  create_bd_port -dir I xg_rxp
#  create_bd_port -dir O xg_txn
#  create_bd_port -dir O xg_txp
#  create_bd_port -dir I xg_refclk_n
#  create_bd_port -dir I xg_refclk_p
#  
#  create_bd_port -dir O -from 127 -to 0 -type data data_out

  # system reset/clock definitions

  ad_connect  sys_cpu_clk pll/clk_in1
  ad_connect  sys_cpu_resetn pll/resetn

  ad_connect  fast_clk pll/clk_out1
  ad_connect  eth_clk pll/clk_out2
  ad_connect  top_clk pll/clk_out3

  ad_connect  eth_clk pack/clk
  ad_connect  eth_clk pack/clk_1g
  ad_connect  sys_cpu_resetn pack/rst_n
  ad_connect  eth_clk unpack/clk_in
  ad_connect  eth_clk unpack/clk_rd
  ad_connect  sys_cpu_resetn unpack/rst_n
  ad_connect  sys_cpu_clk aximm_inout/s_axi_aclk
  ad_connect  sys_cpu_resetn aximm_inout/s_axi_aresetn

  ad_connect  pack/avalon_dout unpack/avalon_din

  ad_connect  adrv9009_harden_sync/slot_cnt_abs  pack/timing_slot_index
  ad_connect  adrv9009_harden_sync/frame_cnt_abs pack/timing_frame_index
  ad_connect  adrv9009_harden_sync/irq_1ms       pack/irq_1ms
  ad_connect  aximm_inout/mac_addr               pack/mac_addr
  ad_connect  aximm_inout/sync_ctrl         adrv9009_harden_sync/sync_ctrl
  ad_connect  aximm_inout/tx_ahead_time     adrv9009_harden_sync/tx_ahead_time
  ad_connect  aximm_inout/tx_delay_time     adrv9009_harden_sync/tx_delay_time
  ad_connect  aximm_inout/rx_ahead_time     adrv9009_harden_sync/rx_ahead_time  
  ad_connect  aximm_inout/rx_delay_time     adrv9009_harden_sync/rx_delay_time


  ad_connect  aximm_inout/harden_tx_ctrl adrv9009_harden_tx_top/gp_control
  ad_connect  aximm_inout/harden_rx_ctrl adrv9009_harden_rx_top/gp_control

  # connections (facc_harden)

  ad_connect  sys_cpu_clk adrv9009_harden_tx_top/link_clk
  ad_connect  eth_clk adrv9009_harden_tx_top/eth_clk
  ad_connect  fast_clk adrv9009_harden_tx_top/fast_clk
  ad_connect  sys_cpu_resetn adrv9009_harden_tx_top/rst_sys_n
  ad_connect  sys_cpu_clk adrv9009_harden_rx_top/link_clk
  ad_connect  eth_clk adrv9009_harden_rx_top/eth_clk
  ad_connect  fast_clk adrv9009_harden_rx_top/fast_clk
  ad_connect  sys_cpu_resetn adrv9009_harden_rx_top/rst_sys_n
  ad_connect  pll/clk_out4 adrv9009_harden_sync/clk_tx
  ad_connect  sys_cpu_clk adrv9009_harden_sync/clk_rx
  ad_connect  sys_cpu_resetn adrv9009_harden_sync/rst_n
  
  ad_connect  sys_cpu_clk     axis_interconnect/ACLK
  ad_connect  sys_cpu_clk     axis_interconnect/M00_AXIS_ACLK
  ad_connect  fast_clk        axis_interconnect/S00_AXIS_ACLK  
  ad_connect  eth_clk         axis_interconnect/S01_AXIS_ACLK
  ad_connect  sys_cpu_resetn  axis_interconnect/ARESETN
  ad_connect  sys_cpu_resetn  axis_interconnect/M00_AXIS_ARESETN   
  ad_connect  sys_cpu_resetn  axis_interconnect/S00_AXIS_ARESETN
  ad_connect  sys_cpu_resetn  axis_interconnect/S01_AXIS_ARESETN 
  
  ad_connect  sys_cpu_clk     axis_test/link_clk 
  ad_connect  sys_cpu_resetn  axis_test/rst_n 
  
  
    
  ad_connect  pack/pusch_ante   adrv9009_harden_rx_top/pusch_ante
  ad_connect  unpack/pdsch_ante adrv9009_harden_tx_top/pdsch_ante
  ad_connect  adrv9009_harden_sync/sync_tx_ctrl adrv9009_harden_tx_top/sync_tx_ctrl
  ad_connect  adrv9009_harden_sync/sync_rx_ctrl adrv9009_harden_rx_top/sync_rx_ctrl
  ad_connect  pps_in adrv9009_harden_sync/pps_in 
  ad_connect  adrv9009_harden_rx_top/m_axis_fast axis_interconnect/S00_AXIS
  ad_connect  adrv9009_harden_rx_top/m_axis_eth  axis_interconnect/S01_AXIS
  ad_connect  axis_interconnect/M00_AXIS         axis_test/s_axis_link
  
  # connections (xg_ethernet)
#  ad_connect sys_cpu_resetn  xg_ethernet/reset
#  ad_connect xg_refclk_p     xg_ethernet/refclk_p
#  ad_connect xg_refclk_n     xg_ethernet/refclk_n
#  ad_connect pll/clk_out3    xg_ethernet/dclk
#  ad_connect xg_rxp          xg_ethernet/rxp
#  ad_connect xg_rxn          xg_ethernet/rxn
#  ad_connect sys_cpu_clk     xg_ethernet/s_axi_aclk
#  ad_connect sys_cpu_resetn  xg_ethernet/s_axi_aresetn
#  ad_connect sys_cpu_resetn  xg_ethernet/tx_axis_aresetn
#  ad_connect sys_cpu_resetn  xg_ethernet/rx_axis_aresetn
#  ad_connect xg_ethernet/txp xg_txp
#  ad_connect xg_ethernet/txn xg_txn  
#  ad_connect xg_ethernet/m_axis_rx xg_ethernet/s_axis_tx
 

#  # connect to adrv9009_bd.tcl
#
# for {set i 0} {$i < 4} {incr i} {
#
# ad_connect  adc_enable_$i  adrv9009_harden_tx_top/adc_enable_$i
# ad_connect  adc_valid_$i   adrv9009_harden_tx_top/adc_valid_$i
# ad_connect  adc_data_$i    adrv9009_harden_tx_top/adc_data_$i
# ad_connect  dac_enable_$i  adrv9009_harden_tx_top/dac_enable_$i
# ad_connect  dac_valid_$i   adrv9009_harden_tx_top/dac_valid_$i
# ad_connect  dac_data_$i    adrv9009_harden_tx_top/dac_data_$i
#}
#
## interconnects
#
ad_cpu_interconnect 0x43c30000  aximm_inout
#ad_cpu_interconnect 0x43c40000  xg_ethernet

  



