# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create aximm_inout
adi_ip_files aximm_inout [list \
  "up_axi.v" \
  "aximm_inout.sv" \
]

adi_ip_properties aximm_inout

adi_add_bus "mac_addr" "master" \
  "analog.com:interface:mac_addr_rtl:1.0" \
  "analog.com:interface:mac_addr:1.0" \
  { \
    { "dest_addr_l" "dest_addr_l" } \
    { "dest_addr_h" "dest_addr_h" } \
    { "sour_addr_l" "sour_addr_l" } \
    { "sour_addr_h" "sour_addr_h" } \
 }


ipx::infer_bus_interface dpd_rstn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface dfe_sysrst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::save_core [ipx::current_core]