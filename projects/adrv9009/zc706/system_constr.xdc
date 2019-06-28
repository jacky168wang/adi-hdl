
# adrv9009

set_property -dict {PACKAGE_PIN AD10} [get_ports ref_clk0_p]
set_property -dict {PACKAGE_PIN AD9} [get_ports ref_clk0_n]
set_property -dict {PACKAGE_PIN AA8} [get_ports ref_clk1_p]
set_property -dict {PACKAGE_PIN AA7} [get_ports ref_clk1_n]
set_property -dict {PACKAGE_PIN AJ8} [get_ports {rx_data_p[0]}]
set_property -dict {PACKAGE_PIN AJ7} [get_ports {rx_data_n[0]}]
set_property -dict {PACKAGE_PIN AG8} [get_ports {rx_data_p[1]}]
set_property -dict {PACKAGE_PIN AG7} [get_ports {rx_data_n[1]}]
set_property -dict {PACKAGE_PIN AH10} [get_ports {rx_data_p[2]}]
set_property -dict {PACKAGE_PIN AH9} [get_ports {rx_data_n[2]}]
set_property -dict {PACKAGE_PIN AE8} [get_ports {rx_data_p[3]}]
set_property -dict {PACKAGE_PIN AE7} [get_ports {rx_data_n[3]}]
set_property -dict {PACKAGE_PIN AK6} [get_ports {tx_data_p[0]}]
set_property -dict {PACKAGE_PIN AK5} [get_ports {tx_data_n[0]}]
set_property -dict {PACKAGE_PIN AJ4} [get_ports {tx_data_p[1]}]
set_property -dict {PACKAGE_PIN AJ3} [get_ports {tx_data_n[1]}]
set_property -dict {PACKAGE_PIN AK10} [get_ports {tx_data_p[2]}]
set_property -dict {PACKAGE_PIN AK9} [get_ports {tx_data_n[2]}]
set_property -dict {PACKAGE_PIN AK2} [get_ports {tx_data_p[3]}]
set_property -dict {PACKAGE_PIN AK1} [get_ports {tx_data_n[3]}]
set_property -dict {PACKAGE_PIN AH19 IOSTANDARD LVDS_25} [get_ports rx_sync_p]
set_property -dict {PACKAGE_PIN AJ19 IOSTANDARD LVDS_25} [get_ports rx_sync_n]
set_property -dict {PACKAGE_PIN T29 IOSTANDARD LVDS_25} [get_ports rx_os_sync_p]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVDS_25} [get_ports rx_os_sync_n]
set_property -dict {PACKAGE_PIN AK17 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports tx_sync_p]
set_property -dict {PACKAGE_PIN AK18 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports tx_sync_n]
set_property -dict {PACKAGE_PIN AF20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports sysref_p]
set_property -dict {PACKAGE_PIN AG20 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports sysref_n]
set_property -dict {PACKAGE_PIN T30 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports tx_sync_1_p]
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports tx_sync_1_n]
set_property -dict {PACKAGE_PIN AG21 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports sysref_out_p]
set_property -dict {PACKAGE_PIN AH21 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports sysref_out_n]

set_property -dict {PACKAGE_PIN AE21 IOSTANDARD LVCMOS25} [get_ports spi_csn_ad9528]
set_property -dict {PACKAGE_PIN AH23 IOSTANDARD LVCMOS25} [get_ports spi_clk_ad9528]
set_property -dict {PACKAGE_PIN AH24 IOSTANDARD LVCMOS25} [get_ports spi_mosi_ad9528]
set_property PACKAGE_PIN AG19 [get_ports spi_miso_ad9528]
set_property IOSTANDARD LVCMOS25 [get_ports spi_miso_ad9528]
set_property PULLUP true [get_ports spi_miso_ad9528]

set_property -dict {PACKAGE_PIN AD21 IOSTANDARD LVCMOS25} [get_ports spi_csn_adrv9009]
set_property -dict {PACKAGE_PIN AJ23 IOSTANDARD LVCMOS25} [get_ports spi_clk_adrv9009]
set_property -dict {PACKAGE_PIN AJ24 IOSTANDARD LVCMOS25} [get_ports spi_mosi_adrv9009]
set_property PACKAGE_PIN AF19 [get_ports spi_miso_adrv9009]
set_property IOSTANDARD LVCMOS25 [get_ports spi_miso_adrv9009]
set_property PULLUP true [get_ports spi_miso_adrv9009]

set_property -dict {PACKAGE_PIN R28 IOSTANDARD LVCMOS25} [get_ports ad9528_reset_b]
set_property -dict {PACKAGE_PIN T28 IOSTANDARD LVCMOS25} [get_ports ad9528_sysref_req]
set_property -dict {PACKAGE_PIN AA22 IOSTANDARD LVCMOS25} [get_ports adrv9009_tx1_enable]
set_property -dict {PACKAGE_PIN AC24 IOSTANDARD LVCMOS25} [get_ports adrv9009_tx2_enable]
set_property -dict {PACKAGE_PIN AA23 IOSTANDARD LVCMOS25} [get_ports adrv9009_rx1_enable]
set_property -dict {PACKAGE_PIN AD24 IOSTANDARD LVCMOS25} [get_ports adrv9009_rx2_enable]
set_property -dict {PACKAGE_PIN AD23 IOSTANDARD LVCMOS25} [get_ports adrv9009_test]
set_property -dict {PACKAGE_PIN AJ20 IOSTANDARD LVCMOS25} [get_ports adrv9009_reset_b]
set_property -dict {PACKAGE_PIN AK20 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpint]

set_property -dict {PACKAGE_PIN Y22 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_00]
set_property -dict {PACKAGE_PIN Y23 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_01]
set_property -dict {PACKAGE_PIN AA24 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_02]
set_property -dict {PACKAGE_PIN AB24 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_03]
set_property -dict {PACKAGE_PIN W29 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_04]
set_property -dict {PACKAGE_PIN W30 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_05]
set_property -dict {PACKAGE_PIN W25 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_06]
set_property -dict {PACKAGE_PIN W26 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_07]
set_property -dict {PACKAGE_PIN W28 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_08]
set_property -dict {PACKAGE_PIN T24 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_09]
set_property -dict {PACKAGE_PIN T25 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_10]
set_property -dict {PACKAGE_PIN U25 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_11]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_12]
set_property -dict {PACKAGE_PIN AF24 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_13]
set_property -dict {PACKAGE_PIN AF23 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_14]
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_15]
set_property -dict {PACKAGE_PIN AH22 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_16]
set_property -dict {PACKAGE_PIN AG22 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_17]
set_property -dict {PACKAGE_PIN AE23 IOSTANDARD LVCMOS25} [get_ports adrv9009_gpio_18]

#set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS15} [get_ports tx_link_clk]
#set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS15} [get_ports rx_link_clk]
#set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS15} [get_ports os_link_clk]

set_property IOSTANDARD LVCMOS15 [get_ports {gpio_bd[13]}]
set_property IOSTANDARD LVCMOS15 [get_ports {gpio_bd[12]}]
set_property IOSTANDARD LVCMOS15 [get_ports {gpio_bd[11]}]
set_property PACKAGE_PIN AB20 [get_ports {gpio_bd[13]}]
set_property PACKAGE_PIN AD20 [get_ports {gpio_bd[12]}]
set_property PACKAGE_PIN AE20 [get_ports {gpio_bd[11]}]


#10g

set_property PACKAGE_PIN A8 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]


set_property PACKAGE_PIN AC8 [get_ports xg_refclk_p]
set_property PACKAGE_PIN AC7 [get_ports xg_refclk_n]


set_property PACKAGE_PIN Y5 [get_ports xg_rxn]
set_property PACKAGE_PIN Y6 [get_ports xg_rxp]
set_property PACKAGE_PIN W3 [get_ports xg_txn]
set_property PACKAGE_PIN W4 [get_ports xg_txp]



set_property PACKAGE_PIN AA18 [get_ports xg_tx_disable]
set_property IOSTANDARD LVCMOS15 [get_ports xg_tx_disable]




# clocks

create_clock -period 4.000 -name tx_ref_clk [get_ports ref_clk0_p]
create_clock -period 4.000 -name rx_ref_clk [get_ports ref_clk1_p]
create_clock -period 4.000 -name tx_div_clk [get_pins i_system_wrapper/system_i/util_adrv9009_xcvr/inst/i_xch_0/i_gtxe2_channel/TXOUTCLK]
create_clock -period 4.000 -name rx_div_clk [get_pins i_system_wrapper/system_i/util_adrv9009_xcvr/inst/i_xch_0/i_gtxe2_channel/RXOUTCLK]
create_clock -period 4.000 -name rx_os_div_clk [get_pins i_system_wrapper/system_i/util_adrv9009_xcvr/inst/i_xch_2/i_gtxe2_channel/RXOUTCLK]


#timing ctrl

create_clock -period 10.000 -name clk_fpga [get_pins i_system_wrapper/system_i/sys_ps7/inst/FCLK_CLK0]


create_clock -period 16.276 -name tx_link_clk [get_nets i_system_wrapper/system_i/axi_adrv9009_tx_clkgen/clk_0]
create_clock -period 8.138 -name rx_link_clk [get_nets i_system_wrapper/system_i/axi_adrv9009_rx_clkgen/clk_0]
create_clock -period 8.138 -name os_link_clk [get_nets i_system_wrapper/system_i/axi_adrv9009_rx_os_clkgen/clk_0]


create_clock -period 4.069 -name fast_clk [get_nets i_system_wrapper/system_i/fast_pll/inst/clk_out1]

create_clock -period 6.400 -name eth_clk [get_nets i_system_wrapper/system_i/xg_ethernet/inst/coreclk_out]


set_clock_groups -asynchronous -group [get_clocks eth_clk] -group [get_clocks tx_link_clk] -group [get_clocks fast_clk] -group [get_clocks rx_link_clk] -group [get_clocks clk_fpga]




































