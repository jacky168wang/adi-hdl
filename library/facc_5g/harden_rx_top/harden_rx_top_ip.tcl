
# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create harden_rx_top

set ip_fft_rx [create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name ip_fft_rx]
  set_property -dict [ list \
   CONFIG.implementation_options {pipelined_streaming_io} \
   CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5} \
   CONFIG.scaling_options {block_floating_point} \
   CONFIG.transform_length {4096} \
   CONFIG.output_ordering {natural_order}\
 ]  [get_ips ip_fft_rx]

generate_target {all} [get_files harden_rx_top.srcs/sources_1/ip/ip_fft_rx/ip_fft_rx.xci]

set de_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name de_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {8} \
    CONFIG.Write_Depth_A {19656} \
    CONFIG.Read_Width_A {8} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {32} \
    CONFIG.Read_Width_B {32} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
     ] [get_ips de_ram]

generate_target {all} [get_files harden_rx_top.srcs/sources_1/ip/de_ram/de_ram.xci]

set cpr_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name cpr_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {8192} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {16} \
    CONFIG.Read_Width_B {16} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
     ] [get_ips cpr_ram]

generate_target {all} [get_files harden_rx_top.srcs/sources_1/ip/cpr_ram/cpr_ram.xci]

 set mult_complex [ create_ip -name cmpy -vendor xilinx.com -library ip -version 6.0 -module_name mult_complex ]
  set_property -dict [ list \
   CONFIG.MinimumLatency {4} \
   CONFIG.OptimizeGoal {Performance} \
 ] [get_ips mult_complex]
generate_target {all} [get_files harden_rx_top.srcs/sources_1/ip/mult_complex/mult_complex.xci]


adi_ip_files harden_rx_top [list \
  "harden_rx_top_constr.xdc" \
  "util_arbitmux.sv" \
  "util_blocfifo.sv" \
  "sc_demap.sv" \
  "compression.v" \
  "util_fft.v" \
  "util_scaler.v" \
  "sd_forward.sv" \
  "cp_removal.sv" \
  "phase_comps.sv" \
  "harden_rx.sv" \
  "harden_rx_top.sv" \
  ]
set_property source_mgmt_mode DisplayOnly [current_project]
reorder_files -front harden_rx.sv

adi_ip_properties_lite harden_rx_top

adi_add_bus "pusch_ante" "master" \
"analog.com:interface:pusch_ante_rtl:1.0" \
"analog.com:interface:pusch_ante:1.0" \
{\
  { "dout_used" "block_used" } \
  { "data_rd_req" "rx_rd_en" } \
  { "dout_data" "rx_data" } \
  { "dout_valid" "rx_valid" } \
  { "dout_ante" "ante_index" } \
  { "dout_exp" "gain_factor" } \
  { "dout_symbol" "symbol_index" } \
  { "dout_slot" "slot_index" } \
  { "dout_frame" "frame_index" } \
}

adi_add_bus "sync_rx_ctrl" "slave" \
"analog.com:interface:sync_ctrl_rtl:1.0" \
"analog.com:interface:sync_ctrl:1.0" \
{\
  { "mode" "mode" } \
  { "trigger" "trigger" } \
  { "long_cp" "long_cp" } \
  { "sync_symbol" "symbol" } \
  { "sync_slot" "slot" } \
  { "sync_frame" "frame" } \
}

adi_add_bus "m_axis_fast" "master" \
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list {"m_axis_fast_tready" "TREADY"} \
	  {"m_axis_fast_tvalid" "TVALID"} \
	  {"m_axis_fast_tdata" "TDATA"} \
	  {"m_axis_fast_tlast" "TLAST"} ]
adi_add_bus_clock "fast_clk" "m_axis_fast"

adi_add_bus "m_axis_eth" "master" \
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list {"m_axis_eth_tready" "TREADY"} \
	  {"m_axis_eth_tvalid" "TVALID"} \
	  {"m_axis_eth_tdata" "TDATA"} \
	  {"m_axis_eth_tlast" "TLAST"} ]
adi_add_bus_clock "eth_clk" "m_axis_eth"


adi_add_bus "m_axis_link" "master" \
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list {"m_axis_link_tvalid" "TVALID"} \
	  {"m_axis_link_tdata" "TDATA"} ]
adi_add_bus_clock "link_clk" "m_axis_link"

##adi_add_bus "phs_coef" "slave" \
##"analog.com:interface:phs_coef_rtl:1.0" \
##"analog.com:interface:phs_coef:1.0" \
##{\
##  {"phs_coef_0" "coef_0"} \
##  {"phs_coef_1" "coef_1"} \
##  {"phs_coef_2" "coef_2"} \
##  {"phs_coef_3" "coef_3"} \
##  {"phs_coef_4" "coef_4"} \
##  {"phs_coef_5" "coef_5"} \
##  {"phs_coef_6" "coef_6"} \
##  {"phs_coef_7" "coef_7"} \
##  {"phs_coef_8" "coef_8"} \
##  {"phs_coef_9" "coef_9"} \
##  {"phs_coef_10" "coef_10"} \
##  {"phs_coef_11" "coef_11"} \
##  {"phs_coef_12" "coef_12"} \
##  {"phs_coef_13" "coef_13"} \
##  {"phs_coef_14" "coef_14"} \
##  {"phs_coef_15" "coef_15"} \
##  {"phs_coef_16" "coef_16"} \
##  {"phs_coef_17" "coef_17"} \
##  {"phs_coef_18" "coef_18"} \
##  {"phs_coef_19" "coef_19"} \
##  {"phs_coef_20" "coef_20"} \
##  {"phs_coef_21" "coef_21"} \
##  {"phs_coef_22" "coef_22"} \
##  {"phs_coef_23" "coef_23"} \
##  {"phs_coef_24" "coef_24"} \
##  {"phs_coef_25" "coef_25"} \
##  {"phs_coef_26" "coef_26"} \
##  {"phs_coef_27" "coef_27"} \
##}

ipx::save_core [ipx::current_core]