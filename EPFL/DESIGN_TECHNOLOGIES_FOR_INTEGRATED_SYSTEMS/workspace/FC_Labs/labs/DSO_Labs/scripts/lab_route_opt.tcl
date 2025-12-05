## This is an example Fusion Compiler script for use in DSO.ai labs

# This loads the block from the previous launcher
open_block data/nlib/RGRJ.nlib:route_auto

set_app_options -name route.global.deterministic -value on
route_opt

# The end of this script is the last launcher of the slice and required to save the block
save_block -as route_opt
