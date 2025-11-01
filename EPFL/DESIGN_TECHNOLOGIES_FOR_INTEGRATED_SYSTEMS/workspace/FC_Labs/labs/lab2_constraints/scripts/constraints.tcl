#####################################################################
#####			Lab 2. Constraints			#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/rtl_read -to ${DESIGN_NAME}/inital_syn_with_sdc
open_block ${DESIGN_NAME}/inital_syn_with_sdc

# Read the constraints
read_sdc -echo ${SDC_FILE}

# initial mapping
compile_fusion -to initial_map

# Collect the reports
report_timing
report_power
report_area

# Gate level netlist generation
write_verilog ../../results/${DESIGN_NAME}_initial_syn_with_sdc.v

# Working with blocks
current_block
save_block

get_blocks -all

save_lib

exit

