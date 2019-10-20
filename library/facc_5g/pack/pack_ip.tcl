# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create pack

set st_ram_32to64 [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name st_ram_32to64]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {4096} \
    CONFIG.Read_Width_A {64} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {64} \
    CONFIG.Read_Width_B {64} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
     ] [get_ips st_ram_32to64]

generate_target {all} [get_files pack.srcs/sources_1/ip/st_ram_32to64/st_ram_32to64.xci]


adi_ip_files pack [list \
  "util_arbitmux.sv" \
  "pss_pckt_gen.sv" \
  "pusch_packet.sv" \
  "avlst_32to64.sv" \
  "timing_packet.v" \
  "util_packfifo.sv" \
  "pack.sv"\
  ]

adi_ip_properties_lite pack

adi_add_bus "pusch_ante" "slave" \
"analog.com:interface:pusch_ante_rtl:1.0" \
"analog.com:interface:pusch_ante:1.0" \
{\
  { "block_used" "block_used" } \
  { "rx_rd_en" "rx_rd_en" } \
  { "rx_data" "rx_data" } \
  { "rx_valid" "rx_valid" } \
  { "gain_factor" "gain_factor" } \
  { "ante_index" "ante_index" } \
  { "symbol_index" "symbol_index" } \
  { "slot_index" "slot_index" } \
  { "frame_index" "frame_index" } \
}


adi_add_bus "mac_addr" "slave" \
  "analog.com:interface:mac_addr_rtl:1.0" \
  "analog.com:interface:mac_addr:1.0" \
  { \
    { "dest_addr_l" "dest_addr_l" } \
    { "dest_addr_h" "dest_addr_h" } \
    { "sour_addr_l" "sour_addr_l" } \
    { "sour_addr_h" "sour_addr_h" } \
 }

## for denug
##adi_add_bus "avalon_dout" "master" \
##"analog.com:interface:avalon_st_rtl:1.0" \
##"analog.com:interface:avalon_st:1.0" \
##{\
##  { "dout_ready" "ready" } \
##  { "dout_sop" "sop" } \
##  { "dout_eop" "eop" } \
##  { "dout_valid" "valid" } \
##  { "dout_empty" "empty" } \
##  { "dout_data" "data" } \
##}

adi_add_bus	"xg_m_axis" "master"\
"xilinx.com:interface:axis_rtl:1.0" \
"xilinx.com:interface:axis:1.0" \
[list \
	{"dout_data" "TDATA"}\
	{"dout_eop" "TLAST"}\
	{"dout_valid" "TVALID"}\
	{"dout_keep" "TKEEP"}\
	{"dout_ready" "TREADY"} ]


ipx::save_core [ipx::current_core]
