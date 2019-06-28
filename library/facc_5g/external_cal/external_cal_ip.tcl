# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create external_cal
adi_ip_files external_cal [list \
  "external_cal.v" \
]
  
adi_ip_properties_lite external_cal 

ipx::save_core [ipx::current_core]                                                                                                                                                                                                                                                                                                                                                                                                                                                            