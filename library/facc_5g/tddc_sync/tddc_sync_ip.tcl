# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create tddc_sync
adi_ip_files tddc_sync [list \
  "tdd_aximm_inout.sv" \
  "up_axi.v" \
  "tdd_regist_ctrl.v" \
  "tdd_state_machine.v" \
  "tddc_sync.v" \
  ]

adi_ip_properties tddc_sync

ipx::save_core [ipx::current_core]