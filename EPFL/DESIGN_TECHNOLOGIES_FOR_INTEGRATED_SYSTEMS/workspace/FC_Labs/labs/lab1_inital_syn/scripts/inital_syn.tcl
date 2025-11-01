#####################################################################
#####			Lab 1. Inital Logic Synthesis		#####
#####################################################################

#### Sourcing common setup script
source -echo ../../setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ../../setup/fc_flow_setup.tcl

#### Creating Design Library
if {[string equal frame_only ${REF_NDM}]} {
	#### Specify the link libraries
	set_app_var link_library "${DB_FF} ${DB_TT} ${DB_SS}"
	
	create_lib ${RESULTS_PATH}/${DESIGN_LIBRARY} -technology $TECH_FILE -ref_libs ${REFERENCE_LIBRARY}
} elseif {[string equal frame_timing ${REF_NDM}]} {
	if {[string equal ndm ${TECH_BASED}]} {
		lappend REFERENCE_LIBRARY ${TECH_NDM}
		create_lib ${RESULTS_PATH}/${DESIGN_LIBRARY} -use_technology_lib ${TECH_NDM} -ref_libs ${REFERENCE_LIBRARY} 
	} elseif {[string equal tf ${TECH_BASED}]} {
		create_lib ${RESULTS_PATH}/${DESIGN_LIBRARY} -technology $TECH_FILE -ref_libs ${REFERENCE_LIBRARY}
	} else {
		echo "Error: TECH_BASED variable's value is not ndm or tf. Please fix the value."
	}
} else {
	echo "Error: REF_NDM variable's value is frame_only ndm or frame_timing. Please fix the value."
}

#### Report reference libraries
report_ref_libs

#### Reading RTL
# Analyze the HDL

# Suppress known warnings 
suppress_message VER-130

if {[string equal verilog ${HDL}]} {
	analyze -format verilog [glob ${VERILOG_PATH}/*.v]
} elseif {[string equal vhdl ${HDL}]} {
	analyze -format vhdl [glob ${VHDL_PATH}/*.vhd]
} else {
	echo "Error: HDL variable's value is not verilog or vhdl. Please fix the value."
}
# Unsuppress after analyze stage
unsuppress_message VER-130

# Elaborate
elaborate ${DESIGN_NAME}

# Set top module in the design
set_top_module ${DESIGN_NAME}

# Save block after RTL setup
save_block -as ${DESIGN_NAME}/rtl_read

# initial mapping
compile_fusion -to initial_map

# Collect the reports
report_timing
report_power
report_area

# Gate level netlist generation
write_verilog ../../results/${DESIGN_NAME}_initial_syn.v

# Working with blocks
current_block
save_block
save_block -as ${DESIGN_NAME}/inital_syn

get_blocks -all

save_lib

exit

