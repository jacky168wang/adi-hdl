
source $ad_hdl_dir/projects/common/zc706/zc706_system_bd.tcl

ad_ip_parameter sys_ps7 CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ 250

source ../common/minimum_bd.tcl

create_bd_port -dir O fclk_clk0
create_bd_port -dir O fclk_clk1
create_bd_port -dir O fclk_clk2
create_bd_port -dir O fclk_rst0_n
create_bd_port -dir O fclk_rst1_n
create_bd_port -dir O fclk_rst2_n

ad_connect fclk_clk0 sys_ps7/FCLK_CLK0
ad_connect fclk_clk1 sys_ps7/FCLK_CLK1
ad_connect fclk_clk2 sys_ps7/FCLK_CLK2
ad_connect fclk_rst0_n sys_ps7/FCLK_RESET0_N
ad_connect fclk_rst1_n sys_ps7/FCLK_RESET1_N
ad_connect fclk_rst2_n sys_ps7/FCLK_RESET2_N

