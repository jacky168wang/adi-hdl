
# RF   GPIO


set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVCMOS25} [get_ports GPIO_SP4T_V1]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVCMOS25} [get_ports GPIO_SP4T_V2]
set_property -dict {PACKAGE_PIN U26 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR1_A]
set_property -dict {PACKAGE_PIN V23 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR1_SW]
set_property -dict {PACKAGE_PIN U27 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR2_A]
set_property -dict {PACKAGE_PIN W24 IOSTANDARD LVCMOS25} [get_ports GPIO_UA_TR2_SW]
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR1_A]                    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR1_SW]                    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR2_A]                       ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_UB_TR2_SW]                       ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_RF_SW_ORX]                    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_RF_SW_PHACAL]                    ; ##
#set_property  -dict {PACKAGE_PIN    IOSTANDARD LVCMOS25} [get_ports GPIO_SNF_RX_SEL]                    ; ##  THIS IS PIN NO USE
set_property -dict {PACKAGE_PIN N27 IOSTANDARD LVCMOS25} [get_ports GPIO_TX_CAL]



# J67,J68
set_property -dict {PACKAGE_PIN AD18 IOSTANDARD LVCMOS15} [get_ports pps_in_outside]
#set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVDS_25} [get_ports user_sma_clock_n]

# rf_gpio
set_property PACKAGE_PIN N26 [get_ports pa_power_enable]
set_property IOSTANDARD LVCMOS25 [get_ports pa_power_enable]


#sys  rst
#set_property PACKAGE_PIN A8 [get_ports sys_rst]
#set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]

set_property -dict {PACKAGE_PIN AJ21 IOSTANDARD LVCMOS25} [get_ports tx_trigger]
set_property -dict {PACKAGE_PIN Y20 IOSTANDARD LVCMOS15} [get_ports tx_lcp]
set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS25} [get_ports rx_trigger]
#set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS25} [get_ports pps_in_inside]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS15} [get_ports rx_lcp]
#J58  1 port
#J58  2 port
#J58  3 port
#J58  4 port






