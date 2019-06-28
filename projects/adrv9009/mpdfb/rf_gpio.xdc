
# RF   GPIO

set_property -dict {PACKAGE_PIN U26 IOSTANDARD LVCMOS25} [get_ports GPIO_SP4T_V1]
set_property -dict {PACKAGE_PIN U27 IOSTANDARD LVCMOS25} [get_ports GPIO_SP4T_V2]
set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR1_A]
set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR1_SW]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR2_A]
set_property -dict {PACKAGE_PIN AD13 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR2_SW]
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR1_A]    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR1_SW]   ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR2_A]    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR2_SW]   ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_RF_SW_ORX]   ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_RF_SW_PHACAL ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_SNF_RX_SEL]  ; ##  THIS IS PIN NO USE
set_property -dict {PACKAGE_PIN R21 IOSTANDARD LVCMOS25} [get_ports GPIO_TX_CAL]

###10g

set_property PACKAGE_PIN A8 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]
set_property PACKAGE_PIN AF10 [get_ports xg_refclk_p]
set_property PACKAGE_PIN AF9 [get_ports xg_refclk_n]
set_property PACKAGE_PIN AJ7 [get_ports xg_rxn]
set_property PACKAGE_PIN AJ8 [get_ports xg_rxp]
set_property PACKAGE_PIN AK5 [get_ports xg_txn]
set_property PACKAGE_PIN AK6 [get_ports xg_txp]

#BANK 13
set_property PACKAGE_PIN U21 [get_ports xg_tx_disable]
set_property IOSTANDARD LVCMOS25 [get_ports xg_tx_disable]

###PPS
# J67  BANK 9
set_property -dict {PACKAGE_PIN AD18 IOSTANDARD LVCMOS25} [get_ports pps_in_dfb]
# BANK 13
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS25} [get_ports pps_in_rfb]

set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS25} [get_ports pm_power_enable]

### pa_power_enable  bank13
set_property PACKAGE_PIN P21 [get_ports pa_power_enable]
set_property IOSTANDARD LVCMOS25 [get_ports pa_power_enable]



set_property -dict {PACKAGE_PIN AJ21 IOSTANDARD LVCMOS25} [get_ports tx_trigger]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS25} [get_ports tx_lcp]
set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS25} [get_ports rx_trigger]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS25} [get_ports rx_lcp]
#J58  1 port  bank 11
#J58  2 port  bank 9
#J58  3 port  bank 11
#J58  4 port  bank 9






