#===============================================================================
# Setup for session
#===============================================================================
set FC_PATH         "/home/gjenni/Synopsys_Labs/Lab1/CS472/FC_Labs/FC_Labs"
set WORK_DIR		"${FC_PATH}/labs/dso_project/work"				; # Get current working directory
set database dso_db
set workdir dso_work_compile


file delete -force $workdir

current_db -fs $database

create_session -project LAB -slices {compile}
set_session_options -design_name mac_unit -work_dir ./$workdir

set_design_data_options -data_dir results


set fc_shell "fc_shell"
set_localhost_options -num_cores 1 -name tum_localhost -max_workers 5

current_slice compile

create_launcher -name compile -tool ${fc_shell} -tool_script "${WORK_DIR}/../scripts/compile.tcl"

set_dont_use -stage compile -focus multibit


set_qor_strategy -stages {compile} -power_effort  low -power_mode total -timing_effort none -area_effort high -congestion_effort medium
set_compute_options -parallel_effort 8

set_run_save_rule -clear
set_run_save_rule -metric [get_attribute [current_session] optimize] -num_pareto_fronts 1
set_run_save_rule -metric TOTAL_POWER -num_runs 2 -include_ties true
set_run_save_rule -metric TNS -num_runs 2 -include_ties true


report_aggregate_metric [get_attribute [current_session] optimize]
report_permutons
report_session_config

## Check the session configuration and run the session
if {[check_session] == 1} {
   run_session
}

set_result_columns -add "WNS TNS R2R_WNS R2R_TNS LEAKAGE"

report_session_results -anchor_baseline

report_session_results -only_block_save

report_session_results -permuton_distribution
