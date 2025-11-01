#####################################################################
#####			Create PG Network Script		#####
#####################################################################

#### Remove PG related data
remove_pg_via_master_rules -all
remove_pg_patterns -all
remove_pg_strategies -all
remove_pg_strategy_via_rules -all
remove_routes -ring -stripe -lib_cell_pin_connect 

#### Set PG net attribute
set_attribute -objects [get_nets VDD] -name net_type -value power
set_attribute -objects [get_nets VSS] -name net_type -value ground

#### Create VIA strategy rule VIA_NIL
set_pg_strategy_via_rule VIA_NIL -via_rule { {intersection: undefined} {via_master: NIL} }

#### Create PG Rails for standard cells
create_pg_std_cell_conn_pattern M1_rail -layers {M1} -rail_width {@wtop @wbottom} -parameters {wtop wbottom}

set_pg_strategy M1_rail_strategy_pwr -core -pattern {{name: M1_rail} {nets: VDD} {parameters: {0.094 0.094}}}
set_pg_strategy M1_rail_strategy_gnd -core -pattern {{name: M1_rail} {nets: VSS} {parameters: {0.094 0.094}}}

compile_pg -strategies M1_rail_strategy_pwr -ignore_drc
compile_pg -strategies M1_rail_strategy_gnd -ignore_drc

#### Create M5 Vertical PG Straps
create_pg_mesh_pattern M5_PG \
	-layers { {vertical_layer: M5}   {width: 0.1} {spacing: interleaving} {pitch: 4} {offset: 0.5} } 

set_pg_strategy M5_PG_Strategy \
	-core \
	-pattern   { {name: M5_PG} {nets:{VSS VDD}} } \
	-extension { {stop: core_boundary} }

compile_pg -strategies {M5_PG_Strategy} -via_rule VIA_NIL

#### Create M6 Horizontal PG Straps 
create_pg_mesh_pattern M6_PG \
	-layers { {horizontal_layer: M6}   {width: 0.2} {spacing: interleaving} {pitch: 4} {offset: 0.5} }
	 
set_pg_strategy M6_PG_Strategy \
	-core \
	-pattern   { {name: M6_PG} {nets:{VSS VDD}} } \
	-extension { {stop: design_boundary_and_generate_pin} }

compile_pg -strategies {M6_PG_Strategy} -via_rule VIA_NIL

#### Create M7 Vertical PG Straps
create_pg_mesh_pattern M7_PG \
	-layers { {vertical_layer: M7}   {width: 0.2} {spacing: interleaving} {pitch: 4} {offset: 0.5} } 

set_pg_strategy M7_PG_Strategy \
	-core \
	-pattern   { {name: M7_PG} {nets:{VSS VDD}} } \
	-extension { {stop: design_boundary_and_generate_pin} }

compile_pg -strategies {M7_PG_Strategy} -via_rule VIA_NIL

#### Create PG Rings
create_pg_ring_pattern \
                 PG_Ring \
                 -horizontal_layer M6  -vertical_layer M7 \
                 -horizontal_width 1 -vertical_width 1 \
                 -horizontal_spacing 1 -vertical_spacing 1

set_pg_strategy PG_Ring_Strategy -core -pattern {{ name: PG_Ring} { nets: "VDD VSS" } {offset: 0.5}}

compile_pg -strategies PG_Ring_Strategy -via_rule VIA_NIL

#### Create PG VIAs
create_pg_vias -from_layers M5 -to_layers M1 -via_masters default -nets {VDD VSS}
create_pg_vias -from_layers M6 -to_layers M5 -via_masters default -nets {VDD VSS}
create_pg_vias -from_layers M7 -to_layers M6 -via_masters default -nets {VDD VSS}

#### Connect PG nets
connect_pg_net -net VDD [get_pins -hierarchical  */VDD]
connect_pg_net -net VSS [get_pins -hierarchical  */VSS]

#### Check created PG structure
check_pg_connectivity
check_pg_drc
