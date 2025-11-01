#####################################################################
#####			Lab 3.2 Area effort               	#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

# Open the design library
open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}

# Copy and open block
copy_block -from ${DESIGN_NAME}/rtl_read -to ${DESIGN_NAME}/mcmm_and_logic_opto_area_effort
open_block ${DESIGN_NAME}/mcmm_and_logic_opto_area_effort

# Source tech setup script
source -echo ../../setup/tech_setup.tcl

# Read the constraints
read_sdc -echo ${SDC_FILE}

# MCMM setup
source -echo ../../setup/mcmm_setup.tcl

# initial mapping with power
set_app_options -name compile.flow.high_effort_area -value true
compile_fusion -to logic_opto

# Collect the reports
set report_prefix "logic_opto_area"
redirect -file ../../reports/${report_prefix}_report_power.rpt {report_power -scenarios [all_scenarios]}
redirect -file ../../reports/${report_prefix}_report_timing_setup.rpt {report_timing -scenarios [all_scenarios] -delay_type max}
redirect -file ../../reports/${report_prefix}_report_timing_hold.rpt  {report_timing -scenarios [all_scenarios] -delay_type min}
redirect -file ../../reports/${report_prefix}_report_area.rpt {report_area}

# Gate level netlist generation
write_verilog ../../results/${DESIGN_NAME}_${report_prefix}.v

# Working with blocks
current_block
save_block

get_blocks -all

save_lib

exit

