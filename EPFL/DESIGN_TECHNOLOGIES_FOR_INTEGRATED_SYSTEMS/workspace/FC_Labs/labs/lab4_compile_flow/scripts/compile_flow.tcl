#####################################################################
#####			Lab 4. Compile Flow			#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/rtl_read -to ${DESIGN_NAME}/compile
open_block ${DESIGN_NAME}/compile

# Source tech setup script
source -echo ../../setup/tech_setup.tcl

# Read the constraints
read_sdc -echo ${SDC_FILE}

# MCMM setup
source -echo ../../setup/mcmm_setup.tcl

# Setup application options
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
set_app_options -name place.coarse.continue_on_missing_scandef -value true

# Check the design before compile_fusion
compile_fusion -check_only

# initial_map stage
compile_fusion -to initial_map
collect_reports initial_map

# logic_opto stage
compile_fusion -from logic_opto -to logic_opto
collect_reports logic_opto

# initial_place stage
compile_fusion -from initial_place -to initial_place
collect_reports initial_place

# initial_drc stage
compile_fusion -from initial_drc -to initial_drc
collect_reports initial_drc

# initial_opto stage
compile_fusion -from initial_opto -to initial_opto
collect_reports initial_opto

# final_place stage
compile_fusion -from final_place -to final_place
collect_reports final_place

# final_opto stage
compile_fusion -from final_opto -to final_opto
collect_reports final_opto

check_legality

save_block
save_lib

exit
