## This is an example Fusion Compiler script for use in DSO.ai labs

# This loads the block from the previous launcher
open_block data/nlib/RGRJ.nlib:clock_opt_build_clock

set_app_options -name route.global.deterministic -value on
clock_opt -from final_opto

# The end of this script is the last launcher of the slice and required to save the block
save_block -as clock_opt
