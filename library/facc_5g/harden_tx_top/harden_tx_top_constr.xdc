
set_property ASYNC_REG TRUE [get_cells -hier -filter {name =~ *cc*}]

set_false_path -to [get_cells -hier -filter {name =~ *cc_reg[1] && IS_SEQUENTIAL}]

# clocks

