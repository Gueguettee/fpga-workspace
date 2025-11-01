#####################################################################
#####		Flow Setup Script for Fusion Compiler		#####
#####################################################################

set TECH_BASED	"tf"				; # set "tf" for TECH_FILE-based flow or set "ndm" for TECH_NDM-based flow.
			
set PARASITIC	"tlup"				; # set "tlup" for using TLUP files or  set "nxtgrd" for using NXTGRD files.
			
set HDL		"verilog"			; # set "verilog" for reading Verilog RTL or set "vhdl" for reading VHDL RTL.

set PVT_FF	"ff0p88v125c"			; # set FF PVT
set PVT_TT	"tt0p8v25c"			; # set TT PVT
set PVT_SS	"ss0p72vm40c"			; # set SS PVT

set DB_FF	"${LIBERTY_PATH}/${LIBNAME}_${PVT_FF}.db"
set DB_TT	"${LIBERTY_PATH}/${LIBNAME}_${PVT_TT}.db"
set DB_SS	"${LIBERTY_PATH}/${LIBNAME}_${PVT_SS}.db"

set_host_options -max_cores 1
