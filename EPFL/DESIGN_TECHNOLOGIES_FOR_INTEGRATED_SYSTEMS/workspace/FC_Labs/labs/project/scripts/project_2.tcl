#### Sourcing common setup script
source -echo ../scripts/project_fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

#### Report reference libraries
report_ref_libs

#### Reading RTL

# Suppress known warnings 
suppress_message VER-130

# Unsuppress after analyze stage
unsuppress_message VER-130

set DESIGN_NAME mac_unit_2

analyze -format sverilog mac_unit_2.sv

# Unsuppress after analyze stage
unsuppress_message VER-130

# Elaborate
elaborate ${DESIGN_NAME}

# Set top module in the design
set_top_module ${DESIGN_NAME}

save_block -as ${DESIGN_NAME}/project2_read_rtl

# Source tech setup script
source -echo ../../setup/tech_setup.tcl

# Setup application options
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name compile.flow.enable_ccd -value false

# manual floorplan

### TODO ###
### COPY FROM project_1.tcl the FLOORPLAN and make it the right size AND ADJUST THE SIDE LENGTH ###
### If it doesnt fit, compile_fusion will error out, thus reatry with a bigger value ###
initialize_floorplan -control_type core -core_utilization 0.6 -core_offset 5 -shape R -side_length {36 36} -flip_first_row true

set_block_pin_constraints -self -allowed_layers {M4 M3} -sides {1 4} -pin_spacing_distance 1 -width 0.11 -length 0.11 
	
set_individual_pin_constraints -ports [get_ports clk_i] -sides 2 -allowed_layers M5

create_port -port_type power -direction inout VDD
create_port -port_type ground -direction inout VSS

create_net  -power  VDD
create_net  -ground  VSS

#### Set pin placement constraints
set ports [remove_from_collection [get_ports] {VDD VSS}]

place_pins -self -ports ${ports}

#### Insert Boundary/TAP cells in the design
source -echo ../scripts/insert_boundary_and_tap_cells.tcl

#### Create Power/Ground Network
source -echo ../scripts/create_pg_network.tcl

# MCMM setup
set SDC_FILE_MAC_UNIT "mac_unit.sdc"
source -echo ../scripts/project_mcmm_setup.tcl

compile_fusion -to final_opto

#for the final reports, we want to use zero_interconnect to be consistent with previous runs
set_app_options -name time.delay_calculation_style -value zero_interconnect

report_area > reports/area_final_opto_report_p2.log
report_timing -significant_digits 10 > reports/timing_final_opto_report_p2.log

report_resources > reports/resource_final_opto_report_p2.log
report_utilization > reports/utilization_final_opto_report_p2.log

save_block -as ${DESIGN_NAME}/project2_final_opto

exit