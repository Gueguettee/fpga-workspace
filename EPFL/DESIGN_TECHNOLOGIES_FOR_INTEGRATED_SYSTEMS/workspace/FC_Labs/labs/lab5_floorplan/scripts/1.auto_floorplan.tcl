#####################################################################
#####			Lab 5.1 Auto Floorplan			#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/rtl_read -to ${DESIGN_NAME}/auto_floorplan
open_block ${DESIGN_NAME}/auto_floorplan

# Source tech setup script
source -echo ../../setup/tech_setup.tcl

# Read the constraints
read_sdc -echo ${SDC_FILE}

# MCMM setup
source -echo ../../setup/mcmm_setup.tcl

# Setup application options
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name compile.auto_floorplan.enable            -value true

# Check the design before compile_fusion
compile_fusion -check_only

#### Initial auto floorplan creation
compile_fusion -to logic_opto 

#### Auto floorplan tuning

# Auto floorplan constraints
set_auto_floorplan_constraints \
	-control_type core \
	-core_utilization 0.5 \
	-core_offset 10 \
	-shape R \
	-side_ratio {1 2} \
	-flip_first_row true
	
report_auto_floorplan_constraints
	
set_app_options -name compile.auto_floorplan.place_pins -value all

# Pin placement constraints
set ports [remove_from_collection [get_ports] {VDD VSS}]

set_block_pin_constraints -self \
	-allowed_layers {M2 M3} \
	-sides {1 4} \
	-pin_spacing_distance 1 \
	-width 0.19 \
	-length 0.19 
	
set_individual_pin_constraints \
	-ports [get_ports wb_clk_i] \
	-sides 3 \
	-allowed_layers M4

report_block_pin_constraints -self

#### Tuned auto floorplan creation
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
compile_fusion -to logic_opto

#### Analyze the design
report_congestion -rerun_global_router
collect_reports tuned_auto_floorplan 

get_blocks -all
save_block
save_lib

exit
