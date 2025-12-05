#### Sourcing common setup script
set FC_PATH         "/home/gjenni/Synopsys_Labs/Lab1/CS472/FC_Labs/FC_Labs"
set WORK_DIR		"${FC_PATH}/labs/dso_project/work"				; # Get current working directory

source -echo ${WORK_DIR}/../scripts/project_fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ${WORK_DIR}/../../setup/fc_flow_setup.tcl

if {[string equal frame_only ${REF_NDM}]} {
	#### Specify the link libraries
	set_app_var link_library "${DB_FF} ${DB_TT} ${DB_SS}"
	create_lib ./results/${DESIGN_LIBRARY} -technology $TECH_FILE -ref_libs ${REFERENCE_LIBRARY}
} elseif {[string equal frame_timing ${REF_NDM}]} {
	if {[string equal ndm ${TECH_BASED}]} {
		lappend REFERENCE_LIBRARY ${TECH_NDM}
		create_lib ./results/${DESIGN_LIBRARY} -use_technology_lib ${TECH_NDM} -ref_libs ${REFERENCE_LIBRARY}
	} elseif {[string equal tf ${TECH_BASED}]} {
		create_lib ./results/${DESIGN_LIBRARY} -technology $TECH_FILE -ref_libs ${REFERENCE_LIBRARY}
	} else {
		echo "Error: TECH_BASED variable's value is not ndm or tf. Please fix the value."
	}
} else {
	echo "Error: REF_NDM variable's value is frame_only ndm or frame_timing. Please fix the value."
}


#### Report reference libraries
report_ref_libs

#### Reading RTL

# Suppress known warnings
suppress_message VER-130

analyze -format sverilog ${WORK_DIR}/mac_unit.sv

# Unsuppress after analyze stage
unsuppress_message VER-130

# Elaborate
elaborate ${DESIGN_NAME}

# Set top module in the design
set_top_module ${DESIGN_NAME}

# Source tech setup script
source -echo ${WORK_DIR}/../../setup/tech_setup.tcl

# Setup application options
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name compile.flow.enable_ccd -value false

# manual floorplan
initialize_floorplan -control_type core -core_utilization 0.6 -core_offset 5 -shape R -side_length {33 33} -flip_first_row true

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
source -echo ${WORK_DIR}/../scripts/insert_boundary_and_tap_cells.tcl

#### Create Power/Ground Network
source -echo ${WORK_DIR}/../scripts/create_pg_network.tcl

# MCMM setup
set SDC_FILE_MAC_UNIT "mac_unit.sdc"
source -echo ${WORK_DIR}/../scripts/project_mcmm_setup.tcl

save_block -as ${DESIGN_NAME}/pre_compile

exit