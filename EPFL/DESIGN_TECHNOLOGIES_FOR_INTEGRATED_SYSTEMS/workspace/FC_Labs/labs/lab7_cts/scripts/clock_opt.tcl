#####################################################################
#####	 	Lab 7 Clock Tree Synthesis			#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/place_opt -to ${DESIGN_NAME}/clock_opt
open_block ${DESIGN_NAME}/clock_opt

# Setup application options
set_app_options -name cts.common.max_fanout -value 50
set_app_options -name cts.compile.enable_cell_relocation -value timing_aware
set_app_options -name cts.compile.size_pre_existing_cell_to_cts_references -value true
set_app_options -name cts.common.user_instance_name_prefix -value clock_opt

# Improve routability
set_app_options    -name route.common.wire_on_grid_by_layer_name   -value {{M1 true } {M2 true} {M3 true}}
set_app_options    -name route.common.via_on_grid_by_layer_name    -value {{VIA1 false} {VIA2 true}}

#### Specify the driving cell
set_driving_cell -lib_cell ${CELL_PREFIX}_BUF_16 [get_ports wb_clk_i] 

#### Define cell usage during CTS
set_lib_cell_purpose -include cts \
	{*/SAEDRVT14_INV_1 */SAEDRVT14_INV_2 */SAEDRVT14_INV_4 */SAEDRVT14_INV_8 */SAEDRVT14_INV_16 */SAEDRVT14_INV_20 \
	 */SAEDRVT14_BUF_2 */SAEDRVT14_BUF_4 */SAEDRVT14_BUF_6 */SAEDRVT14_BUF_8 */SAEDRVT14_BUF_16 */SAEDRVT14_BUF_20 }

#### Create Shielding options and Non-Default Routing (NDR) rules

# Create NDR rule
create_routing_rule CLK_NDR \
	-default_reference_rule \
	-multiplier_width 2 \
	-multiplier_spacing 2 \
	-shield \
	-shield_widths {M1 0 M2 0 M3 0 M4 0}\
	-snap_to_track 
	
# Define minimum and maximum clock routing layer
set_clock_routing_rules -rules CLK_NDR \
	-min_routing_layer M2 \
	-max_routing_layer M5

#### Set targer skew value
set_clock_tree_options -clocks [all_clocks] \
	-target_skew 0.1
	 
#### clock_opt flow
get_clocks

# List the stages of clock_opt command
clock_opt -list_only

# Synthesize and optimize the clock tree
clock_opt -to build_clock

# Detail routing of clock
clock_opt -from build_clock -to route_clock 

# Optimization and legalization
clock_opt -to final_opto

# Remove global routes to review the clock tree
remove_routes -global_route 

#### Clock shielding with VSS
set clock_nets [get_nets -hierarchical -filter "net_type == clock"]
create_shields -nets ${clock_nets} -with_ground VSS -preferred_direction_only true -align_to_shape_end true

#### Connect PG nets
connect_pg_net -net VDD [get_pins -hierarchical  */VDD]
connect_pg_net -net VSS [get_pins -hierarchical  */VSS]

# Analyze the design
check_legality 
report_congestion 
report_utilization
collect_reports clock_opt 

get_blocks -all
list_blocks

save_block
save_lib

exit
