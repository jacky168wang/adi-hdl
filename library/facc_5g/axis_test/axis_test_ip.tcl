
# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl


adi_ip_files axis_test [list \
  "axis_test.v" \
  ]

adi_ip_properties_lite axis_test

adi_add_bus "s_axis_link" "slave" \
	"xilinx.com:interface:axis_rtl:1.0" \
	"xilinx.com:interface:axis:1.0" \
	[list {"s_axis_link_tready" "TREADY"} \
	  {"s_axis_link_tvalid" "TVALID"} \
	  {"s_axis_link_tdata" "TDATA"} \
	  {"s_axis_link_tlast" "TLAST"} ]
adi_add_bus_clock "link_clk" "s_axis_link"


ipx::save_core [ipx::current_core]