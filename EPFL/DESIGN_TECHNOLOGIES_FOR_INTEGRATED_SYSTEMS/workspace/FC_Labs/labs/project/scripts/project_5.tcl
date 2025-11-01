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

set DESIGN_NAME mac_unit

open_block ${DESIGN_NAME}/project1_read_rtl

### PLEASE CONTINUE FROM HERE ###
### USE the three previous projects script AS REFERENCE TO COMPLETE THE this script and BUILD THE REPORTS ###
### HINT: you can set SDC_FILE_MAC_UNIT "mac_unit_slow.sdc" to use the slow corner SDC ###


exit