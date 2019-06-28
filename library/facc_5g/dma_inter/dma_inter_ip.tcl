# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create	dma_inter

set lpm_ram_dma_inter0 [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name lpm_ram_dma_inter0]
	set_property -dict [ list\
		CONFIG.Memory_Type {Simple_Dual_Port_RAM}\
		CONFIG.Write_Width_A {32}\
		CONFIG.Write_Depth_A {512}\
		CONFIG.Read_Width_A {32}\
		CONFIG.Operating_Mode_A {NO_CHANGE}\
		CONFIG.Enable_A {Always_Enabled}\
		CONFIG.Write_Width_B {64}\
		CONFIG.Read_Width_B {64}\
		CONFIG.Enable_B {Always_Enabled}\
		CONFIG.Register_PortA_Output_of_Memory_Primitives {false}\
		CONFIG.Register_PortB_Output_of_Memory_Primitives {true}\
		CONFIG.Port_B_Clock {100}\
		CONFIG.Port_B_Enable_Rate {100}\
					]	[get_ips lpm_ram_dma_inter0]


generate_target {all} [get_files	dma_inter.srcs/sources_1/ip/lpm_ram_dma_inter0/lpm_ram_dma_inter0.xci]



adi_ip_files dma_inter [list \
	"dma_inter.v"\
	"fifo_fast.sv"\
	"sym_dc_fifo.sv"\
	]

adi_ip_properties_lite dma_inter

adi_add_bus	"fifo_wr" "master"\
"analog.com:interface:fifo_wr_rtl:1.0" \
"analog.com:interface:fifo_wr:1.0" \
{\
	{"fifo_wr_sync" "SYNC"}\
	{"fifo_wr_en" "EN"}\
	{"fifo_wr_data" "DATA"}\
	{"fifo_wr_xfer_req" "XFER_REQ"}\
	{"fifo_wr_overflow" "OVERFLOW"}\
}

adi_add_bus	"s_tx_axis_fast" "slave" \
"xilinx.com:interface:axis_rtl:1.0" \
"xilinx.com:interface:axis:1.0" \
[list {"tx_axis_fast_tdata" "TDATA"} \
	{"tx_axis_fast_tlast" "TLAST"} \
	{"tx_axis_fast_tvalid" "TVALID"} \
	{"tx_axis_fast_tready" "TREADY"} ]
adi_add_bus_clock "fast_clk" "tx_axis_fast"

adi_add_bus	"s_rx_axis_fast" "slave" \
"xilinx.com:interface:axis_rtl:1.0" \
"xilinx.com:interface:axis:1.0" \
[list \
	{"rx_axis_fast_tdata" "TDATA"} \
	{"rx_axis_fast_tlast" "TLAST"} \
	{"rx_axis_fast_tvalid" "TVALID"} \
	{"rx_axis_fast_tready" "TREADY"} ]
adi_add_bus_clock "fast_clk" "tx_axis_fast"

adi_add_bus	"s_rx_axis_eth" "slave" \
"xilinx.com:interface:axis_rtl:1.0" \
"xilinx.com:interface:axis:1.0" \
[list \
	{"rx_axis_eth_tdata" "TDATA"}\
	{"rx_axis_eth_tlast" "TLAST"}\
	{"rx_axis_eth_tvalid" "TVALID"}\
	{"rx_axis_eth_tready" "TREADY"} ]

adi_add_bus	"s_tx_axis_link" "slave"\
"xilinx.com:interface:axis_rtl:1.0" \
"xilinx.com:interface:axis:1.0" \
[list \
	{"tx_axis_link_tdata" "TDATA"}\
	{"tx_axis_link_tlast" "TLAST"}\
	{"tx_axis_link_tvalid" "TVALID"}\
	{"tx_axis_link_tready" "TREADY"} ]

	adi_add_bus	"s_rx_axis_link" "slave"\
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list \
		{"rx_axis_link_tdata" "TDATA"}\
		{"rx_axis_link_tvalid" "TVALID"} ]

ipx::save_core [ipx::current_core]


