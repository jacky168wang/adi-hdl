# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl


adi_ip_create jesd_looback

adi_ip_files jesd_looback [list \
  "data_32to16.v" \
  "jesd_looback.v"\
  ]

adi_ip_properties_lite jesd_looback
#adi_ip_infer_streaming_interfaces jesd_mux


ipx::save_core [ipx::current_core]

