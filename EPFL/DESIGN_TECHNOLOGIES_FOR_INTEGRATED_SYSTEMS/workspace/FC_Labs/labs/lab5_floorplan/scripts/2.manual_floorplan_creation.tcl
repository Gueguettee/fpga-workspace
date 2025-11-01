#####################################################################
#####		Lab 5.2 Manual Floorplan Creation		#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/auto_floorplan -to ${DESIGN_NAME}/manual_floorplan
open_block ${DESIGN_NAME}/manual_floorplan

#### Initialize the floorplan
initialize_floorplan  \
	-control_type core \
	-core_utilization 0.6 \
	-core_offset 5 \
	-shape R \
	-side_ratio {2 1} \
	-flip_first_row true

#### Set pin placement constraints
set ports [remove_from_collection [get_ports] {VDD VSS}]

set_block_pin_constraints -self \
	-allowed_layers {M4 M3} \
	-sides {1 4} \
	-pin_spacing_distance 1 \
	-width 0.11 \
	-length 0.11 
	
set_individual_pin_constraints \
	-ports [get_ports wb_clk_i] \
	-sides 2 \
	-allowed_layers M5
	
place_pins -self -ports ${ports}

#### Insert Boundary/TAP cells in the design
source -echo ../scripts/insert_boundary_and_tap_cells.tcl

#### Write out the created floorplan 
write_floorplan -output ${RESULTS_PATH}/write_floorplan_files -exclude {cells nets} 

#### Write DEF for created floorplan
write_def -exclude {cells nets} ${RESULTS_PATH}/floorplan.def

get_blocks -all
save_block
save_lib
exit
