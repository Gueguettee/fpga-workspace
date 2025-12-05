## This is an example Fusion Compiler script for use in DSO.ai labs

# This loads the block from the previous slice
open_block data/nlib/RGRJ.nlib:clock_opt

set_app_options -name route.global.deterministic -value on
route_auto

# The end of this script saves a unique block for ease of recovery from this launcher
save_block -as route_auto
