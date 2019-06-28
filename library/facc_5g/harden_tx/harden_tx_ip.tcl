# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create harden_tx

set ip_fft_tx [create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name ip_fft_tx]
  set_property -dict [ list \
   CONFIG.implementation_options {pipelined_streaming_io} \
   CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5} \
   CONFIG.scaling_options {block_floating_point} \
   CONFIG.transform_length {4096} \
 ]  [get_ips ip_fft_tx]

generate_target {all} [get_files harden_tx.srcs/sources_1/ip/ip_fft_tx/ip_fft_tx.xci]

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
    CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
     ] [get_ips sc_ram]

generate_target {all} [get_files harden_tx.srcs/sources_1/ip/sc_ram/sc_ram.xci]
##
set cp_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name cp_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {40960} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {32} \
    CONFIG.Read_Width_B {32} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
  ] [get_ips cp_ram]

generate_target {all} [get_files harden_tx.srcs/sources_1/ip/cp_ram/cp_ram.xci]

adi_ip_files harden_tx [list \
  "harden_tx.v"\ 
  "util_blocfifo.sv" \
  "sc_map.sv" \
  "decompression.v" \
  "util_fft.v" \
  "util_scaler.v" \
  "sd_forward.sv" \
  "cp_insertion.sv" \
  ]

set_property source_mgmt_mode DisplayOnly [current_project]     
reorder_files -front harden_tx.v    

adi_ip_properties_lite harden_tx

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


ipx::save_core [ipx::current_core]

