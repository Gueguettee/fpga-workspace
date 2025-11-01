#####################################################################
#####			MCMM Setup Script			#####
#####################################################################

# Remove all MCMM related info
remove_corners   -all
remove_modes     -all
remove_scenarios -all

# Create Corners
create_corner Fast
create_corner Typical
create_corner Slow

# Set parasitics parameters
set_parasitics_parameters -early_spec minTLU -late_spec  minTLU -corners {Fast}
set_parasitics_parameters -early_spec nomTLU -late_spec  nomTLU -corners {Typical}
set_parasitics_parameters -early_spec maxTLU -late_spec  maxTLU -corners {Slow}

# Create Mode
create_mode  FUNC
current_mode FUNC

# Create Scenarios
create_scenario -mode FUNC -corner Fast    -name FUNC_Fast
create_scenario -mode FUNC -corner Typical -name FUNC_Typical
create_scenario -mode FUNC -corner Slow    -name FUNC_Slow

# Read Constraints for each scenario
set scenarios [get_attribute [get_scenarios ] name]
suppress_message UIC-034

foreach scenario ${scenarios} {
	current_scenario ${scenario}
	read_sdc ${SDC_FILE}
}

# Set operating conditions for each corner and scenario
current_corner Fast
current_scenario FUNC_Fast
set_operating_conditions ${PVT_FF}

current_corner Typical
current_scenario FUNC_Typical
set_operating_conditions ${PVT_TT}

current_corner Slow
current_scenario FUNC_Slow
set_operating_conditions ${PVT_SS}

# Scenario configuration example
set_scenario_status FUNC_Fast    -setup false -hold true  -leakage_power false -dynamic_power true  -max_transition false  -max_capacitance true  -active true
set_scenario_status FUNC_Typical -all -active true
set_scenario_status FUNC_Slow    -setup true  -hold false -leakage_power true  -dynamic_power true  -max_transition true   -max_capacitance false  -active true
