#####################################################################
#####	 Lab 5.3 Read Floorplan and create PG network		#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/rtl_read -to ${DESIGN_NAME}/final_floorplan
open_block ${DESIGN_NAME}/final_floorplan

# Source tech setup script
source -echo ../../setup/tech_setup.tcl

# Read the constraints
read_sdc -echo ${SDC_FILE}

# MCMM setup
source -echo ../../setup/mcmm_setup.tcl

#### Read floorplan from DEF
read_def ${RESULTS_PATH}/floorplan.def

#### Insert Boundary/TAP cells in the design
source -echo ../scripts/insert_boundary_and_tap_cells.tcl

#### Create Power/Ground Network
source -echo ../scripts/create_pg_network.tcl

save_block
save_lib

exit

