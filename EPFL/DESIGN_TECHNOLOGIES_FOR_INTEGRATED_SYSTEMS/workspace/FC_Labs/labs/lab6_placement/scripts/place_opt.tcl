#####################################################################
#####	 	Lab 6 Placement and Optimization		#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/final_floorplan -to ${DESIGN_NAME}/place_opt
open_block ${DESIGN_NAME}/place_opt

# Setup application options
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name place_opt.final_place.effort -value high
set_app_options -name place_opt.place.congestion_effort -value high
set_app_options -name opt.common.user_instance_name_prefix -value place_opt

#### compile_fusion to initial_opto stage to get the design ready for placement and optimization
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
compile_fusion -to initial_opto

#### Classic place_opt flow

# create coarse placement
reset_placement

create_placement \
	-timing_driven \
	-congestion \
	-congestion_effort medium \
	-buffering_aware_timing_driven

legalize_placement 

# place_opt
place_opt

# Analyze the design
check_legality 
report_congestion 
report_utilization
collect_reports classic_place_opt_flow 

#### Unified place_opt flow
reset_placement

compile_fusion -to final_opto

# Analyze the design
check_legality 
report_congestion 
report_utilization
collect_reports unified_flow

#### Placement blockages 
create_placement_blockage \
	-boundary {{7.9600 8.0000} {7.9600 14.0000} {15.9520 14.0000} {15.9520 8.0000}} \
	-type hard 

check_legality 
legalize_placement -incremental

#### Connect PG nets
connect_pg_net -net VDD [get_pins -hierarchical  */VDD]
connect_pg_net -net VSS [get_pins -hierarchical  */VSS]

# Analyze the design
check_legality 
report_congestion 
report_utilization
collect_reports placement_blockage 

get_blocks -all
list_blocks

save_block
save_lib

exit

