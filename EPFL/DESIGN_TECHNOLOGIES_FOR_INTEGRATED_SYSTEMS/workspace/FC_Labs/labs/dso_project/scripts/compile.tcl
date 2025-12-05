#### Sourcing common setup script
set FC_PATH         "/home/gjenni/Synopsys_Labs/Lab1/CS472/FC_Labs/FC_Labs"
set WORK_DIR		"${FC_PATH}/labs/dso_project/work"				; # Get current working 

source -echo ${WORK_DIR}/../scripts/project_fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ${WORK_DIR}/../../setup/fc_flow_setup.tcl

open_block ${RESULTS_PATH}/mac_unit.dlib:mac_unit/pre_compile.design

# Setup application options
set_lib_cell_purpose -include none {*/*_AO21* */*V2LP*}
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name compile.flow.enable_ccd -value false

compile_fusion

set report_prefix compile
redirect -file results/${report_prefix}_report_power.rpt {report_power -scenarios [all_scenarios]}
redirect -file results/${report_prefix}_report_timing_setup.rpt {report_timing -scenarios [all_scenarios] -delay_type max}
redirect -file results/${report_prefix}_report_timing_hold.rpt  {report_timing -scenarios [all_scenarios] -delay_type min}
redirect -file results/${report_prefix}_report_area.rpt {report_area}

save_block -as compile

exit
