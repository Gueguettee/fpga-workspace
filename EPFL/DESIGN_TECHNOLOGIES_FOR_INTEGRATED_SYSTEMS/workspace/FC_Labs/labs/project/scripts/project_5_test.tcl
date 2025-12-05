# close_design
# foreach v [info vars] { unset $v }
# foreach a [info arrays] { array unset $a }
# foreach p [info procs] { rename $p {} }

#### Sourcing common setup script
source -echo ../scripts/project_fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

#### Define global variables
set EXPORT_NAME "project5_mac_unit"
set DESIGN_NAME "mac_unit"
set SV_FILE "mac_unit.sv"

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

#### Report reference libraries
report_ref_libs

#### Reading RTL

# Suppress known warnings 
suppress_message VER-130

# Unsuppress after analyze stage
unsuppress_message VER-130

# Define candidate shapes and sizes
set candidate_floorplans {
    {R {26 26} }
    {R {25 25} }
    {R {24 25} }
    {R {24 24} }
    {R {23 24} }
}

# 25 x 25 succeeded solo
# 24 x 24 failed solo

# 28 x 28 failed after 4 success (max RAM = 1359.05 MB)

set last_successful ""

foreach fp $candidate_floorplans {
    set shape [lindex $fp 0]
    set size_list [lindex $fp 1]
    set width [lindex $size_list 0]
    set height [lindex $size_list 1]

    puts "Trying floorplan shape ${shape}, size ${width} x ${height}"

    open_block ${DESIGN_NAME}/project1_read_rtl

    # Source tech setup script
    source -echo ../../setup/tech_setup.tcl

    # Setup application options
    set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
    set_app_options -name place.coarse.continue_on_missing_scandef -value true
    set_app_options -name compile.flow.enable_ccd -value false

    # Initialize floorplan
    initialize_floorplan -control_type core -core_utilization 0.6 -core_offset 5 -shape $shape -side_length $size_list -flip_first_row true

    set_block_pin_constraints -self -allowed_layers {M4 M3} -sides {1 4} -pin_spacing_distance 1 -width 0.11 -length 0.11 
	
    set_individual_pin_constraints -ports [get_ports clk_i] -sides 2 -allowed_layers M5

    # Create power/ground ports only if they do not already exist
    # Using llength on get_ports will return 0 if not present
    if {[sizeof_collection [get_ports VDD]] == 0} {
        create_port -port_type power -direction inout VDD
        puts "Created power port VDD"
    } else {
        puts "Port VDD already exists — skipping create_port."
    }

    if {[sizeof_collection [get_ports VSS]] == 0} {
        create_port -port_type ground -direction inout VSS
        puts "Created ground port VSS"
    } else {
        puts "Port VSS already exists — skipping create_port."
    }

    # Create power/ground nets if they don't exist
    # create_net returns error if net exists; protect with catch and existence check
    if { [sizeof_collection [get_nets VDD]] == 0 } {
        create_net -power VDD
        puts "Created power net VDD"
    } else {
        puts "Net VDD already exists — skipping create_net."
    }

    if { [sizeof_collection [get_nets VSS]] == 0 } {
        create_net -ground VSS
        puts "Created ground net VSS"
    } else {
        puts "Net VSS already exists — skipping create_net."
    }

    #### Set pin placement constraints
    set ports [remove_from_collection [get_ports] {VDD VSS}]

    place_pins -self -ports ${ports}

    #### Insert Boundary/TAP cells in the design
    source -echo ../scripts/insert_boundary_and_tap_cells.tcl

    #### Create Power/Ground Network
    source -echo ../scripts/create_pg_network.tcl

    # MCMM setup
    set SDC_FILE_MAC_UNIT "mac_unit_slow.sdc"
    source -echo ../scripts/project_mcmm_setup.tcl

    set_app_options -name time.delay_calculation_style -value auto

    set status [catch {compile_fusion -to final_opto} result]

    if {$status == 1} {
        puts "Floorplan ${shape} ${width}x${height} FAILED"
        puts "Smallest successful floorplan: ${last_successful}"
        exit
    } else {
        puts "Floorplan ${shape} ${width}x${height} SUCCESS"
        set last_successful "${shape} ${width}x${height}"

        # Reports
        #for the final reports, we want to use zero_interconnect to be consistent with previous runs
        set_app_options -name time.delay_calculation_style -value zero_interconnect

        report_area > reports/area_final_opto_report_${EXPORT_NAME}.log
        report_timing -significant_digits 10 > reports/timing_final_opto_report_${EXPORT_NAME}.log

        report_resources > reports/resource_final_opto_report_${EXPORT_NAME}.log
        report_utilization > reports/utilization_final_opto_report_${EXPORT_NAME}.log

        save_block -as ${DESIGN_NAME}/${EXPORT_NAME}_final_opto
    }
    close_block -force
}

exit
