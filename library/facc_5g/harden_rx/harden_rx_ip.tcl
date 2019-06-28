
# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create harden_rx

set ip_fft_tx [create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name ip_fft_rx]
  set_property -dict [ list \
   CONFIG.implementation_options {pipelined_streaming_io} \
   CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5} \
   CONFIG.scaling_options {block_floating_point} \
   CONFIG.transform_length {4096} \
 ]  [get_ips ip_fft_rx]

generate_target {all} [get_files harden_rx.srcs/sources_1/ip/ip_fft_rx/ip_fft_rx.xci]

set de_ram [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name de_ram]
  set_property -dict [ list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {8} \
    CONFIG.Write_Depth_A {16384} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Operating_Mode_A {NO_CHANGE} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Write_Width_B {32} \
    CONFIG.Read_Width_B {32} \
    CONFIG.Operating_Mode_B {WRITE_FIRST} \
    CONFIG.Enable_B {Always_Enabled} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
     ] [get_ips de_ram]

generate_target {all} [get_files harden_rx.srcs/sources_1/ip/de_ram/de_ram.xci]

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
    CONFIG.Register_PortB_Output_of_Memory_Primitives {true} \
     ] [get_ips cpr_ram]

generate_target {all} [get_files harden_rx.srcs/sources_1/ip/cpr_ram/cpr_ram.xci]

adi_ip_files harden_rx [list \
  "util_blocfifo.sv" \
  "sc_demap.sv" \
  "compression.v" \
  "util_fft.v" \
  "util_scaler.v" \
  "sd_forward.sv" \
  "cp_removal.sv" \
  "harden_rx.v" \
  ]
set_property source_mgmt_mode DisplayOnly [current_project]     
reorder_files -front harden_rx.v    
     
adi_ip_properties_lite harden_rx

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
ipx::save_core [ipx::current_core]

