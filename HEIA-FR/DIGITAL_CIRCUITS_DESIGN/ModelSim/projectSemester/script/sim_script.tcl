# Author: Gaëtan Jenni
# File Name: sim_script.tcl
# Description: This script compiles the design, then starts the
# simulation and formats the wave window.
#
# Execute this script with the ModelSim command:
# do C:/git/digital-circuits-desighs-workspace/ModelSim/projectSemester/script/sim_script.tcl

namespace eval sim_script {
	# -------------------------------------------------------------------------------- 
	#                               Start user definitions 
	# -------------------------------------------------------------------------------- 
	set COMPILE  	 		yes
	set SIMULATE 			yes
	set XILINX_LIB			yes
	set RUN_TIME 			"35000 ns"
	set SIM_RES				"1 ps"

	# !! if you are using a testbench, the DUT_NAME becomes the testbench entity name !!
	set DUT_NAME 				"TestBench_TL"
	set SIM_SCRIPT_NAME 		"sim_script.tcl"
	set SIM_DEFAULT_WAVE_NAME 	"default_wave.do"

	# Design related files location
	set DIR_PROJECT C:/git/digital-circuits-desighs-workspace/ModelSim/projectSemester
	set DIR_SCRIPTS $DIR_PROJECT/script
	set DIR_PACKAGES $DIR_PROJECT/pkg
	set DIR_SOURCE $DIR_PROJECT/src
	set DIR_TESTBENCH $DIR_PROJECT/tb

	# Simulation files and working library
	set DIR_RUN C:/ModelSim/projectSemester
	set DIR_LIBRARY $DIR_RUN
	set LIB_NAME "LIB_DUT"

	# Xilinx libraries
	set DIR_XILINX C:/Xilinx/Vivado/2023.1/lib
	set LIB_NAME_XILINX "unisim" 

	# List design files with extensions.
	set DESIGN_FILE_LIST [ list \
		TL.vhdl  \
		DFF.vhdl \
		MUX.vhdl \
		PISO_shift_reg.vhdl \
		SIPO_shift_reg.vhdl \
		data_flow.vhdl \
		TestBench_TL.vhdl \
		Int_PLL.vhdl \
		cnt.vhdl \
		my_pkg.vhdl \
	]
	# -------------------------------------------------------------------------------- 
	#                               End user definitions 
	# -------------------------------------------------------------------------------- 

	# exit any currently running simulations and clear the transcript window.
	quit -sim
	.main clear

	# Set the ModelSim running directory.
	puts "\n Searching for ModelSim run directory...\n"
	if {[file isdirectory $DIR_RUN] == 0 } {
		puts "\n ModelSim run directory not detected."
		puts "\n Creating directory $DIR_RUN"
		file mkdir $DIR_RUN
	} else {
		puts "\n The ModelSim run directory already exists."
	}

	# switch ModelSim to the run directory
	cd $DIR_RUN

	# Create a design library
	puts "\n Searching for previous versions of the $LIB_NAME library...\n"
	if { [ file isdirectory $DIR_RUN/$LIB_NAME ] == 1 } {
		puts "\n A previous version of the $LIB_NAME library has been detected."
	} else {
		puts "\n The $LIB_NAME library does not exist."
		puts "\n Creating the $LIB_NAME library..."
		vlib $DIR_LIBRARY/$LIB_NAME
		puts "\n Mapping libraries..."
		vmap $LIB_NAME $DIR_LIBRARY/$LIB_NAME
		vmap work $DIR_LIBRARY/$LIB_NAME	
	}

	# Mapping of pre-compiled Xilinx libraries
	if { $XILINX_LIB == yes } {
		puts "\n Mapping Xilinx library $LIB_NAME_XILINX ...\n"
		vmap $LIB_NAME_XILINX $DIR_XILINX/$LIB_NAME_XILINX	
	}

	#Compile
	if { $COMPILE == yes } {
		puts "\n Compiling files to the $LIB_NAME library...\n"
		foreach i $DESIGN_FILE_LIST {
			if {[ file isfile $DIR_PACKAGES/$i]} {
				puts "\n vcom -work $LIB_NAME $DIR_PACKAGES/$i"
				vcom -work $LIB_NAME $DIR_PACKAGES/$i
			} elseif {[ file isfile $DIR_SOURCE/$i]} {
				puts "\n vcom -work $LIB_NAME $DIR_SOURCE/$i"
				vcom -work $LIB_NAME $DIR_SOURCE/$i
			} elseif {[ file isfile $DIR_TESTBENCH/$i]} {
				puts "\n vcom -work $LIB_NAME $DIR_TESTBENCH/$i"
				vcom -work $LIB_NAME $DIR_TESTBENCH/$i
			} else {
				puts "\n ******************************** "
				puts "\n WARNING: DUT File $i not found   "
				puts "\n ******************************** "
				return
			}
		}
		puts "\n Compilation complete !"
	} else {
		puts "\n Compilation disabled by user"
	}

	#Simulate
	if { $SIMULATE == yes} \
	{
		puts [ format "\n %s: Starting the simulation...\n" $SIM_SCRIPT_NAME ]
		vsim -t $SIM_RES $DUT_NAME
		puts [ format "\n %s: vsim complete !" $SIM_SCRIPT_NAME ]
		
		if {[ file isfile $DIR_SCRIPTS/$SIM_DEFAULT_WAVE_NAME ]} \
		{
			puts [ format "\n %s: Running %s" $SIM_SCRIPT_NAME $SIM_DEFAULT_WAVE_NAME ]
			do $SIM_DEFAULT_WAVE_NAME
			
			puts [ format "\n %s: Running simulation for % s..." $SIM_SCRIPT_NAME $RUN_TIME ]
			run $RUN_TIME
			view wave
			wave zoomfull
			puts [ format "\n %s: Simulation complete." $SIM_SCRIPT_NAME ]		
			
		} else \
		{
				puts "\n ******************************** "
				puts "\n WARNING: .do file not found      "
				puts "\n ******************************** "
		}
		
	} else {
		puts [ format "\n %s: Simulation disabled by user." $SIM_SCRIPT_NAME ]
	}

	puts [ format "\n %s: Script complete.\n" $SIM_SCRIPT_NAME ]

}
