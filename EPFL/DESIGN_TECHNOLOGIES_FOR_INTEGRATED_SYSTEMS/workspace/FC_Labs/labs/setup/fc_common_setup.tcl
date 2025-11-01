#####################################################################
#####		Common Setup Script for Fusion Compiler		#####
#####################################################################

set DESIGN_NAME		"i2c_master_top"		; # set design name
set DESIGN_LIBRARY	"${DESIGN_NAME}.dlib"		; # set design library name
set WORK_DIR		"[pwd]"				; # Get current working directory

set LIBNAME		"saed14rvt"			; # set library name
set CELL_PREFIX		"SAEDRVT14"
set TECH_NODE		"saed14nm"			; # set technology node name
set METAL_STACK		"1p9m"				; # set metal stack

set REF_NDM		"frame_timing"			; # set reference ndm type: "frame_only" or "frame_timing_ccs"
set REFERENCE_LIB_PATH	"${WORK_DIR}/../../../common/ndm"
set REFERENCE_LIBRARY	"${REFERENCE_LIB_PATH}/${LIBNAME}_${REF_NDM}.ndm"

set TECH_FILE_PATH      "${WORK_DIR}/../../../common/tf"
set TECH_FILE		"${WORK_DIR}/../../../common/tf/${TECH_NODE}_${METAL_STACK}.tf"
set TECH_NDM		"path/to/tech_ndm/if/exist"

set LIBERTY_PATH	"${WORK_DIR}/../../../common/liberty"

set TLUP_PATH		"${WORK_DIR}/../../../common/tlup"
set TLUP_MIN_FILE	"${TLUP_PATH}/${TECH_NODE}_${METAL_STACK}_Cmin.tlup"
set TLUP_NOM_FILE	"${TLUP_PATH}/${TECH_NODE}_${METAL_STACK}_Cnom.tlup"
set TLUP_MAX_FILE	"${TLUP_PATH}/${TECH_NODE}_${METAL_STACK}_Cmax.tlup"
set NXTGRD_PATH		"${WORK_DIR}/../../../common/nxtgrd"
set NXTGRD_MIN_FILE	"${NXTGRD_PATH}/${TECH_NODE}_${METAL_STACK}_Cmin.nxtgrd"
set NXTGRD_NOM_FILE	"${NXTGRD_PATH}/${TECH_NODE}_${METAL_STACK}_Cnom.nxtgrd"
set NXTGRD_MAX_FILE	"${NXTGRD_PATH}/${TECH_NODE}_${METAL_STACK}_Cmax.nxtgrd"
set MAP_PATH		"${WORK_DIR}/../../../common/map"
set GDS_PATH		"${WORK_DIR}/../../../common/gds"
set LAYER_MAP_FILE	"${MAP_PATH}/${TECH_NODE}_tf_itf_tluplus.map"

set RTL_PATH		"${WORK_DIR}/../../../common/rtl"
set SDC_PATH		"${WORK_DIR}/../../../common/sdc"
set SDC_FILE		"${SDC_PATH}/${DESIGN_NAME}.sdc"

set VERILOG_PATH	"${RTL_PATH}/verilog"
set VHDL_PATH		"${RTL_PATH}/vhdl"

set RESULTS_PATH	"${WORK_DIR}/../../results"
set REPORTS_PATH	"${WORK_DIR}/../../reports"

set DRC_RUNSET_FILE	"${WORK_DIR}/../../../common/runsets/saed14nm_1p9m_drc_rules.rs"
set GDS_MAP_FILE	"${MAP_PATH}/saed14nm_1p9m_gdsout_mw.map"
set MFILL_RUNSET_FILE	"${WORK_DIR}/../../../common/runsets/saed14nm_1p9m_mfill_rules.rs"
set GDS_FILE		"${GDS_PATH}/saed14rvt.gds"

source ${WORK_DIR}/../../setup/utilities.tcl

