#####################################################################
#####			Tech Setup Script			#####
#####################################################################

set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

if {[string equal tlup ${PARASITIC}]} {
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${TLUP_MAX_FILE} -name maxTLU
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${TLUP_NOM_FILE} -name nomTLU
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${TLUP_MIN_FILE} -name minTLU
} elseif {[string equal nxtgrd ${PARASITIC}]} {
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${NXTGRD_MAX_FILE} -name maxTLU
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${NXTGRD_NOM_FILE} -name nomTLU
	read_parasitic_tech -layermap ${LAYER_MAP_FILE} -tlup ${NXTGRD_MIN_FILE} -name minTLU
} 

suppress_message ATTR-12
set_attribute [get_layers {M1 M3 M5 M7 M9}]   routing_direction vertical
set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction horizontal
unsuppress_message ATTR-12
