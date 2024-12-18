# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}


}

proc update_PARAM_VALUE.FREQ_DATA_LENGTH { PARAM_VALUE.FREQ_DATA_LENGTH } {
	# Procedure called to update FREQ_DATA_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FREQ_DATA_LENGTH { PARAM_VALUE.FREQ_DATA_LENGTH } {
	# Procedure called to validate FREQ_DATA_LENGTH
	return true
}

proc update_PARAM_VALUE.IFBW_DATA_LENGTH { PARAM_VALUE.IFBW_DATA_LENGTH } {
	# Procedure called to update IFBW_DATA_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IFBW_DATA_LENGTH { PARAM_VALUE.IFBW_DATA_LENGTH } {
	# Procedure called to validate IFBW_DATA_LENGTH
	return true
}

proc update_PARAM_VALUE.PATH_DATA_LENGTH { PARAM_VALUE.PATH_DATA_LENGTH } {
	# Procedure called to update PATH_DATA_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PATH_DATA_LENGTH { PARAM_VALUE.PATH_DATA_LENGTH } {
	# Procedure called to validate PATH_DATA_LENGTH
	return true
}

proc update_PARAM_VALUE.SPM_DATA_LENGTH { PARAM_VALUE.SPM_DATA_LENGTH } {
	# Procedure called to update SPM_DATA_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SPM_DATA_LENGTH { PARAM_VALUE.SPM_DATA_LENGTH } {
	# Procedure called to validate SPM_DATA_LENGTH
	return true
}

proc update_PARAM_VALUE.TILT_DATA_LENGTH { PARAM_VALUE.TILT_DATA_LENGTH } {
	# Procedure called to update TILT_DATA_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TILT_DATA_LENGTH { PARAM_VALUE.TILT_DATA_LENGTH } {
	# Procedure called to validate TILT_DATA_LENGTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.FREQ_DATA_LENGTH { MODELPARAM_VALUE.FREQ_DATA_LENGTH PARAM_VALUE.FREQ_DATA_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FREQ_DATA_LENGTH}] ${MODELPARAM_VALUE.FREQ_DATA_LENGTH}
}

proc update_MODELPARAM_VALUE.IFBW_DATA_LENGTH { MODELPARAM_VALUE.IFBW_DATA_LENGTH PARAM_VALUE.IFBW_DATA_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IFBW_DATA_LENGTH}] ${MODELPARAM_VALUE.IFBW_DATA_LENGTH}
}

proc update_MODELPARAM_VALUE.PATH_DATA_LENGTH { MODELPARAM_VALUE.PATH_DATA_LENGTH PARAM_VALUE.PATH_DATA_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PATH_DATA_LENGTH}] ${MODELPARAM_VALUE.PATH_DATA_LENGTH}
}

proc update_MODELPARAM_VALUE.TILT_DATA_LENGTH { MODELPARAM_VALUE.TILT_DATA_LENGTH PARAM_VALUE.TILT_DATA_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TILT_DATA_LENGTH}] ${MODELPARAM_VALUE.TILT_DATA_LENGTH}
}

proc update_MODELPARAM_VALUE.SPM_DATA_LENGTH { MODELPARAM_VALUE.SPM_DATA_LENGTH PARAM_VALUE.SPM_DATA_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SPM_DATA_LENGTH}] ${MODELPARAM_VALUE.SPM_DATA_LENGTH}
}

