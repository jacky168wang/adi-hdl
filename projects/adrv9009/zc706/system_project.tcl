
source ../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

adi_project_xilinx adrv9009_mpdfb
adi_project_files adrv9009_mpdfb [list \
  "system_top.v" \
  "system_constr.xdc"\
  "system_constr_n2.xdc"\
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/mpdfb/mpdfb_system_constr.xdc" ]

## To improve timing of the BRAM buffers
set_property strategy Performance_RefinePlacement [get_runs impl_1]

adi_project_run adrv9009_mpdfb