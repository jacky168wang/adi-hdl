# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create harden_sync
adi_ip_files harden_sync [list \
  "sync.v" \
  "tdd_trig.v" \
  "harden_sync.v" \
  ]

adi_ip_properties_lite harden_sync

adi_add_bus "sync_rx_ctrl" "master" \
"analog.com:interface:sync_ctrl_rtl:1.0" \
"analog.com:interface:sync_ctrl:1.0" \
{\
  { "mode" "mode" } \
  { "rx_trigger" "trigger" } \
  { "rx_lcp" "long_cp" } \
  { "rx_symbol_cnt" "symbol" } \
  { "rx_slot_cnt" "slot" } \
  { "rx_frame_cnt" "frame" } \
}

adi_add_bus "sync_tx_ctrl" "master" \
"analog.com:interface:sync_ctrl_rtl:1.0" \
"analog.com:interface:sync_ctrl:1.0" \
{\
  { "tx_trigger" "trigger" } \
  { "tx_lcp" "long_cp" } \
  { "tx_symbol_cnt" "symbol" } \
  { "tx_slot_cnt" "slot" } \
  { "tx_frame_cnt" "frame" } \
}

ipx::infer_bus_interface clk_tx xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface clk_rx xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface rst_n  xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::save_core [ipx::current_core]