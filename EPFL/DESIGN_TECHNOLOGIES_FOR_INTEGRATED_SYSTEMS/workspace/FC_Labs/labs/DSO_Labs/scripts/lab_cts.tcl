## This is an example Fusion Compiler script for use in DSO.ai labs

# This loads the block from the previous slice
open_block data/nlib/RGRJ.nlib:compile

set_app_options -name route.global.deterministic -value on
clock_opt -from build_clock -to route_clock

# The end of this script saves a unique block for ease of recovery from this launcher
save_block -as clock_opt_build_clock
