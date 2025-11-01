
############################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl
#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

############################################################################

#### Library creation based on the Technology File
# create_lib ${RESULTS_PATH}/${DESIGN_LIBRARY} \
# -technology $TECH_FILE -ref_libs ${REFERENCE_LIBRARY}

#### Library creation based on the Technology Library
# create_lib ${RESULTS_PATH}/${DESIGN_LIBRARY} \
# -use_technology_lib ${TECH_NDM} \
# -ref_libs ${REFERENCE_LIBRARY}

report_ref_libs

############################################################################


set file_list [glob -nocomplain -directory $VERILOG_PATH *.v]

if {[llength $file_list] == 0} {
    puts "No Verilog files found in $VERILOG_PATH"
    exit 1
}

#### Compile the design files
foreach file $file_list {
    echo "Compiling $file"
    analyze -format verilog $file
}

############################################################################

elaborate ${DESIGN_NAME}
set_top_module ${DESIGN_NAME}
compile_fusion -to initial_map

############################################################################

report_timing
report_power
report_area

############################################################################

write_verilog ../../results/${DESIGN_NAME}_initial_syn.v

save_block
get_blocks -all
save_lib

############################################################################

# exit
