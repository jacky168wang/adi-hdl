# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create harden_tx_top

set ip_fft_tx [create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name ip_fft_tx]
  set_property -dict [ list \
   CONFIG.implementation_options {pipelined_streaming_io} \
   CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5} \
   CONFIG.scaling_options {block_floating_point} \
   CONFIG.output_ordering {natural_order} \
   CONFIG.transform_length {4096} \
 ]  [get_ips ip_fft_tx]

generate_target {all} [get_files harden_tx_top.srcs/sources_1/ip/ip_fft_tx/ip_fft_tx.xci]

set dma_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name dma_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {4096} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {32} \
    CONFIG.Read_Width_B {32} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
     ] [get_ips dma_ram]

generate_target {all} [get_files harden_tx_top.srcs/sources_1/ip/dma_ram/dma_ram.xci]

set sc_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name sc_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Write_Depth_A {8192} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {8} \
    CONFIG.Read_Width_B {8} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
     ] [get_ips sc_ram]

generate_target {all} [get_files harden_tx_top.srcs/sources_1/ip/sc_ram/sc_ram.xci]
##
set cp_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name cp_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {40960} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {32} \
    CONFIG.Read_Width_B {32} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
  ] [get_ips cp_ram]

generate_target {all} [get_files harden_tx_top.srcs/sources_1/ip/cp_ram/cp_ram.xci]


 set mult_complex [ create_ip -name cmpy -vendor xilinx.com -library ip -version 6.0 -module_name mult_complex ]
  set_property -dict [ list \
   CONFIG.MinimumLatency {4} \
   CONFIG.OptimizeGoal {Performance} \
 ] [get_ips mult_complex]
generate_target {all} [get_files harden_tx_top.srcs/sources_1/ip/mult_complex/mult_complex.xci]        











adi_ip_files harden_tx_top [list \
  "harden_tx_top_constr.xdc" \
  "util_arbitmux.sv" \
  "dmafifo_tx.sv" \
  "util_fifo2avl.v"\
  "harden_tx.sv"\
  "util_blocfifo.sv" \
  "sc_map.sv" \
  "decompression.v" \
  "util_fft.v" \
  "util_scaler.v" \
  "sd_forward.sv" \
  "cp_insertion.sv" \
  "phase_comps.sv" \
  "harden_tx_top.sv" \
  ]

set_property source_mgmt_mode DisplayOnly [current_project]
reorder_files -front harden_tx.sv

adi_ip_properties_lite harden_tx_top

adi_add_bus "pdsch_ante" "slave" \
"analog.com:interface:pdsch_ante_rtl:1.0" \
"analog.com:interface:pdsch_ante:1.0" \
{\
  { "din_data" "data" } \
  { "din_sop" "sop" } \
  { "din_eop" "eop" } \
  { "din_valid" "valid" } \
  { "din_ante" "ante" } \
  { "din_symbol" "symbol" } \
  { "din_slot" "slot" } \
  { "din_frame" "frame" } \
}

adi_add_bus "sync_tx_ctrl" "slave" \
"analog.com:interface:sync_ctrl_rtl:1.0" \
"analog.com:interface:sync_ctrl:1.0" \
{\
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

adi_add_bus "m_axis_link" "master" \
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list {"m_axis_link_tready" "TREADY"} \
	  {"m_axis_link_tvalid" "TVALID"} \
	  {"m_axis_link_tdata" "TDATA"} \
	  {"m_axis_link_tlast" "TLAST"} ]
adi_add_bus_clock "link_clk" "m_axis_link"

##adi_add_bus "phs_coef" "slave" \
##"analog.com:interface:phs_coef_rtl:1.0" \
##"analog.com:interface:phs_coef:1.0" \
##{\
##  {"phs_coef[ 0]" "coef_0"} \
##  {"phs_coef[ 1]" "coef_1"} \
##  {"phs_coef[ 2]" "coef_2"} \
##  {"phs_coef[ 3]" "coef_3"} \
##  {"phs_coef[ 4]" "coef_4"} \
##  {"phs_coef[ 5]" "coef_5"} \
##  {"phs_coef[ 6]" "coef_6"} \
##  {"phs_coef[ 7]" "coef_7"} \
##  {"phs_coef[ 8]" "coef_8"} \
##  {"phs_coef[ 9]" "coef_9"} \
##  {"phs_coef[10]" "coef_10"} \
##  {"phs_coef[11]" "coef_11"} \
##  {"phs_coef[12]" "coef_12"} \
##  {"phs_coef[13]" "coef_13"} \
##  {"phs_coef[14]" "coef_14"} \
##  {"phs_coef[15]" "coef_15"} \
##  {"phs_coef[16]" "coef_16"} \
##  {"phs_coef[17]" "coef_17"} \
##  {"phs_coef[18]" "coef_18"} \
##  {"phs_coef[19]" "coef_19"} \
##  {"phs_coef[20]" "coef_20"} \
##  {"phs_coef[21]" "coef_21"} \
##  {"phs_coef[22]" "coef_22"} \
##  {"phs_coef[23]" "coef_23"} \
##  {"phs_coef[24]" "coef_24"} \
##  {"phs_coef[25]" "coef_25"} \
##  {"phs_coef[26]" "coef_26"} \
##  {"phs_coef[27]" "coef_27"} \
##}

ipx::save_core [ipx::current_core]

